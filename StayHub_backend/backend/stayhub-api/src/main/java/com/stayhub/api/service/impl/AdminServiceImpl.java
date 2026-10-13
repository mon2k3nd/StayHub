package com.stayhub.api.service.impl;

import com.stayhub.api.entity.*;
import com.stayhub.api.repository.*;
import com.stayhub.api.service.AdminService;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.HashMap;
import java.util.Map;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
@RequiredArgsConstructor
@lombok.extern.slf4j.Slf4j
public class AdminServiceImpl implements AdminService {

    private final UserRepository userRepository;
    private final SaasPlanRepository saasPlanRepository;
    private final OwnerSubscriptionRepository ownerSubscriptionRepository;
    private final SystemAuditLogRepository auditLogRepository;
    private final NotificationService notificationService;
    private final BillRepository billRepository;
    private final RoomRepository roomRepository;
    private final BranchRepository branchRepository;
    private final SaasMarketingCampaignRepository campaignRepository;
    private final SystemLegalBlueprintRepository legalBlueprintRepository;
    private final ContractRepository contractRepository;
    private final TenantBlacklistRepository blacklistRepository;
    private final TenantProfileRepository tenantProfileRepository;
    private final ObjectMapper objectMapper;

    @Override
    public java.util.List<Map<String, Object>> getOwners(String status) {
        java.util.List<User> owners = userRepository.findOwners();
        if (status != null && !status.isEmpty()) {
            owners = owners.stream()
                .filter(u -> u.getOwnerProfile() != null && u.getOwnerProfile().getOwnerStatus() != null && u.getOwnerProfile().getOwnerStatus().name().equals(status))
                .toList();
        }
        
        return owners.stream().map(u -> {
            var op = u.getOwnerProfile();
            Map<String, Object> map = new HashMap<>();
            map.put("id", u.getId());
            map.put("name", u.getName());
            map.put("email", u.getEmail());
            map.put("phone", u.getPhoneNumber());
            // Null-safe: getRequestingOwner() là Boolean (có thể NULL) → Boolean.TRUE.equals()
            // để tránh NullPointerException khi auto-unbox.
            map.put("ownerStatus", op != null && op.getOwnerStatus() != null ? op.getOwnerStatus().name() : (op != null && Boolean.TRUE.equals(op.getRequestingOwner()) ? "PENDING_VERIFICATION" : "NONE"));
            map.put("packageId", op != null ? op.getPackageId() : null);
            return map;
        }).toList();
    }
    @Override
    public java.util.List<Map<String, Object>> getTenants(String search) {
        java.util.List<User> tenants = userRepository.findByRoleId("TENANT");
        
        if (search != null && !search.isEmpty()) {
            String q = search.toLowerCase();
            tenants = tenants.stream()
                .filter(u -> (u.getName() != null && u.getName().toLowerCase().contains(q)) || 
                             (u.getPhoneNumber() != null && u.getPhoneNumber().contains(q)))
                .toList();
        }
        
        return tenants.stream().map(u -> {
            var tp = u.getTenantProfile();
            Map<String, Object> map = new HashMap<>();
            map.put("id", u.getId());
            map.put("name", u.getName());
            map.put("email", u.getEmail());
            map.put("phone", u.getPhoneNumber());
            map.put("status", u.getStatus() != null ? u.getStatus().name() : "UNKNOWN");
            map.put("trustScore", tp != null && tp.getTrustScore() != null ? tp.getTrustScore() : 100);
            map.put("kycStatus", tp != null && tp.getKycStatus() != null ? tp.getKycStatus().name() : "UNVERIFIED");
            map.put("cccdNumber", tp != null ? tp.getCccdNumber() : null);
            return map;
        }).toList();
    }

