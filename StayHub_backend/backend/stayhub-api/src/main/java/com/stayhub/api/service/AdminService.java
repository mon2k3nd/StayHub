package com.stayhub.api.service;

import java.util.Map;

public interface AdminService {
    java.util.List<Map<String, Object>> getOwners(String status);
    java.util.List<Map<String, Object>> getTenants(String search);
    void verifyOwner(Long ownerId, Long adminId, boolean approved, String reason);
    void overrideOwnerData(Long ownerId, Long adminId, Map<String, String> data);
    Map<String, Object> getDashboardStats();
    java.util.List<Map<String, Object>> omniSearch(String query);
    Map<String, Object> getUserDetails(Long userId);
    void overrideBillStatus(Long billId, Long adminId);
    Object getBranchCoordinates();
    void banOwner(Long ownerId, Long adminId, boolean isBanned);
    

    // Admin Deep Interventions (eKYC & Blacklist)
    void unbanTenant(Long tenantId, Long adminId, String reason);
    void updateTrustScore(Long tenantId, Long adminId, int newScore, String reason);
    void deleteBlacklist(Long blacklistId, Long adminId, String reason);
    void unlinkCccd(Long tenantId, Long adminId, String reason);
    void manualEkyc(Long tenantId, Long adminId, String cccdNumber, String reason, boolean isApproved);
    
    // SaaS Plans
    java.util.List<com.stayhub.api.entity.SaasPlan> getAllSaasPlans();
    com.stayhub.api.entity.SaasPlan saveSaasPlan(com.stayhub.api.entity.SaasPlan plan);
    
    // Marketing Campaigns
    java.util.List<com.stayhub.api.entity.SaasMarketingCampaign> getAllCampaigns();
    com.stayhub.api.entity.SaasMarketingCampaign saveCampaign(com.stayhub.api.entity.SaasMarketingCampaign campaign);
    
    // Legal Blueprints
    java.util.List<com.stayhub.api.entity.SystemLegalBlueprint> getAllLegalBlueprints();
    com.stayhub.api.entity.SystemLegalBlueprint saveLegalBlueprint(com.stayhub.api.entity.SystemLegalBlueprint blueprint);
    
    // Audit Logs
    java.util.List<com.stayhub.api.entity.SystemAuditLog> getAuditLogs();
}
