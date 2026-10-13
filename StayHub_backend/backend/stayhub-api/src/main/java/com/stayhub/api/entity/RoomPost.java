package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "room_posts")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomPost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", insertable = false, updatable = false)
    private Room room;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "post_title", nullable = false, columnDefinition = "TEXT")
    private String postTitle;

    @Column(name = "post_description", columnDefinition = "TEXT")
    private String postDescription;

    @Column(name = "cover_image_url", columnDefinition = "TEXT")
    private String coverImageUrl;

    @Column(name = "post_images", columnDefinition = "TEXT")
    private String postImages; // JSON array of ordered images for the post

    @Column(name = "renting_price")
    private Double rentingPrice;

    @Column(name = "deposit")
    private Double deposit;

    @Column(name = "has_promotion")
    @Builder.Default
    private Boolean hasPromotion = false;

    @Column(name = "discount_type")
    private String discountType;

    @Column(name = "discount_amount")
    private Double discountAmount;

    @Column(name = "promotion_months")
    private Integer promotionMonths;

    @Column(name = "promotion_description", columnDefinition = "TEXT")
    private String promotionDescription;

    @Column(name = "status", nullable = false)
    @Builder.Default
    private String status = "ACTIVE"; // ACTIVE, HIDDEN, DRAFT

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
