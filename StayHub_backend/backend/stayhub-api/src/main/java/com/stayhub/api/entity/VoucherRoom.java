package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "voucher_rooms", indexes = {
    @Index(name = "idx_voucher_room_voucher", columnList = "voucher_id"),
    @Index(name = "idx_voucher_room_room", columnList = "room_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VoucherRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "voucher_id", nullable = false)
    private Long voucherId;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
