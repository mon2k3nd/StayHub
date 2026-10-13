package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Entity
@Table(name = "shared_facilities")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@org.hibernate.annotations.SQLRestriction("is_deleted = false")
public class SharedFacility {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "branch_id")
    private Long branchId;

    @Column(name = "name")
    private String name;

    @Column(name = "type")
    private String type; // WC, KITCHEN, etc.

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes; // Ghi chú: lịch vệ sinh, phân công, v.v.

    @Column(name = "equipment", columnDefinition = "TEXT")
    private String equipment; // Danh sách thiết bị (JSON String)

    @Column(name = "images", columnDefinition = "TEXT")
    private String images; // Ảnh WC (JSON String)

    @Column(name = "feature_photos", columnDefinition = "TEXT")
    private String featurePhotos; // Ảnh thiết bị (JSON String map)

    @Column(name = "electric_index_init")
    private Integer electricIndexInit;

    @Column(name = "water_index_init")
    private Integer waterIndexInit;

    /// Cách tính nước cho khu vực chung: PER_INDEX (có công tơ) hoặc PER_PERSON (theo đầu người).
    @Column(name = "water_pricing_type")
    @Enumerated(EnumType.STRING)
    private PricingType waterPricingType;

    @ManyToMany
    @JoinTable(
        name = "room_shared_facilities",
        joinColumns = @JoinColumn(name = "facility_id"),
        inverseJoinColumns = @JoinColumn(name = "room_id")
    )
    @com.fasterxml.jackson.annotation.JsonIgnore
    private List<Room> rooms;

    @com.fasterxml.jackson.annotation.JsonProperty("roomIds")
    public List<Long> getRoomIds() {
        if (rooms == null) return java.util.Collections.emptyList();
        try {
            return rooms.stream().map(Room::getId).collect(java.util.stream.Collectors.toList());
        } catch (org.hibernate.LazyInitializationException e) {
            return java.util.Collections.emptyList();
        }
    }

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;
}