    @Transactional
    @Override
    public void verifyOwner(Long ownerId, Long adminId, boolean approved, String reason) {
        User owner = userRepository.findById(ownerId).orElseThrow(() -> new RuntimeException("Owner not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(owner); } catch (Exception e) { log.error("Error parsing JSON", e); }

        if (approved) {
            if (owner.getOwnerProfile() == null) {
                var p = new com.stayhub.api.entity.OwnerProfile();
                p.setUser(owner);
                owner.setOwnerProfile(p);
            }
            owner.getOwnerProfile().setOwnerStatus(OwnerStatus.APPROVED);
            owner.setRoleId("OWNER");
            owner.getOwnerProfile().setPackageId("FREE");
            owner.getOwnerProfile().setRequestingOwner(false);
            
            SaasPlan freePlan = saasPlanRepository.findByPlanType("FREE").orElseThrow(() -> new RuntimeException("FREE plan missing"));
            OwnerSubscription sub = OwnerSubscription.builder()
                    .owner(owner)
                    .plan(freePlan)
                    .status("ACTIVE")
                    .build();
            ownerSubscriptionRepository.save(sub);
            
            notificationService.send(adminId, ownerId, NotificationScope.INDIVIDUAL, "KYC Approved", "Chúc mừng! Bạn đã trở thành Chủ nhà.", NotificationType.SYSTEM_ALERT, null, false, null, "{\"event\":\"KYC_APPROVED_SUCCESS\"}");
        } else {
            if (owner.getOwnerProfile() != null) {
                owner.getOwnerProfile().setOwnerStatus(OwnerStatus.REJECTED);
                owner.getOwnerProfile().setRequestingOwner(false);
            }
            notificationService.send(adminId, ownerId, NotificationScope.INDIVIDUAL, "KYC Rejected", "Hồ sơ của bạn bị từ chối. Lý do: " + reason, NotificationType.SYSTEM_ALERT, null, false, null, "{\"event\":\"KYC_REJECTED\"}");
        }
        
        userRepository.save(owner);
        
        String newData = null;
        try { newData = objectMapper.writeValueAsString(owner); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action("VERIFY_KYC")
                .targetId(ownerId.toString())
                .previousData(previousData)
                .newData(newData)
                .build();
        auditLogRepository.save(audit);
    }

    @Transactional
    @Override
    public void overrideOwnerData(Long ownerId, Long adminId, Map<String, String> data) {
        User owner = userRepository.findById(ownerId).orElseThrow(() -> new RuntimeException("Owner not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(owner); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        if (data.containsKey("fullName")) owner.setName(data.get("fullName"));
        if (data.containsKey("cccdNumber")) {
            if (owner.getTenantProfile() == null) {
                var tp = new com.stayhub.api.entity.TenantProfile();
                tp.setUser(owner);
                owner.setTenantProfile(tp);
            }
            owner.getTenantProfile().setCccdNumber(data.get("cccdNumber"));
        }
        if (data.containsKey("status") && "BAN".equals(data.get("status"))) {
            owner.setStatus(User.UserStatus.LOCKED);
        }
        
        userRepository.save(owner);
        
        String newData = null;
        try { newData = objectMapper.writeValueAsString(owner); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action("OVERRIDE_OWNER_DATA")
                .targetId(ownerId.toString())
                .previousData(previousData)
                .newData(newData)
                .build();
        auditLogRepository.save(audit);
    }

    @Override
    public Map<String, Object> getDashboardStats() {
        Map<String, Object> stats = new HashMap<>();
        // Mocking native query with JPA standard for simplicity, but the requirement said "Native Query".
        // I will implement basic counting.
        long totalRevenue = billRepository.findAll().stream().filter(b -> "PAID".equals(b.getStatus())).mapToLong(b -> b.getTotalAmount() != null ? b.getTotalAmount().longValue() : 0).sum();
        long totalOwners = userRepository.findByRoleId("OWNER").size();
        long totalRooms = roomRepository.count();
        long occupiedRooms = contractRepository.findByStatus(ContractStatus.ACTIVE).stream().map(c -> c.getRoomId()).distinct().count();
        double occupancyRate = totalRooms > 0 ? (double) occupiedRooms / totalRooms * 100 : 0;
        
        java.util.List<User> owners = userRepository.findByRoleId("OWNER");
        Map<String, Long> saasPackageRatio = new HashMap<>();
        for (User u : owners) {
            String pkg = u.getOwnerProfile() != null && u.getOwnerProfile().getPackageId() != null ? u.getOwnerProfile().getPackageId() : "FREE";
            saasPackageRatio.put(pkg, saasPackageRatio.getOrDefault(pkg, 0L) + 1);
        }
        
        stats.put("totalRevenue", totalRevenue);
        stats.put("totalOwners", totalOwners);
        stats.put("totalRooms", totalRooms);
        stats.put("occupancyRate", occupancyRate);
        stats.put("saasPackageRatio", saasPackageRatio);
        return stats;
    }

    @Override
    public java.util.List<Map<String, Object>> omniSearch(String query) {
        java.util.List<User> users = userRepository.findByOmniQuery(query);
        return users.stream().map(u -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", u.getId());
            map.put("name", u.getName());
            map.put("phone", u.getPhoneNumber());
            map.put("role", u.getRoleId());
            map.put("status", u.getStatus() != null ? u.getStatus().name() : "UNKNOWN");
            
            if ("OWNER".equals(u.getRoleId()) && u.getOwnerProfile() != null) {
                map.put("packageId", u.getOwnerProfile().getPackageId());
            } else if ("TENANT".equals(u.getRoleId()) && u.getTenantProfile() != null) {
                map.put("cccd", u.getTenantProfile().getCccdNumber());
                map.put("trustScore", u.getTenantProfile().getTrustScore());
            }
            return map;
        }).collect(java.util.stream.Collectors.toList());
    }

    @Override
    public Map<String, Object> getUserDetails(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        Map<String, Object> map = new HashMap<>();
        map.put("id", user.getId());
        map.put("name", user.getName());
        map.put("phone", user.getPhoneNumber());
        map.put("email", user.getEmail());
        map.put("role", user.getRoleId());
        map.put("status", user.getStatus() != null ? user.getStatus().name() : "UNKNOWN");
        map.put("avatarUrl", user.getAvatarUrl());
        map.put("createdAt", user.getCreatedAt() != null ? user.getCreatedAt().toString() : null);

        if ("OWNER".equals(user.getRoleId()) && user.getOwnerProfile() != null) {
            OwnerProfile op = user.getOwnerProfile();
            Map<String, Object> ownerData = new HashMap<>();
            ownerData.put("bankName", op.getBankName());
            ownerData.put("bankAccountNumber", op.getBankAccountNumber());
            ownerData.put("ownerStatus", op.getOwnerStatus() != null ? op.getOwnerStatus().name() : null);
            ownerData.put("packageId", op.getPackageId());
            ownerData.put("expiredAt", op.getExpiredAt() != null ? op.getExpiredAt().toString() : null);
            
            long totalRooms = roomRepository.findByOwnerId(userId).size();
            ownerData.put("totalRoomsOwned", totalRooms);
            
            map.put("ownerDetails", ownerData);
        } else if ("TENANT".equals(user.getRoleId()) && user.getTenantProfile() != null) {
            TenantProfile tp = user.getTenantProfile();
            Map<String, Object> tenantData = new HashMap<>();
            tenantData.put("cccdNumber", tp.getCccdNumber());
            tenantData.put("cccdIssuePlace", tp.getCccdIssuePlace());
            tenantData.put("hometown", tp.getHometown());
            tenantData.put("gender", tp.getGender());
            tenantData.put("dateOfBirth", tp.getDateOfBirth() != null ? tp.getDateOfBirth().toString() : null);
            tenantData.put("occupation", tp.getOccupation());
            tenantData.put("trustScore", tp.getTrustScore());
            tenantData.put("kycStatus", tp.getKycStatus() != null ? tp.getKycStatus().name() : null);
            tenantData.put("cccdFrontUrl", tp.getCccdFrontUrl());
            tenantData.put("cccdBackUrl", tp.getCccdBackUrl());
            tenantData.put("selfieUrl", tp.getSelfieUrl());
            
            java.util.List<Contract> contracts = contractRepository.findByTenantId(userId);
            java.util.List<Map<String, Object>> activeContracts = new java.util.ArrayList<>();
            java.util.List<Map<String, Object>> pastContracts = new java.util.ArrayList<>();
            
            for (Contract c : contracts) {
                Map<String, Object> cmap = new HashMap<>();
                cmap.put("id", c.getId());
                cmap.put("roomId", c.getRoomId());
                cmap.put("status", c.getStatus() != null ? c.getStatus().name() : null);
                cmap.put("startDate", c.getStartDate() != null ? c.getStartDate().toString() : null);
                cmap.put("endDate", c.getEndDate() != null ? c.getEndDate().toString() : null);
                cmap.put("depositAmount", c.getDepositAmount());
                
                if (c.getStatus() == ContractStatus.ACTIVE || c.getStatus() == ContractStatus.PENDING) {
                    activeContracts.add(cmap);
                } else {
                    pastContracts.add(cmap);
                }
            }
            tenantData.put("activeContracts", activeContracts);
            tenantData.put("pastContracts", pastContracts);
            
            map.put("tenantDetails", tenantData);
        }
        
        return map;
    }

    @Transactional
    @Override
    public void overrideBillStatus(Long billId, Long adminId) {
        Bill bill = billRepository.findById(billId).orElseThrow(() -> new RuntimeException("Bill not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(bill); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        bill.setStatus("PAID");
        billRepository.save(bill);
        
        String newData = null;
        try { newData = objectMapper.writeValueAsString(bill); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action("OVERRIDE_BILL_STATUS")
                .targetId(billId.toString())
                .previousData(previousData)
                .newData(newData)
                .build();
        auditLogRepository.save(audit);
    }

    @Override
    public Object getBranchCoordinates() {
        return branchRepository.findAll().stream()
            .map(branch -> {
                Map<String, Object> map = new HashMap<>();
                map.put("branchId", branch.getId());
                map.put("branchName", branch.getBranchName());
                map.put("latitude", branch.getLatitude());
                map.put("longitude", branch.getLongitude());
                
                // Get Owner's Subscription Plan
                String planName = "FREE";
                try {
                    User owner = userRepository.findById(branch.getOwnerId()).orElse(null);
                    if (owner != null && owner.getOwnerProfile() != null && owner.getOwnerProfile().getPackageId() != null) {
                        planName = owner.getOwnerProfile().getPackageId();
                    }
                } catch (Exception e) { log.error("Error parsing JSON", e); }
                map.put("plan", planName);
                map.put("ownerId", branch.getOwnerId());
                map.put("totalRooms", branch.getTotalRooms());
                return map;
            })
            .toList();
    }

    @Transactional
    @Override
    public void banOwner(Long ownerId, Long adminId, boolean isBanned) {
        User owner = userRepository.findById(ownerId).orElseThrow(() -> new RuntimeException("Owner not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(owner); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        if (isBanned) {
            owner.setStatus(User.UserStatus.LOCKED);
        } else {
            owner.setStatus(User.UserStatus.ACTIVE);
        }
        userRepository.save(owner);
        
        String newData = null;
        try { newData = objectMapper.writeValueAsString(owner); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action(isBanned ? "BAN_OWNER" : "UNBAN_OWNER")
                .targetId(ownerId.toString())
                .previousData(previousData)
                .newData(newData)
                .build();
        auditLogRepository.save(audit);
    }

    @Override
    public java.util.List<SaasPlan> getAllSaasPlans() {
        return saasPlanRepository.findAll();
    }

    @Transactional
    @Override
    public SaasPlan saveSaasPlan(SaasPlan plan) {
        return saasPlanRepository.save(plan);
    }

    @Override
    public java.util.List<SaasMarketingCampaign> getAllCampaigns() {
        return campaignRepository.findAll();
    }

    @Transactional
    @Override
    public SaasMarketingCampaign saveCampaign(SaasMarketingCampaign campaign) {
        return campaignRepository.save(campaign);
    }

    @Override
    public java.util.List<SystemLegalBlueprint> getAllLegalBlueprints() {
        return legalBlueprintRepository.findAll();
    }

    @Transactional
    @Override
    public SystemLegalBlueprint saveLegalBlueprint(SystemLegalBlueprint blueprint) {
        return legalBlueprintRepository.save(blueprint);
    }

    @Override
    public java.util.List<SystemAuditLog> getAuditLogs() {
        return auditLogRepository.findAll();
    }

    @Transactional
    @Override
    public void unbanTenant(Long tenantId, Long adminId, String reason) {
        User tenant = userRepository.findById(tenantId).orElseThrow(() -> new RuntimeException("Tenant not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(tenant); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        tenant.setStatus(User.UserStatus.ACTIVE);
        userRepository.save(tenant);
        
        String newData = null;
        try { newData = objectMapper.writeValueAsString(tenant); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action("UNBAN_TENANT")
                .targetId(tenantId.toString())
                .previousData(previousData)
                .newData(newData)
                .build();
        auditLogRepository.save(audit);
    }

    @Transactional
    @Override
    public void updateTrustScore(Long tenantId, Long adminId, int newScore, String reason) {
        User tenant = userRepository.findById(tenantId).orElseThrow(() -> new RuntimeException("Tenant not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        TenantProfile profile = tenantProfileRepository.findByUserId(tenantId).orElseThrow(() -> new RuntimeException("Tenant profile not found"));
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(profile); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        profile.setTrustScore(newScore);
        tenantProfileRepository.save(profile);

        if (newScore >= 50 && tenant.getStatus() == User.UserStatus.BANNED_RENTING) {
            tenant.setStatus(User.UserStatus.ACTIVE);
            userRepository.save(tenant);
        } else if (newScore < 50 && tenant.getStatus() == User.UserStatus.ACTIVE) {
            tenant.setStatus(User.UserStatus.BANNED_RENTING);
            userRepository.save(tenant);
        }
        
        String newData = null;
        try { newData = objectMapper.writeValueAsString(profile); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action("UPDATE_TRUST_SCORE")
                .targetId(tenantId.toString())
                .previousData(previousData)
                .newData(newData)
                .build();
        auditLogRepository.save(audit);
    }

    @Transactional
    @Override
    public void deleteBlacklist(Long blacklistId, Long adminId, String reason) {
        TenantBlacklist blacklist = blacklistRepository.findById(blacklistId).orElseThrow(() -> new RuntimeException("Blacklist record not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        User tenant = blacklist.getTenant();
        TenantProfile profile = tenantProfileRepository.findByUserId(tenant.getId()).orElseThrow(() -> new RuntimeException("Tenant profile not found"));
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(blacklist); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        // Restore score
        int currentScore = profile.getTrustScore() != null ? profile.getTrustScore() : 100;
        profile.setTrustScore(Math.min(100, currentScore + 30));
        tenantProfileRepository.save(profile);

        if (profile.getTrustScore() >= 50 && tenant.getStatus() == User.UserStatus.BANNED_RENTING) {
            tenant.setStatus(User.UserStatus.ACTIVE);
            userRepository.save(tenant);
        }
        
        blacklistRepository.delete(blacklist);
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action("DELETE_BLACKLIST")
                .targetId(blacklistId.toString())
                .previousData(previousData)
                .newData(null)
                .build();
        auditLogRepository.save(audit);
    }

    @Transactional
    @Override
    public void unlinkCccd(Long tenantId, Long adminId, String reason) {
        TenantProfile profile = tenantProfileRepository.findByUserId(tenantId).orElseThrow(() -> new RuntimeException("Tenant profile not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(profile); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        profile.setCccdNumber(null);
        profile.setKycStatus(KycStatus.UNVERIFIED);
        tenantProfileRepository.save(profile);
        
        String newData = null;
        try { newData = objectMapper.writeValueAsString(profile); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action("UNLINK_CCCD")
                .targetId(tenantId.toString())
                .previousData(previousData)
                .newData(newData)
                .build();
        auditLogRepository.save(audit);
    }

    @Transactional
    @Override
    public void manualEkyc(Long tenantId, Long adminId, String cccdNumber, String reason, boolean isApproved) {
        TenantProfile profile = tenantProfileRepository.findByUserId(tenantId).orElseThrow(() -> new RuntimeException("Tenant profile not found"));
        User admin = userRepository.findById(adminId).orElseThrow(() -> new RuntimeException("Admin not found"));
        
        if (isApproved && cccdNumber != null && tenantProfileRepository.existsByCccdNumber(cccdNumber) && !cccdNumber.equals(profile.getCccdNumber())) {
            throw new RuntimeException("CCCD đã được sử dụng bởi một tài khoản khác");
        }
        
        String previousData = null;
        try { previousData = objectMapper.writeValueAsString(profile); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        if (profile.getKycStatus() == KycStatus.REVERIFY_REQUESTED) {
            if (isApproved) {
                profile.setKycStatus(KycStatus.UNVERIFIED);
                notificationService.send(null, tenantId, com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                    "Yêu cầu xác thực lại được phê duyệt",
                    "Yêu cầu xác thực lại thông tin eKYC của bạn đã được phê duyệt. Vui lòng thực hiện quét CCCD mới.",
                    com.stayhub.api.entity.NotificationType.KYC_APPROVED, null, false, null, null);
            } else {
                profile.setKycStatus(KycStatus.APPROVED);
                notificationService.send(null, tenantId, com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                    "Yêu cầu xác thực lại bị từ chối",
                    "Yêu cầu xác thực lại thông tin eKYC của bạn bị từ chối. Lý do: " + (reason != null ? reason : "Không hợp lệ") + ".",
                    com.stayhub.api.entity.NotificationType.KYC_REJECTED, null, false, null, null);
            }
        } else {
            if (isApproved) {
                if (cccdNumber != null) profile.setCccdNumber(cccdNumber);
                profile.setKycStatus(KycStatus.APPROVED);
                notificationService.send(null, tenantId, com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                    "Hồ sơ định danh hợp lệ",
                    "Hồ sơ eKYC của bạn đã được phê duyệt thành công. Bạn đã có thể sử dụng đầy đủ các tính năng.",
                    com.stayhub.api.entity.NotificationType.KYC_APPROVED, null, false, null, null);
            } else {
                profile.setKycStatus(KycStatus.REJECTED);
                notificationService.send(null, tenantId, com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                    "Hồ sơ định danh bị từ chối",
                    "Hồ sơ eKYC của bạn bị từ chối. Lý do: " + (reason != null ? reason : "Hình ảnh mờ/không rõ nét") + ". Vui lòng cập nhật lại.",
                    com.stayhub.api.entity.NotificationType.KYC_REJECTED, null, false, null, null);
            }
        }
        tenantProfileRepository.save(profile);
        
        String newData = null;
        try { newData = objectMapper.writeValueAsString(profile); } catch (Exception e) { log.error("Error parsing JSON", e); }
        
        SystemAuditLog audit = SystemAuditLog.builder()
                .admin(admin)
                .action("MANUAL_EKYC")
                .targetId(tenantId.toString())
                .previousData(previousData)
                .newData(newData)
                .build();
        auditLogRepository.save(audit);
    }
}
