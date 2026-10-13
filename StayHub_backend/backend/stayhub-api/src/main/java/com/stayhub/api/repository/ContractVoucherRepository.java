package com.stayhub.api.repository;

import com.stayhub.api.entity.ContractVoucher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

@Repository
public interface ContractVoucherRepository extends JpaRepository<ContractVoucher, Long> {
    Optional<ContractVoucher> findByContractIdAndStatus(Long contractId, ContractVoucher.ContractVoucherStatus status);
    List<ContractVoucher> findByContractId(Long contractId);
}
