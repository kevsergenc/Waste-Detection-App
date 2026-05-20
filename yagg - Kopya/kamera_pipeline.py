import cv2
from ultralytics import YOLO

model = YOLO('C:/yagg/runs/detect/train/weights/best.pt')

cap = cv2.VideoCapture(0)

print("Kamera pipeline entegrasyonu aktif. Çıkış için 'q' tuşuna basın.")

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        break

    results = model(frame, stream=True, conf=0.48, iou=0.45, max_det=1)

    for r in results:
        annotated_frame = r.plot()
        

    cv2.imshow("Ali - Atik Yag Gercek Zamanli Tespit", annotated_frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()