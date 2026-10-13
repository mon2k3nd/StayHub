package com.stayhub.api.repository;

import com.stayhub.api.entity.RentalRequest;
import com.stayhub.api.entity.RequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface RentalRequestRepository extends JpaRepository<RentalRequest, Long> {
    // Find pending requests for a list of room IDs
    List<RentalRequest> findAllByRoomIdInAndStatus(List<Long> roomIds, RequestStatus status);

    // Find the latest rental request by tenant
    RentalRequest findTopByTenantIdOrderBySubmittedAtDesc(Long tenantId);
}
