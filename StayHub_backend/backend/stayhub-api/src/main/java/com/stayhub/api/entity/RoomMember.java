package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "room_members")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomMember {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "room_id", nullable = false)
    private Long roomId;
    @Column(name = "contract_id")
    private Long contractId;
    @Column(name = "name", nullable = false)
    private String name;
    @Column(name = "phone")
    private String phone;
    @Column(name = "cccd")
    private String cccd;
    @Column(name = "is_ekyc_verified")
    @Builder.Default
    private Boolean isEkycVerified = false;
    @Column(name = "status")
    @Builder.Default
    private String status = "ACTIVE"; 

    @Column(name = "role")
    @Builder.Default
    private String role = "TENANT_SUB"; // TENANT_MAIN, TENANT_SUB, GUEST

    @Column(name = "check_in_date")
    private LocalDateTime checkInDate;

    @Column(name = "check_out_date")
    private LocalDateTime checkOutDate;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}