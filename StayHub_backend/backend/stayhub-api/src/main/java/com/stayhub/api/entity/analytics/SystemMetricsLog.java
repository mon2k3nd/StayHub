package com.stayhub.api.entity.analytics;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "system_metrics_log")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SystemMetricsLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDateTime recordedAt;
    
    // CPU usage percentage
    private Double cpuUsage;
    
    // RAM usage percentage
    private Double ramUsage;
    
    // API Latency in ms
    private Double avgApiLatencyMs;
    
    // Total DB Queries
    private Long totalDbQueries;
    
    // Storage used in GB
    private Double storageUsedGb;
    
    // Bandwidth used in GB
    private Double bandwidthUsedGb;
    
    // Error rate percentage (e.g. 5xx responses)
    private Double errorRate;
    
    private Integer activeConnections;
}
