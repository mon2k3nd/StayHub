package com.stayhub.api.repository;

import com.stayhub.api.entity.SharedFacility;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SharedFacilityRepository extends JpaRepository<SharedFacility, Long> {
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"rooms"})
    List<SharedFacility> findByBranchId(Long branchId);

    /**
     * Tìm TẤT CẢ tiện ích chung của chi nhánh KỂ CẢ bản ghi đã xoá mềm.
     *
     * <p>{@link SharedFacility} có {@code @SQLRestriction("is_deleted = false")}
     * nên {@link #findByBranchId(Long)} sẽ bỏ qua các tiện ích đã bị tắt lúc tạm
     * ngừng chi nhánh. Dùng native query để khôi phục chúng khi kích hoạt lại.</p>
     */
    @org.springframework.data.jpa.repository.Query(
            value = "SELECT * FROM shared_facilities WHERE branch_id = :branchId ORDER BY id ASC",
            nativeQuery = true)
    List<SharedFacility> findByBranchIdIncludingDeleted(
            @org.springframework.data.repository.query.Param("branchId") Long branchId);
}
