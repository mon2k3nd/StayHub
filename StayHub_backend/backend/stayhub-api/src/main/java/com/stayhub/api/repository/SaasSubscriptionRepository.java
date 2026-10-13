package com.stayhub.api.repository;

import com.stayhub.api.entity.SaasSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SaasSubscriptionRepository extends JpaRepository<SaasSubscription, Long> {
    Optional<SaasSubscription> findTopByOwnerIdAndStatusOrderByEndDateDesc(Long ownerId, String status);
    List<SaasSubscription> findByStatus(String status);
    
    @org.springframework.data.jpa.repository.Query("SELECT COUNT(s) FROM SaasSubscription s WHERE s.plan.id = :planId AND s.status = 'ACTIVE'")
    int countActiveByPlanId(@org.springframework.data.repository.query.Param("planId") Long planId);
    
    @org.springframework.data.jpa.repository.Query("SELECT COALESCE(SUM(s.amountPaid), 0) FROM SaasSubscription s WHERE s.plan.id = :planId")
    double sumRevenueByPlanId(@org.springframework.data.repository.query.Param("planId") Long planId);
}
