package com.stayhub.api.entity;

public enum RequestStatus {
    PENDING,
    APPROVED_WAITING_HANDOVER, // Chờ khách nghiệm thu
    COMPLETED, // Khách đã ký và nghiệm thu xong
    APPROVED, // Cũ (Deprecated)
    REJECTED
}
