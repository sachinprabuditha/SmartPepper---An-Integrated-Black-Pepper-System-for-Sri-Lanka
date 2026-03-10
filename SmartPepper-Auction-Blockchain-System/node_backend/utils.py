import cv2
import numpy as np
from config import (
    MIN_LEAF_AREA, MAX_LEAF_AREA, CROP_PADDING, MASK_THRESHOLD,
    DILATION_KERNEL_SIZE, DILATION_ITERATIONS
)

def preprocess(image, size=(224, 224)):
    # Convert BGR to RGB as ResNet expects RGB formatting for ImageNet specific means/stds
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image = cv2.resize(image, size, interpolation=cv2.INTER_AREA)
    image = image.astype(np.float32) / 255.0
    
    # ImageNet normalization
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    image = (image - mean) / std
    
    image = np.transpose(image, (2, 0, 1))  # HWC → CHW
    return image

def extract_crops(results, frame):
    h, w = frame.shape[:2]
    leaf_batch = []
    meta = []
    
    if results.masks is not None:
        for i, (box, mask_data) in enumerate(zip(results.boxes, results.masks.data)):
            mask = mask_data.cpu().numpy()
            mask = cv2.resize(mask, (w, h), interpolation=cv2.INTER_LINEAR)

            # Use configurable mask threshold (better edge preservation for footrot)
            binary_mask = (mask > MASK_THRESHOLD).astype(np.uint8) * 255

            # Configurable dilation for edge capture
            kernel = np.ones((DILATION_KERNEL_SIZE, DILATION_KERNEL_SIZE), np.uint8)
            binary_mask = cv2.dilate(binary_mask, kernel, iterations=DILATION_ITERATIONS)

            # ---------- WHITE BACKGROUND ----------
            white_bg = np.ones_like(frame) * 255
            leaf_only = cv2.bitwise_and(frame, frame, mask=binary_mask)
            bg_only = cv2.bitwise_and(
                white_bg, white_bg, mask=cv2.bitwise_not(binary_mask)
            )
            final_leaf = cv2.add(leaf_only, bg_only)

            # ---------- MASK-BASED CROP ----------
            ys, xs = np.where(binary_mask > 0)
            if len(xs) == 0 or len(ys) == 0:
                continue

            # Small padding buffer based on bounding box size
            box_w = xs.max() - xs.min()
            box_h = ys.max() - ys.min()
            box_area = box_w * box_h
            
            # Area-based filtering with configurable thresholds
            if box_area < MIN_LEAF_AREA or box_area > MAX_LEAF_AREA:
                continue
                
            # Aspect ratio filtering (typical pepper leaves)
            aspect_ratio = float(box_w) / float(box_h)
            if aspect_ratio < 0.4 or aspect_ratio > 2.5:
                continue
                
            # Configurable padding for edge disease detection (e.g., footrot)
            pad_x = int(box_w * CROP_PADDING)
            pad_y = int(box_h * CROP_PADDING)

            x1m = max(0, xs.min() - pad_x)
            x2m = min(w, xs.max() + pad_x)
            y1m = max(0, ys.min() - pad_y)
            y2m = min(h, ys.max() + pad_y)

            crop = final_leaf[y1m:y2m, x1m:x2m]
            if crop.size == 0:
                continue

            leaf_batch.append(preprocess(crop))
            meta.append((i, crop))
            
    return leaf_batch, meta
