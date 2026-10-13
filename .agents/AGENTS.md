- **Dual Address System (Xử lý Hệ thống Địa chỉ kép 2026)**:
  Hệ thống BẮT BUỘC vận hành song song 2 định dạng địa chỉ để tương thích với thay đổi sáp nhập hành chính:
  - **Lớp Presentation (UI/Maps/Search):** Duy trì cấu trúc 4 cấp truyền thống (`Số nhà/Đường`, `Phường/Xã`, `Quận/Huyện`, `Tỉnh/Thành phố`). Mọi form nhập liệu, logic filter và hiển thị trên thẻ (Property Card) phải dùng chuẩn này để tối ưu trải nghiệm và khớp với API Bản đồ.
  - **Lớp Legal & Core Business (eKYC/Hợp đồng/Hóa đơn):** Tuân thủ cấu trúc 3 cấp mới (`Số nhà/Đường`, `Phường/Xã`, `Tỉnh/Thành phố` - lược bỏ hoàn toàn cấp Quận/Huyện).
  - **Yêu cầu thực thi (Code Implementation):** 
    1. Database phải thiết kế linh hoạt để lưu được mapping của cả 2 hệ thống. 
    2. Cấm hardcode. BẮT BUỘC xây dựng một `AddressMapper` (tại Service layer). Khi UI gửi payload 4 cấp xuống, hệ thống phải tự động nội suy và map về 3 cấp trước khi binding vào PDF Hợp đồng thuê nhà hoặc gửi API xác thực eKYC.