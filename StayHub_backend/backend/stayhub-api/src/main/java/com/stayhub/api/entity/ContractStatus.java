package com.stayhub.api.entity;

public enum ContractStatus {
    PENDING,    // Chờ ký
    ACTIVE,     // Đang hiệu lực
    EXPIRED,    // Đã hết hạn
    TERMINATED, // Đã chấm dứt sớm
    LIQUIDATED, // Đã thanh lý
    VOID_BY_TIMEOUT, // Hủy do không thanh toán phí ban đầu
    CANCELLED   // Đã hủy trước khi ký
}
