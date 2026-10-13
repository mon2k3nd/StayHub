package com.stayhub.api.entity.analytics;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "market_intelligence")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MarketIntelligence {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDateTime recordedAt;
    
    // Average Rent in the region
    private Double avgRentPrice;
    
    // Overall market occupancy rate
    private Double regionOccupancyRate;
    
    // Top searched region name
    private String topSearchedRegion;
    
    // Total rooms available in the market
    private Integer totalAvailableRooms;
    
    // Average days a room stays empty
    private Double avgDaysToFindTenant;
    
    // Average room size
    private Double avgRoomSizeSqm;
    
    // Average price per square meter
    private Double pricePerSqm;
}
