package com.stayhub.api.service;

import com.stayhub.api.entity.SaasMarketingCampaign;
import com.stayhub.api.repository.SaasMarketingCampaignRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class MarketingService {

    private final SaasMarketingCampaignRepository campaignRepository;

    public List<SaasMarketingCampaign> getAllActiveCampaigns() {
        // Fetch all active campaigns
        return campaignRepository.findAll().stream()
                .filter(SaasMarketingCampaign::getIsActive)
                .toList();
    }

    public SaasMarketingCampaign createCampaign(SaasMarketingCampaign campaign) {
        return campaignRepository.save(campaign);
    }

    public void pushNotification(Long campaignId) {
        SaasMarketingCampaign campaign = campaignRepository.findById(campaignId)
                .orElseThrow(() -> new RuntimeException("Campaign not found"));
        // Mock push notification logic
        log.info("Pushing notification for campaign: {}", campaign.getName());
    }
}
