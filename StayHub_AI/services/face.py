from deepface import DeepFace

def verify_faces(img1_path: str, img2_path: str) -> dict:
    # Sử dụng ArcFace (Rất mạnh mẽ cho khuôn mặt Châu Á)
    # anti_spoofing=True sẽ sử dụng mô hình Fasnet tích hợp sẵn trong DeepFace để chống giả mạo
    try:
        result = DeepFace.verify(
            img1_path=img1_path, 
            img2_path=img2_path, 
            model_name="ArcFace",
            detector_backend="retinaface", # RetinaFace cắt khuôn mặt chính xác nhất
            anti_spoofing=True
        )
        
        return {
            "similarity": (1 - result["distance"]) * 100, # Chuyển distance sang %
            "isMatch": result["verified"],
            "isReal": result.get("is_real", True) # Kết quả từ module anti_spoofing
        }
    except ValueError as e:
        # Xảy ra khi không tìm thấy khuôn mặt trong ảnh, hoặc ảnh giả mạo bị từ chối trước khi verify
        if "Spoof detected" in str(e):
            return {
                "similarity": 0.0,
                "isMatch": False,
                "isReal": False,
                "error": "Phát hiện giả mạo (Ảnh chụp từ màn hình hoặc giấy)."
            }
        raise e
