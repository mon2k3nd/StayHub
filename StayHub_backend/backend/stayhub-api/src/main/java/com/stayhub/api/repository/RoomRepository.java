package com.stayhub.api.repository;

import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.RoomStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

@Repository
public interface RoomRepository extends JpaRepository<Room, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM Room r WHERE r.id = :id")
    Optional<Room> findByIdWithLock(@Param("id") Long id);

    List<Room> findByOwnerId(Long ownerId);
    long countByOwnerId(Long ownerId);

    /**
     * Đếm số phòng ĐANG CHIẾM QUOTA của gói cước.
     *
     * <p>Không tính các phòng đã ĐÓNG CỬA ({@code DONG_CUA}) — đây là các phòng
     * thuộc chi nhánh đã ngừng hoạt động, đã bị ẩn khỏi chợ trọ và không còn
     * được vận hành. Nhờ vậy chủ trọ dừng chi nhánh xong vẫn tạo được chi nhánh
     * mới trong hạn mức gói.
     */
    @Query("SELECT COUNT(r) FROM Room r WHERE r.ownerId = :ownerId " +
           "AND (r.status IS NULL OR r.status <> com.stayhub.api.entity.RoomStatus.DONG_CUA)")
    long countActiveQuotaRoomsByOwnerId(@Param("ownerId") Long ownerId);
    Page<Room> findByOwnerId(Long ownerId, Pageable pageable);

    default Page<Room> findByOwnerIdPaged(Long ownerId, Pageable pageable) {
        return findByOwnerId(ownerId, pageable);
    }

    List<Room> findByOwnerIdAndStatus(Long ownerId, RoomStatus status);
    @EntityGraph(attributePaths = {"sharedFacilities"})
    List<Room> findByBranchId(Long branchId);
    long countByBranchId(Long branchId);
    @Query("SELECT r.branchId, COUNT(r) FROM Room r WHERE r.branchId IN :branchIds GROUP BY r.branchId")
    List<Object[]> countRoomsByBranchIdIn(@Param("branchIds") List<Long> branchIds);

    List<Room> findByBranchIdIn(List<Long> branchIds);
    boolean existsByBranchIdAndRoomName(Long branchId, String roomName);
    
    @Query("SELECT r FROM Room r WHERE r.ownerId = :ownerId " +
           "AND (:branchId IS NULL OR r.branchId = :branchId) " +
           "AND (:status IS NULL OR r.status = :status) " +
           "AND (:maxPrice IS NULL OR r.price <= :maxPrice)")
    Page<Room> filterRooms(
        @Param("ownerId") Long ownerId,
        @Param("branchId") Long branchId,
        @Param("status") RoomStatus status,
        @Param("maxPrice") Double maxPrice,
        Pageable pageable
    );
    Optional<Room> findByCurrentTenantId(Long tenantId);
    Optional<Room> findByActiveOtpCode(String activeOtpCode);

    @Query("SELECT r FROM Room r WHERE r.status = 'TRONG' AND r.branchId IN (SELECT b.id FROM Branch b WHERE b.creationStatus = 'COMPLETED')")
    Page<Room> findPublicRooms(Pageable pageable);

    @Query("SELECT r FROM Room r WHERE r.ownerId = :ownerId AND r.id NOT IN (SELECT c.roomId FROM Contract c WHERE c.status = 'ACTIVE')")
    Page<Room> findRoomsWithoutActiveContract(@Param("ownerId") Long ownerId, Pageable pageable);

    @Query("SELECT COUNT(r) FROM Room r WHERE r.ownerId = :ownerId AND r.status = 'DA_THUE'")
    long countOccupied(@Param("ownerId") Long ownerId);

    /** Đếm phòng đã cấu hình (loại bỏ phòng chờ setup) */
    @Query("SELECT COUNT(r) FROM Room r WHERE r.ownerId = :ownerId AND r.status <> 'KHOA_CHO_CAP_NHAT'")
    long countConfigured(@Param("ownerId") Long ownerId);

    /** Lấy danh sách phòng đã cấu hình */
    @Query("SELECT r FROM Room r WHERE r.ownerId = :ownerId AND r.status <> 'KHOA_CHO_CAP_NHAT'")
    List<Room> findConfiguredByOwnerId(@Param("ownerId") Long ownerId);

    /** Đếm phòng chờ chủ nhà cấu hình */
    @Query("SELECT COUNT(r) FROM Room r WHERE r.ownerId = :ownerId AND r.status = 'KHOA_CHO_CAP_NHAT'")
    long countPendingConfig(@Param("ownerId") Long ownerId);

    /** Đếm phòng đang trống và đã cấu hình xong (status=TRONG, không phải KHOA_CHO_CAP_NHAT) */
    @Query("SELECT COUNT(r) FROM Room r WHERE r.ownerId = :ownerId AND r.status = 'TRONG'")
    long countVacant(@Param("ownerId") Long ownerId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM Room r WHERE r.id = :id")
    Optional<Room> findByIdWithPessimisticLock(@Param("id") Long id);

    /**
     * Xoá cứng nhiều phòng bằng một câu lệnh bulk.
     *
     * <p>Dùng thay cho {@code deleteAll(entities)} khi đồng bộ cấu trúc ở Bước 3:
     * {@code Room.sharedFacilities} là collection EAGER phía INVERSE, nên xoá
     * từng entity khiến Hibernate cố dọn collection và có thể phát sinh lỗi
     * hoặc để lại rác trong bảng nối. Bulk delete chỉ chạm bảng {@code rooms};
     * bảng nối đã được dọn riêng bằng native SQL trước đó.</p>
     */
    @org.springframework.data.jpa.repository.Modifying
    @Query("DELETE FROM Room r WHERE r.id IN :ids")
    void deleteByIdIn(@Param("ids") List<Long> ids);

    /**
     * Tìm phòng theo {@code room_code} KỂ CẢ phòng đã xoá mềm.
     *
     * <p>{@link Room} có {@code @SQLRestriction("is_deleted = false")} nên các
     * truy vấn JPQL thông thường sẽ ẩn phòng đã xoá mềm. Tuy nhiên ràng buộc
     * UNIQUE trên {@code rooms.room_code} KHÔNG phải partial index — nó vẫn
     * chặn cả các dòng đã xoá mềm. Vì vậy khi đồng bộ cấu trúc ở Bước 3, nếu
     * client tạo lại phòng trùng mã với một phòng đã xoá mềm, backend phải
     * "hồi sinh" dòng cũ thay vì INSERT mới (nếu không sẽ lỗi
     * {@code duplicate key value violates unique constraint}).</p>
     *
     * <p>Dùng native query để bỏ qua {@code @SQLRestriction}.</p>
     */
    @Query(value = "SELECT * FROM rooms WHERE room_code = :code ORDER BY id ASC LIMIT 1",
           nativeQuery = true)
    Optional<Room> findByRoomCodeIncludingDeleted(@Param("code") String code);

    /**
     * Tìm TẤT CẢ phòng của một chi nhánh KỂ CẢ phòng đã xoá mềm.
     *
     * <p>Dùng khi KÍCH HOẠT LẠI chi nhánh: lúc tạm ngừng, mọi phòng đã bị
     * {@code is_deleted = true} nên {@link #findByBranchId(Long)} (bị chặn bởi
     * {@code @SQLRestriction}) sẽ trả về danh sách rỗng và không thể khôi phục.</p>
     */
    @Query(value = "SELECT * FROM rooms WHERE branch_id = :branchId ORDER BY id ASC",
           nativeQuery = true)
    List<Room> findByBranchIdIncludingDeleted(@Param("branchId") Long branchId);
}
