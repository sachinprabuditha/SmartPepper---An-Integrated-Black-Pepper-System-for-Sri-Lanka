import cv2
import numpy as np

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

            binary_mask = (mask > 0.1).astype(np.uint8) * 255

            # Small dilation around the cropped leaf
            kernel = np.ones((5, 5), np.uint8)
            binary_mask = cv2.dilate(binary_mask, kernel, iterations=4)

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
            
            # Filter out very small detections (likely background noise/artifacts)
            # Increased from 3000 to 12000 for strict filtering
            if box_w * box_h < 12000:
                continue
                
            # Filter out extreme aspect ratios (e.g. branches, stems, wires)
            # A typical leaf shape usually falls between 0.3 and 3.0
            aspect_ratio = float(box_w) / float(box_h)
            if aspect_ratio < 0.3 or aspect_ratio > 3.0:
                continue
                
            pad_x = int(box_w * 0.06)
            pad_y = int(box_h * 0.06)

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
