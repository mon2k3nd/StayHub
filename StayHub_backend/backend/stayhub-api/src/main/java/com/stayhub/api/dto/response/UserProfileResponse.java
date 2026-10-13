package com.stayhub.api.dto.response;

import com.stayhub.api.entity.User;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserProfileResponse {

    private Long id;
    private String fullName;
    private String phone;
    private String email;
    private String roleId;
    private String packageId;
    private String accountStatus;
    private boolean isRequestingOwner;
    private String cccdNumber;
    private String cccdIssueDate;
    private String cccdIssuePlace;
    private String emergencyContactName;
    private String emergencyContactPhone;
    private String vehicleType;
    private String licensePlate;
    private String hometown;
    private String gender;
    private String dateOfBirth;
    private String occupation;
    private String avatarUrl;
    private String cccdFrontUrl;
    private String cccdBackUrl;

    private String bankName;
    private String bankAccountNumber;
    private String bankAccountName;
    private String ownerStatus;
    private String signature;
    private String kycStatus;

    public static UserProfileResponse from(User user) {
        var owner = user.getOwnerProfile();
        var tenant = user.getTenantProfile();
        
        return UserProfileResponse.builder()
                .id(user.getId())
                .fullName(user.getName())
                .phone(user.getPhoneNumber())
                .email(user.getEmail())
                .roleId(user.getRoleId())
                .packageId(owner != null && owner.getPackageId() != null ? owner.getPackageId() : "FREE")
                .accountStatus(user.getAccountStatus())
                .isRequestingOwner(owner != null ? owner.getRequestingOwner() : false)
                .cccdNumber(tenant != null ? tenant.getCccdNumber() : null)
                .cccdIssueDate(tenant != null && tenant.getCccdIssueDate() != null ? tenant.getCccdIssueDate().toString() : null)
                .cccdIssuePlace(tenant != null ? tenant.getCccdIssuePlace() : null)
                .emergencyContactName(tenant != null ? tenant.getEmergencyContactName() : null)
                .emergencyContactPhone(tenant != null ? tenant.getEmergencyContactPhone() : null)
                .vehicleType(tenant != null ? tenant.getVehicleType() : null)
                .licensePlate(tenant != null ? tenant.getLicensePlate() : null)
                .hometown(tenant != null ? tenant.getHometown() : null)
                .gender(tenant != null ? tenant.getGender() : null)
                .dateOfBirth(tenant != null && tenant.getDateOfBirth() != null ? tenant.getDateOfBirth().toString() : null)
                .occupation(tenant != null ? tenant.getOccupation() : null)
                .avatarUrl(user.getAvatarUrl())
                .cccdFrontUrl(tenant != null ? tenant.getCccdFrontUrl() : null)
                .cccdBackUrl(tenant != null ? tenant.getCccdBackUrl() : null)
                .bankName(owner != null ? owner.getBankName() : null)
                .bankAccountNumber(owner != null ? owner.getBankAccountNumber() : null)
                .bankAccountName(owner != null ? owner.getBankAccountName() : null)
                .ownerStatus(owner != null && owner.getOwnerStatus() != null ? owner.getOwnerStatus().name() : null)
                .signature(owner != null ? owner.getSignature() : null)
                .kycStatus(tenant != null && tenant.getKycStatus() != null ? tenant.getKycStatus().name() : null)
                .build();
    }
}
