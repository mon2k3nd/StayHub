from paddleocr import PaddleOCR
import re

# Khởi tạo model PaddleOCR (ngôn ngữ Tiếng Việt)
# Lần chạy đầu tiên sẽ tự động tải pre-trained models về máy
ocr = PaddleOCR(use_angle_cls=True, lang='vi')

def extract_cccd_info(img_path: str) -> dict:
    result = ocr.ocr(img_path, cls=True)
    
    extracted_text = []
    for line in result:
        if line:
            for word_info in line:
                extracted_text.append(word_info[1][0])
                
    full_text = " ".join(extracted_text)
    
    # 1. Tìm CCCD (12 chữ số liên tiếp)
    id_match = re.search(r'\b\d{12}\b', full_text)
    id_num = id_match.group(0) if id_match else ""
    
    # 2. Tìm Ngày sinh (dd/mm/yyyy)
    dob_match = re.search(r'\b\d{2}/\d{2}/\d{4}\b', full_text)
    dob = dob_match.group(0) if dob_match else ""
    
    # 3. Tìm Giới tính (Nam/Nữ)
    sex = ""
    if "Nam" in full_text:
        sex = "Nam"
    elif "Nữ" in full_text:
        sex = "Nữ"
        
    # TODO: Cải tiến Regex hoặc dùng Named Entity Recognition (NER) để bóc tách Họ tên và Quê quán chính xác hơn.
    # Tạm thời trả về thông tin cơ bản
    return {
        "id": id_num,
        "name": "N/A",  # Để trống cho user tự nhập hoặc dùng NER model
        "dob": dob,
        "sex": sex,
        "home": "N/A",
        "type": "cccd"
    }

def extract_cccd_back_info(img_path: str) -> dict:
    result = ocr.ocr(img_path, cls=True)
    
    extracted_text = []
    for line in result:
        if line:
            for word_info in line:
                extracted_text.append(word_info[1][0])
                
    full_text = " ".join(extracted_text)
    
    # 1. Tìm Ngày cấp
    issue_date_match = re.search(r'\b\d{2}/\d{2}/\d{4}\b', full_text)
    issue_date = issue_date_match.group(0) if issue_date_match else ""
    
    # 2. Tìm Nơi cấp
    issue_place = ""
    full_text_lower = full_text.lower()
    
    if "cục trưởng" in full_text_lower or "quản lý hành chính" in full_text_lower or "cảnh sát" in full_text_lower:
        issue_place = "Cục Cảnh sát QLHC về TTXH"
    elif "giám đốc công an" in full_text_lower:
        match = re.search(r'công an (tỉnh|thành phố) ([\w\s]+)', full_text_lower)
        if match:
            issue_place = f"Công an {match.group(1)} {match.group(2)}".title()
            
    # 3. Đặc điểm nhận dạng
    features = ""
    if "đặc điểm nhận dạng" in full_text_lower or "nhận dạng" in full_text_lower:
        match = re.search(r'nhận dạng[:\s]*([\w\s,]+)(?=ngày|tháng|năm|$)', full_text_lower)
        if match:
            features = match.group(1).strip().capitalize()
    
    return {
        "issue_date": issue_date,
        "issue_place": issue_place,
        "features": features
    }
