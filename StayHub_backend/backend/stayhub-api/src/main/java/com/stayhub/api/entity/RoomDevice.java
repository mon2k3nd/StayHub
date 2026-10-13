package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "room_devices")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RoomDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "device_type", nullable = false)
    private Integer deviceType; // 1: Công tơ, 2: Đồng hồ nước, 3: Khóa vân tay, 4: Công tắc

    @Column(name = "ip_or_mac_address", length = 50)
    private String ipOrMacAddress;

    @Column(name = "api_token")
    private String apiToken;

    @Column(name = "last_recorded_value")
    private Double lastRecordedValue;

    @Column(name = "last_sync_time")
    private LocalDateTime lastSyncTime;
}
