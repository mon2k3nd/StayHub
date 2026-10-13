package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "room_assets")
@org.hibernate.annotations.SQLDelete(sql = "UPDATE room_assets SET is_deleted = true WHERE id=?")
@org.hibernate.annotations.Where(clause = "is_deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomAsset {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "asset_name", nullable = false)
    private String assetName;

    @Column(name = "quantity")
    @Builder.Default
    private Integer quantity = 1;

    @Column(name = "condition_note", columnDefinition = "TEXT")
    private String conditionNote;

    @Column(name = "asset_image")
    private String assetImage;

    @Enumerated(EnumType.STRING)
    @Column(name = "asset_status")
    @Builder.Default
    private AssetStatus assetStatus = AssetStatus.GOOD;

    @Column(name = "value")
    private Double value;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;
}
