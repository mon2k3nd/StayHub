package com.stayhub.api.entity.analytics;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "saas_performance_metrics")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SaasPerformanceMetrics {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDateTime recordedAt;
    
    // Annual Recurring Revenue
    private Double arr;
    
    // Monthly Recurring Revenue
    private Double mrr;
    
    // Lifetime Value
    private Double ltv;
    
    // Customer Acquisition Cost
    private Double cac;
    
    // Churn Rate percentage
    private Double churnRate;
    
    private Integer premiumAccounts;
    private Integer basicAccounts;
    
    // Daily Active Users
    private Integer dau;
    
    // Monthly Active Users
    private Integer mau;
}
