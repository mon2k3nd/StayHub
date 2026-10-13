package com.stayhub.api.repository;

import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.ContractStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ContractRepository extends JpaRepository<Contract, Long> {
    List<Contract> findByTenantId(Long tenantId);
    long countByTenantIdAndStatus(Long tenantId, ContractStatus status);
    List<Contract> findByOwnerId(Long ownerId);
    List<Contract> findByRoomId(Long roomId);
    List<Contract> findByRoomIdAndStatus(Long roomId, ContractStatus status);
    Optional<Contract> findByRoomIdAndTenantIdAndStatus(Long roomId, Long tenantId, ContractStatus status);
    Optional<Contract> findByRoomIdAndStatusIn(Long roomId, List<ContractStatus> statuses);
    List<Contract> findByStatus(ContractStatus status);

    @Query("SELECT r.roomName FROM Contract c JOIN Room r ON c.roomId = r.id WHERE c.tenantId = :tenantId AND r.branchId = :branchId AND c.status = 'ACTIVE'")
    List<String> findActiveRoomNamesByTenantAndBranch(@Param("tenantId") Long tenantId, @Param("branchId") Long branchId);

    @Query("SELECT DISTINCT c.tenantId FROM Contract c JOIN Room r ON c.roomId = r.id WHERE r.branchId = :branchId AND c.status = 'ACTIVE'")
    List<Long> findActiveTenantIdsByBranch(@Param("branchId") Long branchId);

    // Hợp đồng sắp hết hạn (trong vòng 30 ngày)
    @Query("SELECT c FROM Contract c WHERE c.status = 'ACTIVE' AND c.endDate BETWEEN :today AND :in30Days")
    List<Contract> findExpiringContracts(@Param("today") LocalDate today, @Param("in30Days") LocalDate in30Days);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM Contract c WHERE c.id = :id")
    Optional<Contract> findByIdWithPessimisticLock(@Param("id") Long id);
}
