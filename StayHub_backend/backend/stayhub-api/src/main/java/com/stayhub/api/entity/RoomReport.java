package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "room_reports")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomReport {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "reporter_id")
    private Long reporterId;

    @Column(name = "reason", nullable = false)
    private String reason;

    @Column(name = "details", columnDefinition = "TEXT")
    private String details;

    @Column(name = "status")
    @Builder.Default
    private String status = "PENDING"; // PENDING, RESOLVED, DISMISSED

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
