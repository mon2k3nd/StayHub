import '../../data/models/branch_model.dart';

abstract class BranchRepository {
  Future<List<BranchModel>> loadByOwner(int ownerId);

  /// Lấy MỘT chi nhánh theo ID (kèm `description` mới nhất) — dùng cho wizard.
  Future<BranchModel> getById(int branchId);

  /// Lấy RIÊNG ảnh base64 (cover + PCCC) — vì API danh sách/chi tiết đã bỏ
  /// hai cột ảnh nặng để tránh OOM. Trả về map {coverImage, coverImages, pcccImages}.
  Future<Map<String, String?>> getBranchImages(int branchId);
  Future<List<BranchModel>> loadDeletedByOwner(int ownerId);
  Future<List<BranchModel>> loadDraftsByOwner(int ownerId);
  Future<BranchModel> createBranch(Map<String, dynamic> data);

  /// Tạo chi nhánh NHÁP (DRAFT) cho wizard 4 bước — không lên chợ trọ.
  Future<BranchModel> createWizardDraft(Map<String, dynamic> data);
  Future<BranchModel> completeBranch(int branchId);
  Future<BranchModel> updateBranch(int branchId, Map<String, dynamic> data);
  Future<BranchModel> approveBranch(int branchId, bool approved);
  Future<void> deleteBranch(int branchId);

  /// HỦY chi nhánh đang khởi tạo (DRAFT) — xóa cứng, giải phóng mã hoàn toàn.
  Future<void> cancelDraftBranch(int branchId);

  // ─── Quản lý chi nhánh (wizard 4 bước) ───
  /// Lấy TẤT CẢ chi nhánh (mọi trạng thái) cho màn hình Quản lý chi nhánh.
  Future<List<BranchModel>> loadAllForManagement(int ownerId);

  /// Đánh dấu hoàn tất / bỏ hoàn tất 1 bước (1..4) của wizard.
  Future<BranchModel> markStep(int branchId, int step, bool done);

  /// Tạm ngừng hoạt động chi nhánh.
  Future<BranchModel> suspendBranch(int branchId);

  /// Kích hoạt lại chi nhánh đã tạm ngừng.
  Future<BranchModel> resumeBranch(int branchId);
}
