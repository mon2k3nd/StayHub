package com.stayhub.api.repository;

import com.stayhub.api.entity.PackageSubscription;
import com.stayhub.api.entity.SubscriptionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface PackageSubscriptionRepository extends JpaRepository<PackageSubscription, Long> {
    List<PackageSubscription> findByStatus(SubscriptionStatus status);
    List<PackageSubscription> findByOwnerId(Long ownerId);
    Optional<PackageSubscription> findByTransferCode(String transferCode);
    boolean existsByOwnerIdAndStatus(Long ownerId, SubscriptionStatus status);

    @org.springframework.data.jpa.repository.Query("SELECT COALESCE(SUM(p.amount), 0) FROM PackageSubscription p WHERE p.status = 'ACTIVE'")
    Double sumActiveRevenue();
}
