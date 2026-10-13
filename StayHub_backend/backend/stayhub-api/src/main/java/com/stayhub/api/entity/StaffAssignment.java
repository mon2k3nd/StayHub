package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "staff_assignments")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StaffAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "staff_id", nullable = false)
    private Long staffId;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "branch_id", nullable = false)
    private Long branchId;

    // Lịch trực: MON,TUE,WED,THU,FRI,SAT,SUN
    @Column(name = "work_schedule")
    private String workSchedule;

    // Quyền hạn: CAN_VIEW_FINANCE,CAN_WRITE_METER,CAN_SEND_NOTIFICATION,CAN_VIEW_CONTRACTS
    // Lưu dạng chuỗi phân cách dấu phẩy
    @Column(name = "permissions", columnDefinition = "TEXT")
    @Builder.Default
    private String permissions = "CAN_WRITE_METER";

    // Vai trò hiển thị: MANAGER, ACCOUNTANT, SECURITY, STAFF
    @Column(name = "staff_role")
    @Builder.Default
    private String staffRole = "STAFF";

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "assigned_at")
    @Builder.Default
    private LocalDateTime assignedAt = LocalDateTime.now();
}
