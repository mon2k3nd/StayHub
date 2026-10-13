package com.stayhub.api.repository;

import com.stayhub.api.entity.KycRequest;
import com.stayhub.api.entity.KycStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface KycRequestRepository extends JpaRepository<KycRequest, Long> {
    List<KycRequest> findByStatus(KycStatus status);
    Optional<KycRequest> findByUserId(Long userId);
    boolean existsByUserIdAndStatus(Long userId, KycStatus status);
}
