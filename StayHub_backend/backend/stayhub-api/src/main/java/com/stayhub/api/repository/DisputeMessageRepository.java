package com.stayhub.api.repository;

import com.stayhub.api.entity.DisputeMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DisputeMessageRepository extends JpaRepository<DisputeMessage, Long> {
    List<DisputeMessage> findByBillIdOrderByCreatedAtAsc(Long billId);
}
