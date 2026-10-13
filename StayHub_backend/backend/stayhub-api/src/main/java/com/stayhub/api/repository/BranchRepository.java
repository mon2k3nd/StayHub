package com.stayhub.api.repository;

import com.stayhub.api.entity.Branch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface BranchRepository extends JpaRepository<Branch, Long> {
    List<Branch> findByOwnerIdAndIsActiveTrue(Long ownerId);
    List<Branch> findByOwnerIdAndIsActiveFalse(Long ownerId);
    List<Branch> findByOwnerIdAndIsActiveTrueAndCreationStatus(Long ownerId, String creationStatus);
    List<Branch> findByOwnerId(Long ownerId);
    long countByOwnerId(Long ownerId);

    /**
     * Đếm số chi nhánh ĐANG CHIẾM QUOTA của gói cước.
     *
     * <p>Không tính các chi nhánh đã NGỪNG HOẠT ĐỘNG (creationStatus = SUSPENDED)
     * vì khi tạm ngừng, toàn bộ phòng đã bị đóng ({@code DONG_CUA}) và mã chi
     * nhánh đã được "nhả" — chi nhánh đó không còn tiêu tốn tài nguyên vận hành.
     * Nếu vẫn tính, chủ trọ sẽ bị chặn tạo chi nhánh mới dù đã dừng hết.
     */
    @Query("SELECT COUNT(b) FROM Branch b WHERE b.ownerId = :ownerId " +
           "AND (b.creationStatus IS NULL OR b.creationStatus <> 'SUSPENDED')")
    long countActiveQuotaBranchesByOwnerId(@Param("ownerId") Long ownerId);
    boolean existsByBranchCode(String branchCode);
    boolean existsByBranchCodeAndIsActiveTrue(String branchCode);
    boolean existsByBranchCodeAndIsActiveTrueAndIdNot(String branchCode, Long excludeId);

    /**
     * Kiểm tra trùng mã BỎ QUA @SQLRestriction (tức là tính CẢ branch đã xóa mềm).
     *
     * <p>Lý do: cột {@code branch_code} có UNIQUE INDEX ở tầng DB, kể cả khi
     * branch đã bị xóa mềm thì mã vẫn đang chiếm chỗ. Nếu chỉ kiểm tra các
     * branch "nhìn thấy được" (is_deleted = false) thì sẽ báo "chưa trùng"
     * nhưng lúc INSERT lại vi phạm unique index → lỗi trùng mã.
     *
     * <p>So khớp không phân biệt hoa/thường và đã trim khoảng trắng.
     */
    @Query(value = "SELECT COUNT(*) > 0 FROM branches " +
                   "WHERE UPPER(TRIM(branch_code)) = UPPER(TRIM(:code)) " +
                   "AND (:excludeId IS NULL OR id <> :excludeId)",
           nativeQuery = true)
    boolean existsByBranchCodeIncludingDeleted(@Param("code") String code,
                                                @Param("excludeId") Long excludeId);

    /**
     * Tìm branch đang chiếm mã (kể cả đã xóa mềm) để hiển thị thông tin xung đột.
     */
    @Query(value = "SELECT * FROM branches " +
                   "WHERE UPPER(TRIM(branch_code)) = UPPER(TRIM(:code)) " +
                   "AND (:excludeId IS NULL OR id <> :excludeId) " +
                   "ORDER BY id ASC LIMIT 1",
           nativeQuery = true)
    java.util.Optional<Branch> findConflictingByBranchCode(@Param("code") String code,
                                                           @Param("excludeId") Long excludeId);

    @Query("SELECT b FROM Branch b WHERE b.creationStatus = 'DRAFT' AND b.createdAt < :cutoffDate")
    List<Branch> findOldDraftBranches(@Param("cutoffDate") java.time.LocalDateTime cutoffDate);

    /**
     * Bước 1 - Lọc thô (Bounding Box): Lấy các branch active trong hình chữ nhật lat/lng.
     * Nhanh hơn nhiều so với quét toàn bảng. Bước 2 (Haversine chính xác) thực hiện trong Java.
     */
    @Query("SELECT b FROM Branch b WHERE b.isActive = true " +
           "AND b.creationStatus = 'ACTIVE' " +
           "AND b.latitude IS NOT NULL AND b.longitude IS NOT NULL " +
           "AND b.latitude BETWEEN :minLat AND :maxLat " +
           "AND b.longitude BETWEEN :minLng AND :maxLng")
    List<Branch> findActiveBranchesInBoundingBox(
            @Param("minLat") double minLat,
            @Param("maxLat") double maxLat,
            @Param("minLng") double minLng,
            @Param("maxLng") double maxLng
    );
}
