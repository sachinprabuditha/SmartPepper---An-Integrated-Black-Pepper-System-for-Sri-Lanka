import os
import json
import torch

# Directory setup
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_FOLDER = os.path.join(BASE_DIR, "models")
# Updated to use newly trained YOLO segmentation model
YOLO_PATH = r'C:\Users\nipun\Desktop\Pepper_Project\Training_Results\pepper_leaf_no_overfit\weights\best.pt'
LABELS_PATH = os.path.join(MODEL_FOLDER, "labels.json")
DEBUG_ROOT = os.path.join(BASE_DIR, "debug_crops")

# Hardware config
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Load Class Names
if os.path.exists(LABELS_PATH):
    with open(LABELS_PATH, "r") as f:
        class_names = json.load(f)
else:
    class_names = ["Footrot", "Pollu_Disease", "Slow-Decline", "healthy leaves"]

NUM_CLASSES = len(class_names)
folders_to_create = class_names + ["Uncertain"]

for f in folders_to_create:
    os.makedirs(os.path.join(DEBUG_ROOT, f), exist_ok=True)
