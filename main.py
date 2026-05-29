from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
from PIL import Image
import io
import uvicorn
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

app = FastAPI(title="AtikTara Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Firebase bağlantısı
cred = credentials.Certificate(r"C:\Users\gokal\Waste-Detection-App\atik_tara_backend\firebase_key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Modeller
genel_model = YOLO(r"C:\Users\gokal\Waste-Detection-App\best.pt")
yag_model = YOLO(r"C:\Users\gokal\Waste-Detection-App\yolov8n.pt")

@app.get("/health")
def health_check():
    return {"status": "calisiyor"}

@app.post("/analyze")
async def analyze_waste(file: UploadFile = File(...)):
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))

    results = genel_model(image)

    if len(results[0].boxes) == 0:
        kategori = "Genel Atik"
        model_kullanilan = "genel"
    else:
        best = results[0].boxes[0]
        sinif_id = int(best.cls[0])
        kategori = genel_model.names[sinif_id]
        model_kullanilan = "genel"

    if "yag" in kategori.lower() or "oil" in kategori.lower():
        yag_results = yag_model(image)
        if len(yag_results[0].boxes) > 0:
            best_yag = yag_results[0].boxes[0]
            sinif_id_yag = int(best_yag.cls[0])
            kategori = yag_model.names[sinif_id_yag]
            model_kullanilan = "yag_modeli"

    # Firebase'e kaydet
    db.collection("analizler").add({
        "kategori": kategori,
        "model": model_kullanilan,
        "dosya_adi": file.filename,
        "tarih": datetime.now().isoformat()
    })

    return {
        "kategori": kategori,
        "model": model_kullanilan,
        "mesaj": "Analiz tamamlandi"
    }

@app.post("/analyze-oil")
async def analyze_oil(file: UploadFile = File(...)):
    contents = await file.read()
    image = Image.open(io.BytesIO(contents))

    results = yag_model(image)

    if len(results[0].boxes) == 0:
        kategori = "Yag Atigi Tespit Edilemedi"
    else:
        best = results[0].boxes[0]
        sinif_id = int(best.cls[0])
        kategori = yag_model.names[sinif_id]

    # Firebase'e kaydet
    db.collection("analizler").add({
        "kategori": kategori,
        "model": "yag_modeli",
        "dosya_adi": file.filename,
        "tarih": datetime.now().isoformat()
    })

    return {
        "kategori": kategori,
        "model": "yag_modeli",
        "mesaj": "Analiz tamamlandi"
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)