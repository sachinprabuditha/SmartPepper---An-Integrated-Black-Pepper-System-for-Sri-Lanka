import os
import cv2
import torch
import torch.nn as nn
from torchvision import models
import numpy as np
from ultralytics import YOLO

from config import (
    DEVICE, YOLO_PATH, MODEL_FOLDER, NUM_CLASSES, class_names, DEBUG_ROOT,
    YOLO_CONFIDENCE, YOLO_IOU, YOLO_IMAGE_SIZE
)
from utils import extract_crops

class InferenceEngine:
    def __init__(self):
        print("🔥 Backend running on:", DEVICE)
        self.detector = YOLO(YOLO_PATH)
        self.model = None
        self._load_classifier_model()

    def build_model(self, num_classes):
        model = models.efficientnet_b3(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(0.5),
            nn.Linear(in_features, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Dropout(0.25),
            nn.Linear(512, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(128, num_classes)
        )
        return model

    def _resolve_state_dict(self, checkpoint):
        if isinstance(checkpoint, dict):
            for key in ("state_dict", "model_state_dict", "model", "net"):
                nested = checkpoint.get(key)
                if isinstance(nested, dict):
                    checkpoint = nested
                    break

        if not isinstance(checkpoint, dict):
            raise TypeError(f"Unsupported checkpoint format: {type(checkpoint).__name__}")

        resolved = {}
        for key, value in checkpoint.items():
            normalized_key = key[7:] if key.startswith("module.") else key
            resolved[normalized_key] = value

        return resolved

    def _load_classifier_model(self):
        print(" Loading PyTorch classifier model...")
        path = os.path.join(MODEL_FOLDER, "best_model.pt")
        
        if not os.path.exists(path):
            raise FileNotFoundError(
                f"Classifier model not found at {path}. "
                f"Expected best_model.pt in node_backend/models."
            )
        
        try:
            model = self.build_model(NUM_CLASSES)
            checkpoint = torch.load(path, map_location=DEVICE)
            state_dict = self._resolve_state_dict(checkpoint)
            model.load_state_dict(state_dict, strict=False)
            model.to(DEVICE)
            model.eval()
            self.model = model
            print(f" Loaded classifier model successfully")
        except Exception as exc:
            raise RuntimeError(
                f"Failed to load best_model.pt: {exc}"
            )

    def analyze_images(self, frames, timestamp):
        # Run YOLO with configuration from config.py (can be overridden by .env)
        results_list = self.detector(frames, conf=YOLO_CONFIDENCE, iou=YOLO_IOU, imgsz=YOLO_IMAGE_SIZE, verbose=False)

        all_leaf_batch = []
        all_meta = []
        
        # Aggregate crops from all frames
        for frame_idx, (results, frame) in enumerate(zip(results_list, frames)):
            leaf_batch, meta = extract_crops(results, frame)
            all_leaf_batch.extend(leaf_batch)
            
            # Store frame_idx with original crop idx
            for i, crop in meta:
                all_meta.append((f"{frame_idx}_{i}", crop))
        
        # Count total leaves AFTER filtering (not before)
        # This ensures the count matches the sum of all categories
        total_leaves = len(all_leaf_batch)
        
        infected_count = 0
        stats = {k: 0 for k in class_names + ["Uncertain"]}
        CONF_HIGH = 0.40

        if all_leaf_batch:
            batch_array = np.array(all_leaf_batch, dtype=np.float32)
            print(f" Batch shape: {batch_array.shape}, dtype: {batch_array.dtype}")
            print(f" Batch value range: min={batch_array.min():.3f}, max={batch_array.max():.3f}")
            
            batch_tensor = torch.tensor(batch_array).to(DEVICE)
            print(f" Tensor shape: {batch_tensor.shape}, device: {batch_tensor.device}")

            with torch.no_grad():
                out = self.model(batch_tensor)
                probs = torch.softmax(out, dim=1)
                preds = probs.cpu().numpy()
                print(f" Predictions shape: {preds.shape}")
                print(f" Sample predictions (first leaf): {preds[0]}")

            for (meta_id, crop), p in zip(all_meta, preds):
                sorted_indices = np.argsort(p)[::-1]
                idx = sorted_indices[0]
                conf = float(p[idx])
                label = class_names[idx]
                
                # If top class is Slow-Decline but under 60% confidence, fallback to the next highest class
                if label == "Slow-Decline" and conf < 0.60:
                    idx = sorted_indices[1]
                    conf = float(p[idx])
                    label = class_names[idx]
                
                # Debug: show raw vs normalized crop difference
                if meta_id == "0_0":  # First crop only
                    print(f" DEBUG first crop - raw min={crop.min()}, max={crop.max()}")
                    print(f" DEBUG predictions for first crop: {p}")
                    print(f" DEBUG class_names: {class_names}")

                if conf < CONF_HIGH:
                    label = "Uncertain"
                stats[label] += 1

                if label not in ["healthy leaves", "Uncertain"]:
                    infected_count += 1

                cv2.imwrite(
                    os.path.join(DEBUG_ROOT, label, f"{label}_{timestamp}_{meta_id}.jpg"),
                    crop
                )

        severity = (infected_count / total_leaves * 100) if total_leaves else 0
        healthy_count = stats.get("healthy leaves", 0) + stats.get("healthy", 0)
        global_health_score = (healthy_count / total_leaves * 100) if total_leaves else 0

        disease_specific_severity = {}
        if total_leaves > 0:
            for k, v in stats.items():
                if k not in ["healthy leaves", "Uncertain"]:
                    disease_specific_severity[k] = round((v / total_leaves) * 100, 2)
        else:
            for k in stats.keys():
                if k not in ["healthy leaves", "Uncertain"]:
                    disease_specific_severity[k] = 0.0

        return {
            "severity": severity,
            "global_health_score": global_health_score,
            "disease_specific_severity": disease_specific_severity,
            "total_leaves": total_leaves,
            "stats": stats
        }
