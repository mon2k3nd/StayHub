package com.stayhub.api.repository;

import com.stayhub.api.entity.ElectronicContract;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import jakarta.persistence.LockModeType;
import java.util.Optional;

@Repository
public interface ElectronicContractRepository extends JpaRepository<ElectronicContract, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM ElectronicContract c WHERE c.id = :id")
    Optional<ElectronicContract> findByIdForSigning(@Param("id") Long id);

    Optional<ElectronicContract> findByRentalRequestId(Long rentalRequestId);
}
