package com.stayhub.api.repository;

import com.stayhub.api.entity.Bill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;

@Repository
public interface BillRepository extends JpaRepository<Bill, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT b FROM Bill b WHERE b.id = :id")
    Optional<Bill> findByIdWithLock(@Param("id") Long id);

    List<Bill> findByRoomId(Long roomId);
    List<Bill> findByTenantId(Long tenantId);
    List<Bill> findByTenantIdOrderByCreatedAtDesc(Long tenantId);
    Optional<Bill> findByRoomIdAndMonthAndYear(Long roomId, int month, int year);
    boolean existsByRoomIdAndMonthAndYear(Long roomId, int month, int year);
    boolean existsByRoomIdAndStatusNot(Long roomId, String status);
    
    List<Bill> findByStatus(String status);

    @Query("SELECT b FROM Bill b WHERE b.isPaid = false AND b.tenantId = :tenantId ORDER BY b.year DESC, b.month DESC")
    List<Bill> findUnpaidByTenant(Long tenantId);

    @Query("SELECT b FROM Bill b WHERE b.isPaid = true AND b.collectedByStaffId = :staffId AND b.isRemitted = false ORDER BY b.paidAt DESC")
    List<Bill> findUnremittedByStaff(@Param("staffId") Long staffId);

    @Query("SELECT b.roomId FROM Bill b WHERE b.month = :month AND b.year = :year")
    List<Long> findRoomIdsByMonthAndYear(@Param("month") int month, @Param("year") int year);

    @Query("SELECT b FROM Bill b WHERE b.isPaid = true AND b.month = :month AND b.year = :year")
    List<Bill> findPaidByMonthYear(int month, int year);

    @Query("SELECT b FROM Bill b JOIN Room r ON b.roomId = r.id WHERE r.ownerId = :ownerId ORDER BY b.year DESC, b.month DESC")
    List<Bill> findByOwnerId(@Param("ownerId") Long ownerId);

    @Query("SELECT b FROM Bill b JOIN Room r ON b.roomId = r.id JOIN StaffAssignment sa ON r.branchId = sa.branchId WHERE sa.staffId = :staffId ORDER BY b.year DESC, b.month DESC")
    List<Bill> findByStaffId(@Param("staffId") Long staffId);

    @Query("SELECT b FROM Bill b JOIN Room r ON b.roomId = r.id WHERE r.branchId = :branchId AND b.month = :month AND b.year = :year")
    List<Bill> findByBranchIdAndMonthAndYear(@Param("branchId") Long branchId, @Param("month") int month, @Param("year") int year);
}

