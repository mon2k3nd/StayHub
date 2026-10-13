package com.stayhub.api.repository;

import com.stayhub.api.entity.CheckoutRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CheckoutRequestRepository extends JpaRepository<CheckoutRequest, Long> {
    List<CheckoutRequest> findByTenantId(Long tenantId);
    List<CheckoutRequest> findByOwnerId(Long ownerId);
    List<CheckoutRequest> findByRoomId(Long roomId);
}
