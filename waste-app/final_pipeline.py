from ultralytics import YOLO
import cv2
import time


genel_model = YOLO(r"C:\Users\Bir Kevser\runs\detect\exp_320-5\weights\best.pt")
yag_model = YOLO(r"D:\Desktop\Waste-Detection-App-main\yagg - Kopya\runs\detect\train\weights\best.pt")


cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Kamera açılamadı!")
    exit()


def predict(frame):

    result1 = genel_model(frame, conf=0.4)

    if len(result1[0].boxes) > 0:
        return result1, "Genel Atık"

    result2 = yag_model(frame, conf=0.4)

    if len(result2[0].boxes) > 0:
        return result2, "Atık Yağ"

    return result1, "Tespit Yok"


while True:

    start = time.time()

    ret, frame = cap.read()
    if not ret:
        break

    results, label = predict(frame)

    annotated = results[0].plot()

    fps = 1 / (time.time() - start)

    cv2.putText(
        annotated,
        f"{label} | FPS: {round(fps,2)}",
        (20, 40),
        cv2.FONT_HERSHEY_SIMPLEX,
        1,
        (0, 255, 0),
        2
    )

    cv2.imshow("Waste Detection System", annotated)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break


cap.release()
cv2.destroyAllWindows()


