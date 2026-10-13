package com.stayhub.api.repository;

import com.stayhub.api.entity.ContractInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContractInventoryRepository extends JpaRepository<ContractInventory, Long> {
    List<ContractInventory> findByContractId(Long contractId);
}