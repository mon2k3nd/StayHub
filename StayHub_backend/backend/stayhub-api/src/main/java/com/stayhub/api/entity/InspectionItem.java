package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "inspection_items")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InspectionItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "inspection_id", nullable = false)
    private Long inspectionId;

    @Column(name = "item_name", nullable = false)
    private String itemName;

    @Column(name = "is_good", nullable = false)
    private Boolean isGood;

    @Column(name = "notes")
    private String notes;

    @Column(name = "photo_url")
    private String photoUrl;
}
