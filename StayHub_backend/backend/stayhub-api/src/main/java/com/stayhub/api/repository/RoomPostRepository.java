package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;

@Repository
public interface RoomPostRepository extends JpaRepository<RoomPost, Long>, JpaSpecificationExecutor<RoomPost> {
    Optional<RoomPost> findByRoomId(Long roomId);
    List<RoomPost> findByRoomIdIn(java.util.Collection<Long> roomIds);
    List<RoomPost> findByOwnerId(Long ownerId);
    org.springframework.data.domain.Page<RoomPost> findByStatus(String status, org.springframework.data.domain.Pageable pageable);

    // BUGFIX (nhất quán feed ↔ search): trước đây feed mặc định chỉ lọc
    // r.status = 'TRONG', trong khi RoomPostSpecification (dùng cho search)
    // lọc IN ('TRONG','SAP_TRONG'). Hệ quả: phòng "sắp trống" hiện khi TÌM KIẾM
    // nhưng BIẾN MẤT khỏi feed mặc định — dữ liệu không nhất quán giữa hai
    // đường vào. Nay đồng bộ cùng tập trạng thái. Đồng thời coi isDeleted NULL
    // là chưa xoá (dữ liệu cũ) cho khớp với specification.
    @Query("SELECT p FROM RoomPost p JOIN Room r ON p.roomId = r.id "
            + "WHERE p.status = 'ACTIVE' "
            + "AND r.status IN (com.stayhub.api.entity.RoomStatus.TRONG, com.stayhub.api.entity.RoomStatus.SAP_TRONG) "
            + "AND (r.isDeleted IS NULL OR r.isDeleted = false)")
    org.springframework.data.domain.Page<RoomPost> findActivePublicPosts(org.springframework.data.domain.Pageable pageable);

    // BUGFIX (perf/memory): getFilterMetadata() trước đây gọi findAll(spec) → nạp
    // TOÀN BỘ entity RoomPost (kèm mọi cột nặng) vào bộ nhớ chỉ để lấy roomId +
    // rentingPrice → nguy cơ OOM khi dữ liệu lớn, trái với chính comment của hàm.
    // Query projection nhẹ dưới đây chỉ kéo 2 cột cần thiết, giữ nguyên tập lọc
    // (tin ACTIVE + phòng TRONG/SAP_TRONG + chưa xoá) cho khớp specification.
    @Query("SELECT p.roomId, p.rentingPrice FROM RoomPost p JOIN Room r ON p.roomId = r.id "
            + "WHERE p.status = 'ACTIVE' "
            + "AND r.status IN (com.stayhub.api.entity.RoomStatus.TRONG, com.stayhub.api.entity.RoomStatus.SAP_TRONG) "
            + "AND (r.isDeleted IS NULL OR r.isDeleted = false)")
    List<Object[]> findActivePostRoomPricePairs();
}
