package com.stayhub.api.repository;

import com.stayhub.api.entity.OwnerSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OwnerSubscriptionRepository extends JpaRepository<OwnerSubscription, Long> {
    Optional<OwnerSubscription> findByOwnerIdAndStatus(Long ownerId, String status);
}
