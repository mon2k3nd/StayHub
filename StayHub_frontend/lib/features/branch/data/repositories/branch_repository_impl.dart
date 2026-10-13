import '../../domain/repositories/branch_repository.dart';
import '../datasources/branch_remote_data_source.dart';
import '../models/branch_model.dart';
import '../../../../core/utils/identifier_utils.dart';

class BranchRepositoryImpl implements BranchRepository {
  final BranchRemoteDataSource _remoteDataSource;

  const BranchRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<BranchModel>> loadByOwner(int ownerId) async {
    final res = await _remoteDataSource.loadByOwner(ownerId);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => _applyFallbackCode(e))
        .toList();
  }

  @override
  Future<BranchModel> getById(int branchId) async {
    final res = await _remoteDataSource.getById(branchId);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Không tải được chi nhánh ID: $branchId');
    }
    return _applyFallbackCode(rawData);
  }

  @override
  Future<Map<String, String?>> getBranchImages(int branchId) async {
    final data = await _remoteDataSource.getBranchImages(branchId);
    // BUGFIX (data): tránh `as String?` ném TypeError khi giá trị là số/object.
    return {
      'coverImage': data['coverImage']?.toString(),
      'coverImages': data['coverImages']?.toString(),
      'pcccImages': data['pcccImages']?.toString(),
    };
  }

  @override
  Future<List<BranchModel>> loadDeletedByOwner(int ownerId) async {
    final rawData = await _remoteDataSource.getDeletedBranches(ownerId);
    return rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => _applyFallbackCode(e))
        .toList();
  }

  @override
  Future<List<BranchModel>> loadDraftsByOwner(int ownerId) async {
    final res = await _remoteDataSource.loadDraftsByOwner(ownerId);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => _applyFallbackCode(e))
        .toList();
  }

  // ────────────────────────────────────────────────────────────────
  // LƯU Ý QUAN TRỌNG VỀ _applyFallbackCode:
  //   CHỈ áp dụng cho các method ĐỌC (loadByOwner / loadDraftsByOwner /
  //   loadAllForManagement / loadDeletedByOwner) để hiển thị tạm cho dữ liệu
  //   cũ thiếu mã. TUYỆT ĐỐI KHÔNG áp dụng cho các method GHI (create /
  //   update / complete / markStep / suspend / resume), vì khi đó mã hiển
  //   thị sẽ KHÁC mã thật trong DB → người dùng thấy "không trùng" nhưng
  //   backend lại báo trùng, hoặc ngược lại.
  // ────────────────────────────────────────────────────────────────

  @override
  Future<BranchModel> createBranch(Map<String, dynamic> data) async {
    final res = await _remoteDataSource.createBranch(data);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Tạo chi nhánh thất bại: dữ liệu không hợp lệ.');
    }
    return BranchModel.fromJson(rawData);
  }

  @override
  Future<BranchModel> createWizardDraft(Map<String, dynamic> data) async {
    final res = await _remoteDataSource.createWizardDraft(data);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Tạo chi nhánh nháp thất bại: dữ liệu không hợp lệ.');
    }
    return BranchModel.fromJson(rawData);
  }

  @override
  Future<BranchModel> completeBranch(int branchId) async {
    final res = await _remoteDataSource.completeBranch(branchId);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Hoàn tất chi nhánh thất bại.');
    }
    return BranchModel.fromJson(rawData);
  }

  @override
  Future<BranchModel> updateBranch(
    int branchId,
    Map<String, dynamic> data,
  ) async {
    final res = await _remoteDataSource.updateBranch(branchId, data);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Cập nhật chi nhánh thất bại.');
    }
    return BranchModel.fromJson(rawData);
  }

  @override
  Future<void> deleteBranch(int branchId) async {
    await _remoteDataSource.deleteBranch(branchId);
  }

  @override
  Future<void> cancelDraftBranch(int branchId) async {
    await _remoteDataSource.cancelDraftBranch(branchId);
  }

  @override
  Future<BranchModel> approveBranch(int branchId, bool approved) async {
    final res = await _remoteDataSource.approveBranch(branchId, approved);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Phê duyệt chi nhánh thất bại.');
    }
    return BranchModel.fromJson(rawData);
  }

  // ─── Quản lý chi nhánh (wizard 4 bước) ───

  @override
  Future<List<BranchModel>> loadAllForManagement(int ownerId) async {
    final res = await _remoteDataSource.loadAllForManagement(ownerId);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => _applyFallbackCode(e))
        .toList();
  }

  @override
  Future<BranchModel> markStep(int branchId, int step, bool done) async {
    final res = await _remoteDataSource.markStep(branchId, step, done);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Cập nhật tiến độ bước $step thất bại.');
    }
    return BranchModel.fromJson(rawData);
  }

  @override
  Future<BranchModel> suspendBranch(int branchId) async {
    final res = await _remoteDataSource.suspendBranch(branchId);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Tạm ngừng chi nhánh thất bại.');
    }
    return BranchModel.fromJson(rawData);
  }

  @override
  Future<BranchModel> resumeBranch(int branchId) async {
    final res = await _remoteDataSource.resumeBranch(branchId);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Kích hoạt lại chi nhánh thất bại.');
    }
    return BranchModel.fromJson(rawData);
  }

  /// Đảm bảo mọi BranchModel đều có branchCode không null — CHỈ dùng cho
  /// các method ĐỌC để hiển thị tạm cho dữ liệu cũ thiếu mã.
  /// Data cũ không có branchCode sẽ được auto-gen từ branchName.
  BranchModel _applyFallbackCode(Map<String, dynamic> json) {
    final model = BranchModel.fromJson(json);
    if (model.branchCode == null || model.branchCode!.isEmpty) {
      return model.copyWith(
        branchCode: IdentifierUtils.generateBranchCodeFromName(
          model.branchName,
          hostId: model.ownerId,
        ),
      );
    }
    return model;
  }
}
