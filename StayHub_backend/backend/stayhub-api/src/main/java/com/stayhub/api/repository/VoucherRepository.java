package com.stayhub.api.repository;

import com.stayhub.api.entity.Voucher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VoucherRepository extends JpaRepository<Voucher, Long> {

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT v FROM Voucher v WHERE v.id = :id")
    Optional<Voucher> findByIdWithPessimisticLock(@Param("id") Long id);

    Optional<Voucher> findByCodeAndIsActiveTrue(String code);

    List<Voucher> findByIsActiveTrue();

    List<Voucher> findByOwnerIdOrderByCreatedAtDesc(Long ownerId);

    List<Voucher> findByBranchId(Long branchId);

    /**
     * Kiểm tra {@code code} đã tồn tại chưa, KỂ CẢ voucher đã xoá mềm.
     *
     * <p>{@code vouchers.code} có UNIQUE INDEX ở tầng DB và KHÔNG phải partial
     * index — nó chặn cả dòng đã xoá mềm. Dùng native query để bỏ qua
     * {@code @SQLRestriction} khi tính hậu tố {@code _OFF_<id>} an toàn.</p>
     */
    @Query(value = "SELECT COUNT(*) > 0 FROM vouchers WHERE code = :code", nativeQuery = true)
    boolean existsByCodeIncludingDeleted(@Param("code") String code);

    @Query("""
        SELECT DISTINCT v FROM Voucher v 
        LEFT JOIN VoucherRoom vr ON vr.voucherId = v.id 
        WHERE v.isActive = true 
        AND (v.endDate IS NULL OR v.endDate >= CURRENT_DATE) 
        AND (v.totalUsageLimit = 0 OR v.usedCount < v.totalUsageLimit)
        AND (
            v.applyAllRooms = true 
            OR (v.branchId IS NOT NULL AND v.branchId = :branchId)
            OR vr.roomId = :roomId
        )
    """)
    List<Voucher> findApplicableVouchers(@Param("roomId") Long roomId, @Param("branchId") Long branchId);

    @Query("""
        SELECT DISTINCT v FROM Voucher v 
        LEFT JOIN VoucherRoom vr ON vr.voucherId = v.id 
        WHERE v.isActive = true 
        AND (v.endDate IS NULL OR v.endDate >= CURRENT_DATE) 
        AND (v.totalUsageLimit = 0 OR v.usedCount < v.totalUsageLimit)
        AND (
            v.applyAllRooms = true 
            OR (v.branchId IS NOT NULL AND v.branchId IN :branchIds)
            OR vr.roomId IN :roomIds
        )
    """)
    List<Voucher> findApplicableVouchersBatch(@Param("roomIds") List<Long> roomIds, @Param("branchIds") List<Long> branchIds);

    @Modifying
    @Query("""
        UPDATE Voucher v
        SET v.usedCount = v.usedCount + 1,
            v.isActive = CASE
                WHEN v.totalUsageLimit > 0 AND (v.usedCount + 1) >= v.totalUsageLimit THEN false
                ELSE v.isActive
            END,
            v.updatedAt = CURRENT_TIMESTAMP
        WHERE v.id = :id
    """)
    void incrementUsedCount(@Param("id") Long id);
}
