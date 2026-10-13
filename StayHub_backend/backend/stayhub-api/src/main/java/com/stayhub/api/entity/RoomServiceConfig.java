package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "room_service_configs")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomServiceConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "service_id", nullable = false)
    private Long serviceId;

    @Column(name = "custom_price")
    private Double customPrice;

    @Column(name = "quantity")
    @Builder.Default
    private Integer quantity = 1;
}
