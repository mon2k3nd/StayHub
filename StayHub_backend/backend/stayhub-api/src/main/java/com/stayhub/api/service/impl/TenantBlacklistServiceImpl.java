package com.stayhub.api.service.impl;

import com.stayhub.api.entity.TenantBlacklist;
import com.stayhub.api.entity.TenantProfile;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.TenantBlacklistRepository;
import com.stayhub.api.repository.TenantProfileRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.TenantBlacklistService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TenantBlacklistServiceImpl implements TenantBlacklistService {

    private final TenantBlacklistRepository blacklistRepository;
    private final TenantProfileRepository tenantProfileRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public TenantBlacklist reportBlacklist(Long tenantId, Long ownerId, String reason, String proofUrl) {
        User tenant = userRepository.findById(tenantId)
                .orElseThrow(() -> new RuntimeException("Tenant not found"));
        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new RuntimeException("Owner not found"));

        // Deduct trust score
        TenantProfile profile = tenantProfileRepository.findByUserId(tenantId)
                .orElseGet(() -> {
                    TenantProfile newProfile = new TenantProfile();
                    newProfile.setUser(tenant);
                    newProfile.setTrustScore(100);
                    return tenantProfileRepository.save(newProfile);
                });

        int currentScore = profile.getTrustScore() != null ? profile.getTrustScore() : 100;
        int newScore = Math.max(0, currentScore - 30);
        profile.setTrustScore(newScore);
        tenantProfileRepository.save(profile);

        if (newScore < 50) {
            tenant.setStatus(User.UserStatus.BANNED_RENTING);
            userRepository.save(tenant);
        }

        TenantBlacklist blacklist = TenantBlacklist.builder()
                .tenant(tenant)
                .owner(owner)
                .reason(reason)
                .proofUrl(proofUrl)
                .build();

        return blacklistRepository.save(blacklist);
    }

    @Override
    public List<TenantBlacklist> getBlacklistsByTenant(Long tenantId) {
        return blacklistRepository.findByTenantId(tenantId);
    }
}
