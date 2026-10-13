package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "vehicles")
@org.hibernate.annotations.SQLDelete(sql = "UPDATE vehicles SET is_deleted = true WHERE id=?")
@org.hibernate.annotations.Where(clause = "is_deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "branch_id")
    private Long branchId;

    @Column(name = "room_id")
    private Long roomId;

    // Xe máy, Xe đạp điện, Ô tô, Xe đạp
    @Column(name = "vehicle_type", nullable = false)
    private String vehicleType;

    @Column(name = "license_plate")
    private String licensePlate;

    @Column(name = "brand")
    private String brand;

    @Column(name = "color")
    private String color;

    // Phí gửi xe hàng tháng (VND)
    @Column(name = "monthly_fee")
    @Builder.Default
    private Double monthlyFee = 0.0;

    // PENDING / APPROVED / REJECTED
    @Column(name = "status")
    @Builder.Default
    private String status = "APPROVED";

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;
}
