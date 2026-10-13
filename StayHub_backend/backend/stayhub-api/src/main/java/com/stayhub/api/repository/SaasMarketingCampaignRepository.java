package com.stayhub.api.repository;

import com.stayhub.api.entity.SaasMarketingCampaign;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SaasMarketingCampaignRepository extends JpaRepository<SaasMarketingCampaign, Long> {
    Optional<SaasMarketingCampaign> findByDiscountCodeAndIsActiveTrue(String discountCode);
}
