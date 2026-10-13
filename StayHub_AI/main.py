from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import shutil
import os
import uuid
from services.ocr import extract_cccd_info
from services.face import verify_faces

app = FastAPI(title="StayHub AI Microservice", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def save_upload_file(upload_file: UploadFile) -> str:
    file_extension = os.path.splitext(upload_file.filename)[1]
    file_path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}{file_extension}")
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)
    return file_path

@app.get("/")
def read_root():
    return {"status": "AI Microservice is running!"}

@app.post("/api/v1/ekyc/extract")
async def extract_info(image: UploadFile = File(...)):
    if not image.filename:
        raise HTTPException(status_code=400, detail="Không tìm thấy file ảnh.")
    
    file_path = save_upload_file(image)
    try:
        data = extract_cccd_info(file_path)
        return {
            "code": 200,
            "message": "Trích xuất thành công",
            "data": [data]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)

@app.post("/api/v1/ekyc/extract-back")
async def extract_back(image: UploadFile = File(...)):
    if not image.filename:
        raise HTTPException(status_code=400, detail="Không tìm thấy file ảnh.")
    
    file_path = save_upload_file(image)
    try:
        from services.ocr import extract_cccd_back_info
        data = extract_cccd_back_info(file_path)
        return {
            "code": 200,
            "message": "Trích xuất mặt sau thành công",
            "data": [data]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)

@app.post("/api/v1/ekyc/verify")
async def verify_face(file1: UploadFile = File(...), file2: UploadFile = File(...)):
    if not file1.filename or not file2.filename:
        raise HTTPException(status_code=400, detail="Cần cung cấp 2 ảnh để so khớp.")
        
    path1 = save_upload_file(file1)
    path2 = save_upload_file(file2)
    
    try:
        result = verify_faces(path1, path2)
        return {
            "code": 200,
            "message": "So khớp hoàn tất",
            "data": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(path1):
            os.remove(path1)
        if os.path.exists(path2):
            os.remove(path2)

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
