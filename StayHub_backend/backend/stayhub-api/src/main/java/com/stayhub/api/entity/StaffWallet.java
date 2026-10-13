package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "staff_wallets")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StaffWallet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "staff_id", nullable = false, unique = true)
    private Long staffId;

    @Column(name = "cash_collected", nullable = false)
    @Builder.Default
    private Double cashCollected = 0.0;

    @Column(name = "cash_spent", nullable = false)
    @Builder.Default
    private Double cashSpent = 0.0;

    @Column(name = "max_cash_limit")
    private Double maxCashLimit; // Nullable means no limit by default
}
