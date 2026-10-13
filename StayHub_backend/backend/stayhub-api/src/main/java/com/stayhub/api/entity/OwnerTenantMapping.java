package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

// Liên kết chủ nhà - nhân viên (dùng cùng bảng với owner-tenant relationship)
@Entity
@Table(name = "owner_tenant_mappings")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OwnerTenantMapping {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    // tenantId ở đây có thể là ID của khách thuê HOẶC nhân viên
    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "mapping_type")
    @Builder.Default
    private String mappingType = "TENANT"; // TENANT | STAFF

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
