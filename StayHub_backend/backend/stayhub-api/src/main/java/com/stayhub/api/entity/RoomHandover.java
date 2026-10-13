package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "room_handovers")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomHandover {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "contract_id")
    private Long contractId;

    @Column(name = "inspection_time")
    private Integer inspectionTime; // 1: Lúc nhận, 2: Lúc trả

    @Column(name = "wall_condition", columnDefinition = "TEXT")
    private String wallCondition;

    @Column(name = "plumbing_condition", columnDefinition = "TEXT")
    private String plumbingCondition;

    @Column(name = "electrical_condition", columnDefinition = "TEXT")
    private String electricalCondition;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "attached_images", columnDefinition = "jsonb")
    private java.util.List<String> attachedImages;
}
