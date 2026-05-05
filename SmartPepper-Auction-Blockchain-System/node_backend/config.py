import os
import json
import torch
from dotenv import load_dotenv

# Load environment variables (optional - will use defaults if not present)
load_dotenv()

# Directory setup
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_FOLDER = os.path.join(BASE_DIR, "models")

# YOLO Model Path - use relative path by default, can be overridden by .env
YOLO_MODEL_PATH = os.getenv('YOLO_MODEL_PATH', './models/best.pt')
YOLO_PATH = YOLO_MODEL_PATH if os.path.isabs(YOLO_MODEL_PATH) else os.path.join(BASE_DIR, YOLO_MODEL_PATH)

LABELS_PATH = os.path.join(MODEL_FOLDER, "labels.json")
DEBUG_ROOT = os.path.join(BASE_DIR, "debug_crops")

# Hardware config
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# YOLO Configuration — FIXED values
YOLO_CONFIDENCE = float(os.getenv('YOLO_CONFIDENCE', '0.50'))   # was 0.70 — too high, dropping valid leaves
YOLO_IOU        = float(os.getenv('YOLO_IOU',        '0.60'))   # was 0.45
YOLO_IMAGE_SIZE = int(os.getenv('YOLO_IMAGE_SIZE',   '640'))    # was 1024 — must match training imgsz

# Filtering thresholds — FIXED values
MIN_LEAF_AREA = int(os.getenv('MIN_LEAF_AREA', '200'))   # was 15000 — was killing all crops
MAX_LEAF_AREA        = int(os.getenv('MAX_LEAF_AREA',        '500000'))
CROP_PADDING         = float(os.getenv('CROP_PADDING',       '0.15'))
MASK_THRESHOLD       = float(os.getenv('MASK_THRESHOLD',     '0.05'))
DILATION_KERNEL_SIZE = int(os.getenv('DILATION_KERNEL_SIZE', '5'))
DILATION_ITERATIONS  = int(os.getenv('DILATION_ITERATIONS',  '3'))

# Load Class Names
if os.path.exists(LABELS_PATH):
    with open(LABELS_PATH, "r") as f:
        class_names = json.load(f)
else:
    class_names = ["Footrot", "healthy leaves", "Pollu_Disease", "Slow-Decline"]

NUM_CLASSES = len(class_names)
folders_to_create = class_names + ["Uncertain"]

for f in folders_to_create:
    os.makedirs(os.path.join(DEBUG_ROOT, f), exist_ok=True)