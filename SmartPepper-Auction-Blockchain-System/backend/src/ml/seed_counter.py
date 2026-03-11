"""
SmartPepper Hybrid Seed Counter (YOLOv8 + OpenCV Fallback)
---------------------------------------------------------
1. Uses YOLOv8 for high-precision individual seed/cluster detection.
2. Uses OpenCV to detect any large blobs (piles) YOLO might have missed.
3. Includes an Empty Belt Guard (variance check) to prevent noise.
4. Filters out small noise dots (<16px side).
5. Uses ROI filtering to ignore belt edges and hardware.
"""

import cv2
import numpy as np
import json
import sys
import math
import os

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
YOLO_MODEL_PATH = os.path.join(_SCRIPT_DIR, 'yolo_seeds.pt')

# Load YOLOv8
_yolo_model = None
if os.path.exists(YOLO_MODEL_PATH):
    try:
        from ultralytics import YOLO
        _yolo_model = YOLO(YOLO_MODEL_PATH)
        print(f'[seed_counter] YOLOv8 loaded: {YOLO_MODEL_PATH}', file=sys.stderr, flush=True)
    except Exception as e:
        print(f'[seed_counter] YOLO load failed: {e}', file=sys.stderr, flush=True)

def detect_seeds(img_bytes):
    nparr = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        return [], 0

    h, w = img.shape[:2]

    # 1. Empty Belt Guard (Higher Variance Threshold)
    # Empty belt std dev was measured at ~29.1. Set threshold to 35.
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    v_std = np.std(gray)
    if v_std < 35.0:
        print(f'[Hybrid] Empty belt (std={v_std:.2f})', file=sys.stderr, flush=True)
        return [], 0

    # 2. ROI Filtering (Ignore belt edges/hardware)
    # Focus on the center 60% of the image (20% margin on top/bottom)
    margin_h = int(h * 0.20)
    roi_y1, roi_y2 = margin_h, h - margin_h
    
    yolo_bboxes = []
    
    # 3. YOLO Phase
    if _yolo_model:
        # Increase confidence to 0.35 to reduce noise
        results = _yolo_model.predict(img, imgsz=640, conf=0.35, iou=0.8, verbose=False)
        for r in results:
            for box in r.boxes:
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                x1, y1, x2, y2 = max(0, int(x1)), max(0, int(y1)), min(w, int(x2)), min(h, int(y2))
                bw, bh = x2 - x1, y2 - y1
                
                # Filter noise and ROI
                mid_y = y1 + bh // 2
                if bw < 16 or bh < 16: continue
                if mid_y < roi_y1 or mid_y > roi_y2: continue
                
                yolo_bboxes.append({'x': x1, 'y': y1, 'w': bw, 'h': bh})

    # 4. OpenCV Phase (Fallback for missed big piles)
    mask = np.ones((h, w), dtype=np.uint8) * 255
    # Mask out the top and bottom edges to ensure ROI
    mask[:roi_y1, :] = 0
    mask[roi_y2:, :] = 0
    
    for b in yolo_bboxes:
        cv2.rectangle(mask, (b['x']-2, b['y']-2), (b['x']+b['w']+2, b['y']+b['h']+2), 0, -1)
    
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    if np.mean(thresh) > 127:
        _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    masked_thresh = cv2.bitwise_and(thresh, mask)
    cnts, _ = cv2.findContours(masked_thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    final_bboxes = list(yolo_bboxes)
    cv_missed = 0
    
    debug = img.copy()
    # Draw ROI lines in Blue
    cv2.line(debug, (0, roi_y1), (w, roi_y1), (255, 0, 0), 2)
    cv2.line(debug, (0, roi_y2), (w, roi_y2), (255, 0, 0), 2)

    for b in yolo_bboxes:
        cv2.rectangle(debug, (b['x'], b['y']), (b['x']+b['w'], b['y']+b['h']), (0, 255, 0), 2)

    for cnt in cnts:
        area = cv2.contourArea(cnt)
        if area > 600: # Increased threshold for missed massive objects
            x, y, bw, bh = cv2.boundingRect(cnt)
            if area < (h*w*0.3) and max(bw, bh)/max(min(bw, bh), 1) < 8:
                est = max(1, round(area / 950)) # Higher density guess
                cols = max(1, round(math.sqrt(est * bw / max(bh, 1))))
                rows = max(1, round(est / cols))
                sw, sh = max(1, bw // cols), max(1, bh // rows)
                for r in range(rows):
                    for c in range(cols):
                        sx, sy = x + c * sw, y + r * sh
                        sx2, sy2 = min(sx + sw, w), min(sy + sh, h)
                        if sx2 > sx and sy2 > sy:
                            final_bboxes.append({'x': sx, 'y': sy, 'w': sx2-sx, 'h': sy2-sy})
                cv_missed += est
                cv2.rectangle(debug, (x, y), (x + bw, y + bh), (0, 0, 255), 2)

    cv2.imwrite(os.path.join(_SCRIPT_DIR, 'debug_combined.jpg'), debug)
    print(f'[Hybrid] YOLO={len(yolo_bboxes)}, CV_Missed={cv_missed}, std={v_std:.2f}', file=sys.stderr, flush=True)
    return final_bboxes, len(final_bboxes)

if __name__ == '__main__':
    img_bytes = sys.stdin.buffer.read()
    bboxes, count = detect_seeds(img_bytes)
    sys.stdout.write(json.dumps({'seeds': bboxes, 'count': count}))
    sys.stdout.flush()
