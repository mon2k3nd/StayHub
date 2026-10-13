package com.stayhub.api.entity;

public enum RoomStatus {
    TRONG,      // Phòng trống, đang cho thuê
    CHO_DUYET,  // Khách đã nhập mã, chờ duyệt
    CHO_KICH_HOAT, // Chờ kích hoạt hợp đồng offline
    NGHIEM_THU, // Chủ đã duyệt, chờ khách chụp ảnh check-in
    DA_THUE,    // Đang ở
    BAO_TRI,    // Đang bảo trì
    DONG_CUA,   // Không sử dụng
    CLEANING_TURNOVER, // Chờ bàn giao và dọn dẹp
    KHOA_CHO_CAP_NHAT, // Chờ chủ nhà cập nhật chi tiết sau khi auto-generate
    SAP_TRONG,   // Sắp trống
    DISPUTED    // Đang tranh chấp, khóa mọi giao dịch
}
