package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "tenant_profiles")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TenantProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", referencedColumnName = "id", nullable = false)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private User user;

    @Column(name = "cccd_number")
    private String cccdNumber;

    @Column(name = "cccd_issue_date")
    private LocalDateTime cccdIssueDate;

    @Column(name = "cccd_issue_place")
    private String cccdIssuePlace;

    @Column(name = "hometown")
    private String hometown;

    @Column(name = "gender")
    private String gender;

    @Column(name = "date_of_birth")
    private LocalDateTime dateOfBirth;

    @Column(name = "emergency_contact_name")
    private String emergencyContactName;

    @Column(name = "emergency_contact_phone")
    private String emergencyContactPhone;

    @Column(name = "vehicle_type")
    private String vehicleType;

    @Column(name = "license_plate")
    private String licensePlate;

    @Column(name = "occupation")
    private String occupation;

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status")
    @Builder.Default
    private KycStatus kycStatus = KycStatus.UNVERIFIED;

    // Ảnh KYC lưu trữ
    @Column(name = "cccd_front_url", length = 500)
    private String cccdFrontUrl;

    @Column(name = "cccd_back_url", length = 500)
    private String cccdBackUrl;

    @Column(name = "selfie_url", length = 500)
    private String selfieUrl;

    @Column(name = "trust_score")
    @Builder.Default
    private Integer trustScore = 100;

    @Column(name = "mbti_type", length = 4)
    private String mbtiType;


    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
