import cv2
import numpy as np
from config import (
    MIN_LEAF_AREA, MAX_LEAF_AREA, CROP_PADDING, MASK_THRESHOLD,
    DILATION_KERNEL_SIZE, DILATION_ITERATIONS
)

def preprocess(image, size=(224, 224)):
    # Convert BGR to RGB as ResNet expects RGB formatting for ImageNet specific means/stds
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image = cv2.resize(image, size, interpolation=cv2.INTER_LINEAR)
    image = image.astype(np.float32) / 255.0

    # ImageNet normalization
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std  = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    image = (image - mean) / std

    image = np.transpose(image, (2, 0, 1))  # HWC → CHW
    return image


def extract_crops(results, frame):
    h, w = frame.shape[:2]
    leaf_batch = []
    meta = []

    if results.masks is not None:
        total_masks = len(results.masks.data)
        print(f"  YOLO masks found : {total_masks}")

        for i, (box, mask_data) in enumerate(zip(results.boxes, results.masks.data)):
            mask = mask_data.cpu().numpy()
            mask = cv2.resize(mask, (w, h), interpolation=cv2.INTER_LINEAR)

            # Configurable mask threshold
            binary_mask = (mask > MASK_THRESHOLD).astype(np.uint8) * 255

            # Configurable dilation for edge capture
            kernel = np.ones((DILATION_KERNEL_SIZE, DILATION_KERNEL_SIZE), np.uint8)
            binary_mask = cv2.dilate(binary_mask, kernel, iterations=DILATION_ITERATIONS)

            # FIX 1: use real mask pixel count instead of bbox area
            box_area = int(np.sum(binary_mask > 0))
            if box_area < MIN_LEAF_AREA or box_area > MAX_LEAF_AREA:
                print(f"  [skip] crop {i} — area {box_area} out of range [{MIN_LEAF_AREA}, {MAX_LEAF_AREA}]")
                continue

            ys, xs = np.where(binary_mask > 0)
            if len(xs) == 0 or len(ys) == 0:
                continue

            box_w = xs.max() - xs.min()
            box_h = ys.max() - ys.min()

            # FIX 2: lenient aspect ratio + division guard
            aspect_ratio = float(box_w) / float(box_h + 1e-6)
            if aspect_ratio < 0.2 or aspect_ratio > 5.0:   # was 0.4 and 2.5
                print(f"  [skip] crop {i} — aspect ratio {aspect_ratio:.2f} out of range")
                continue

            # White background composite
            white_bg   = np.ones_like(frame) * 255
            leaf_only  = cv2.bitwise_and(frame, frame, mask=binary_mask)
            bg_only    = cv2.bitwise_and(white_bg, white_bg, mask=cv2.bitwise_not(binary_mask))
            final_leaf = cv2.add(leaf_only, bg_only)

            # Padding around crop
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

    else:
        print("  YOLO masks found : 0  (results.masks is None)")

    print(f"  Crops passed filters : {len(leaf_batch)}")
    return leaf_batch, meta