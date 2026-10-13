package com.stayhub.api.repository;

import com.stayhub.api.entity.StaffWallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface StaffWalletRepository extends JpaRepository<StaffWallet, Long> {
    Optional<StaffWallet> findByStaffId(Long staffId);
}
