import os
import cv2
import torch
import torch.nn as nn
from torchvision import models
import numpy as np
from ultralytics import YOLO

from config import DEVICE, YOLO_PATH, MODEL_FOLDER, NUM_CLASSES, class_names, DEBUG_ROOT
from utils import extract_crops

class InferenceEngine:
    def __init__(self):
        print("🔥 Backend running on:", DEVICE)
        self.detector = YOLO(YOLO_PATH)
        self.fold_models = []
        self._load_classifier_folds()

    def build_model(self, num_classes):
        model = models.resnet18(weights=None)
        model.fc = nn.Linear(model.fc.in_features, num_classes)
        return model

    def _load_classifier_folds(self):
        print("🔄 Loading PyTorch classifier folds...")
        for i in range(1, 6):
            path = os.path.join(MODEL_FOLDER, f"leaf_classifier_fold_{i}.pt")
            if os.path.exists(path):
                model = self.build_model(NUM_CLASSES)
                model.load_state_dict(torch.load(path, map_location=DEVICE))
                model.to(DEVICE)
                model.eval()
                self.fold_models.append(model)
        print(f"✅ Loaded {len(self.fold_models)} classifier models")

    def analyze_images(self, frames, timestamp):
        # Run YOLO on the list of frames
        results_list = self.detector(frames, conf=0.25, iou=0.35, imgsz=1024, verbose=False)

        total_leaves = 0
        all_leaf_batch = []
        all_meta = []
        
        # Aggregate crops from all frames
        for frame_idx, (results, frame) in enumerate(zip(results_list, frames)):
            if results.masks is not None:
                total_leaves += len(results.masks.data)
                
            leaf_batch, meta = extract_crops(results, frame)
            all_leaf_batch.extend(leaf_batch)
            
            # Store frame_idx with original crop idx
            for i, crop in meta:
                all_meta.append((f"{frame_idx}_{i}", crop))
        
        infected_count = 0
        stats = {k: 0 for k in class_names + ["Uncertain"]}
        CONF_HIGH = 0.40

        if all_leaf_batch:
            batch_tensor = torch.tensor(
                np.array(all_leaf_batch), dtype=torch.float32
            ).to(DEVICE)

            with torch.no_grad():
                preds = []
                for model in self.fold_models:
                    out = model(batch_tensor)
                    probs = torch.softmax(out, dim=1)
                    preds.append(probs.cpu().numpy())

            avg_preds = np.mean(preds, axis=0)

            for (meta_id, crop), p in zip(all_meta, avg_preds):
                idx = int(np.argmax(p))
                conf = float(p[idx])

                label = class_names[idx] if conf >= CONF_HIGH else "Uncertain"
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
