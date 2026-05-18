from ultralytics import YOLO
import cv2
import time

model = YOLO(
    r"C:\Users\Bir Kevser\runs\detect\exp_320-5\weights\best.pt"
)

cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Kamera açılamadı!")
    exit()

while True:

    start_time = time.time()

    ret, frame = cap.read()

    if not ret:
        break

    results = model(
        frame,
        imgsz=320,
        conf=0.4
    )

    annotated_frame = results[0].plot()

    end_time = time.time()

    fps = 1 / (end_time - start_time)

    cv2.putText(
        annotated_frame,
        f"FPS: {round(fps,2)}",
        (20,40),
        cv2.FONT_HERSHEY_SIMPLEX,
        1,
        (0,255,0),
        2
    )

    cv2.imshow(
        "AI Waste Detection System",
        annotated_frame
    )

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()

