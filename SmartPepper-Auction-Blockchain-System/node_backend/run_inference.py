import sys
import json
import cv2
import numpy as np

# Suppress warnings and standard prints from imports if possible to keep stdout clean
import os
import warnings
warnings.filterwarnings("ignore")
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

from inference import InferenceEngine
from datetime import datetime

def main():
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Insufficient arguments. Usage: python run_inference.py <timestamp> <img_path1> [<img_path2> ...]"}))
        sys.exit(1)

    timestamp = sys.argv[1]
    image_paths = sys.argv[2:]
    
    # Initialize Engine (prints will go to stderr to avoid corrupting JSON stdout if we redirect or we ignore them)
    # Actually, InferenceEngine currently prints "Backend running on..." and "Loading PyTorch..."
    # We will let them go to stdout but ensure our final JSON is clearly on its own printed line.
    
    try:
        # We can temporarily redirect stdout to stderr to avoid polluting the final JSON
        original_stdout = sys.stdout
        sys.stdout = sys.stderr
        
        engine = InferenceEngine()

        frames = []
        for path in image_paths:
            if not os.path.exists(path):
                continue
            
            # Read image using cv2
            frame = cv2.imread(path)
            if frame is not None:
                # Convert BGR to RGB? app.py does cv2.IMREAD_COLOR which is BGR.
                # inference.py handles BGR fine (utils preprocess converts to RGB)
                frames.append(frame)

        if not frames:
            sys.stdout = original_stdout
            print(json.dumps({"error": "No valid images found or readable"}))
            sys.exit(1)

        analysis_results = engine.analyze_images(frames, timestamp)

        # Restore stdout carefully and print the final JSON
        sys.stdout = original_stdout
        print(json.dumps(analysis_results))
        sys.exit(0)

    except Exception as e:
        sys.stdout = sys.__stdout__
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()
