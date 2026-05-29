from ultralytics import YOLO
model = YOLO('yolov8n.pt')
model.train(data='C:/yagg/dataset.yaml', epochs=50, imgsz=640, device='cpu')