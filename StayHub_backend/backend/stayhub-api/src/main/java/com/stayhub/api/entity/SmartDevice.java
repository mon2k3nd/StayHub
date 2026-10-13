package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "smart_devices")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SmartDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "device_type", nullable = false, length = 50)
    private String deviceType; // LIGHT, AC, CURTAIN, LOCK

    @Column(nullable = false, length = 50)
    private String status; // ON, OFF, LOCKED, UNLOCKED, OPEN, CLOSED

    @Column(columnDefinition = "TEXT")
    private String settings; // JSON storing additional state like temperature

    @Column(name = "is_online", nullable = false)
    @Builder.Default
    private Boolean isOnline = true;

    @Column(name = "last_ping_at")
    private LocalDateTime lastPingAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
