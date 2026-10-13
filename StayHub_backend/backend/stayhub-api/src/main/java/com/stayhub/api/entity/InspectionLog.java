package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "inspection_logs")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InspectionLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "contract_images", columnDefinition = "TEXT")
    private String contractImages;

    @Column(name = "inspection_images", columnDefinition = "TEXT")
    private String inspectionImages;

    @Column(name = "furniture_images", columnDefinition = "TEXT")
    private String furnitureImages;

    @Column(name = "electricity_meter_image")
    private String electricityMeterImage;

    @Column(name = "water_meter_image")
    private String waterMeterImage;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
