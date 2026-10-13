package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "room_service_pools")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomServicePool {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "pool_id", nullable = false)
    private Long poolId;
}