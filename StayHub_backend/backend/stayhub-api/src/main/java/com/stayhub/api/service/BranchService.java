package com.stayhub.api.service;

import com.stayhub.api.dto.response.NearbyBranchDto;
import com.stayhub.api.entity.Branch;
import java.util.List;

public interface BranchService {
    List<Branch> getByOwner(Long ownerId);
    List<Branch> getDeletedByOwner(Long ownerId);
    List<Branch> getDraftsByOwner(Long ownerId);
    Branch create(Branch branch);
    Branch complete(Long id);
    Branch update(Long id, Branch branch);
    void delete(Long id);

    /**
     * HỦY chi nhánh đang khởi tạo (DRAFT).
     *
     * <p>Khác với {@link #delete(Long)} (ngừng hoạt động = xóa mềm + thêm
     * hậu tố {@code _OFF_<id>}), hủy DRAFT nghĩa là chi nhánh
     * <b>coi như chưa từng xuất hiện</b>: xóa cứng bản ghi để trả lại
     * hoàn toàn {@code branch_code} cho lần tạo mới tiếp theo.
     */
    void cancelDraft(Long id);

    /**
     * Kiểm tra mã chi nhánh đã bị chiếm chưa.
     *
     * <p><b>Lưu ý quan trọng:</b> hàm này tính CẢ các branch đã xóa mềm
     * (bỏ qua {@code @SQLRestriction("is_deleted = false")}), vì cột
     * {@code branch_code} có UNIQUE INDEX ở tầng DB — mã của branch đã xóa
     * vẫn đang chiếm chỗ và sẽ gây lỗi trùng khi INSERT.
     *
     * <p>So khớp không phân biệt hoa/thường và đã trim khoảng trắng.
     */
    boolean isBranchCodeTaken(String code, Long excludeId);

    /**
     * Tìm chi nhánh đang chiếm mã (kể cả đã xóa mềm) để hiển thị thông tin
     * xung đột cho người dùng. Trả về {@code null} nếu mã chưa bị chiếm.
     */
    Branch findConflictingBranch(String code, Long excludeId);

    /**
     * Lấy TẤT CẢ chi nhánh của chủ nhà (mọi trạng thái) để màn hình
     * "Quản lý chi nhánh" nhóm theo: đang hoạt động / đang khởi tạo / ngừng hoạt động.
     */
    List<Branch> getAllByOwnerForManagement(Long ownerId);

    /**
     * Đánh dấu hoàn tất 1 bước trong wizard 4 bước.
     * Khi cả 4 bước đều true → tự động chuyển creationStatus sang COMPLETED.
     *
     * @param step bước cần đánh dấu (1..4)
     * @param done true = hoàn tất, false = bỏ đánh dấu
     */
    Branch markStep(Long id, int step, boolean done);

    /**
     * Tạm ngừng hoạt động chi nhánh (SUSPENDED) — giữ dữ liệu, ẩn khỏi chợ trọ.
     */
    Branch suspend(Long id);

    /**
     * Kích hoạt lại chi nhánh đã tạm ngừng (SUSPENDED → COMPLETED).
     */
    Branch resume(Long id);

    /**
     * Tìm các chi nhánh active trong bán kính radiusKm tính từ (lat, lng).
     * Sắp xếp theo khoảng cách tăng dần, trả về tối đa maxResults kết quả.
     */
    List<NearbyBranchDto> getNearbyBranches(double lat, double lng, double radiusKm, int maxResults);
}
