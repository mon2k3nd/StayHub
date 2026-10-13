package com.stayhub.api.entity;

public enum SubscriptionStatus {
    PENDING,   // Chờ admin xác nhận tiền về
    ACTIVE,    // Đang hoạt động
    EXPIRED,   // Đã hết hạn
    CANCELLED  // Đã hủy
}
