package com.stayhub.api.repository;

import com.stayhub.api.entity.SignatureHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SignatureHistoryRepository extends JpaRepository<SignatureHistory, Long> {
    List<SignatureHistory> findByUserIdOrderByCreatedAtDesc(Long userId);
}
