package com.stayhub.api.repository;

import com.stayhub.api.entity.SystemDebt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SystemDebtRepository extends JpaRepository<SystemDebt, Long> {
}
