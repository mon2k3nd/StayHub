package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "contract_inventories")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ContractInventory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "contract_id", nullable = false)
    private Long contractId;
    @Column(name = "item_name")
    private String itemName;
    @Column(name = "check_in_condition")
    private String checkInCondition;
    @Column(name = "check_in_images", columnDefinition = "TEXT")
    private String checkInImages;
    @Column(name = "check_out_condition")
    private String checkOutCondition;
    @Column(name = "check_out_images", columnDefinition = "TEXT")
    private String checkOutImages;
    @Column(name = "compensation_fee")
    private Double compensationFee;
    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}