import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/datasources/branch_remote_data_source.dart';
import '../data/models/branch_model.dart';
import '../data/repositories/branch_repository_impl.dart';
import '../domain/repositories/branch_repository.dart';

part 'branch_notifier.g.dart';

@riverpod
BranchRemoteDataSource branchRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BranchRemoteDataSource(apiClient);
}

@Riverpod(keepAlive: true)
BranchRepository branchRepository(Ref ref) {
  final remoteDataSource = ref.watch(branchRemoteDataSourceProvider);
  return BranchRepositoryImpl(remoteDataSource);
}

final draftBranchesProvider = FutureProvider.autoDispose<List<BranchModel>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  final user = authState.value;
  if (user == null) return [];

  final repository = ref.watch(branchRepositoryProvider);
  return repository.loadDraftsByOwner(user.id);
});

final deletedBranchesProvider = FutureProvider.autoDispose<List<BranchModel>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  final user = authState.value;
  if (user == null) return [];

  final repository = ref.watch(branchRepositoryProvider);
  return repository.loadDeletedByOwner(user.id);
});

/// Provider cho màn hình "Quản lý chi nhánh": lấy TẤT CẢ chi nhánh (mọi trạng thái)
/// để nhóm theo: đang hoạt động / đang khởi tạo / ngừng hoạt động.
final managedBranchesProvider = FutureProvider.autoDispose<List<BranchModel>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  final user = authState.value;
  if (user == null) return [];

  final repository = ref.watch(branchRepositoryProvider);
  return repository.loadAllForManagement(user.id);
});

@Riverpod(keepAlive: true)
class BranchNotifier extends _$BranchNotifier {
  @override
  FutureOr<List<BranchModel>> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user == null) return [];

    final repository = ref.read(branchRepositoryProvider);
    return await repository.loadByOwner(user.id);
  }

  /// Lấy MỘT chi nhánh theo ID kèm `description` mới nhất từ server.
  /// Dùng cho wizard khi mở lại một bước để đảm bảo hiển thị đúng cấu trúc
  /// đã lưu (tránh model trong bộ nhớ bị cũ).
  Future<BranchModel?> getById(int branchId) async {
    try {
      final repository = ref.read(branchRepositoryProvider);
      return await repository.getById(branchId);
    } catch (e) {
      debugPrint('getById error: $e');
      return null;
    }
  }

  Future<void> refreshBranches() async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    if (!state.hasValue) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(branchRepositoryProvider);
      return repository.loadByOwner(user.id);
    });
  }

  Future<BranchModel?> createBranch(Map<String, dynamic> data) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return null;

    final repository = ref.read(branchRepositoryProvider);
    BranchModel? createdBranch;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      data['ownerId'] = user.id;
      createdBranch = await repository.createBranch(data);
      // Làm mới toàn bộ dashboard (stats, chi nhánh, phòng, bài đăng...).
      refreshOwnerDashboard(ref);
      return repository.loadByOwner(user.id);
    });

    return createdBranch;
  }

  /// Tạo chi nhánh NHÁP (DRAFT) cho wizard 4 bước.
  ///
  /// Khác [createBranch]: backend luôn ép `creationStatus = 'DRAFT'` và reset
  /// cờ 4 bước về false, nên chi nhánh chưa cấu hình xong sẽ KHÔNG lên chợ trọ
  /// và KHÔNG bị tính vào thống kê. Dùng cho Bước 1 của wizard.
  Future<BranchModel?> createWizardDraft(Map<String, dynamic> data) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return null;

    final repository = ref.read(branchRepositoryProvider);
    BranchModel? createdBranch;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      data['ownerId'] = user.id;
      createdBranch = await repository.createWizardDraft(data);
      refreshOwnerDashboard(ref);
      return repository.loadByOwner(user.id);
    });

    return createdBranch;
  }

  /// Cập nhật chi nhánh. Trả về [BranchModel] sau cập nhật (null nếu lỗi).
  ///
  /// QUAN TRỌNG: trả về chính model từ API thay vì tra trong danh sách
  /// `loadByOwner` (chỉ chứa chi nhánh đang hoạt động). Nhờ đó wizard 4 bước
  /// giữ đúng cờ `step1Done..step4Done` của chi nhánh NHÁP sau khi lưu.
  Future<BranchModel?> updateBranch(int id, Map<String, dynamic> data) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return null;

    final repository = ref.read(branchRepositoryProvider);

    state = const AsyncValue.loading();
    try {
      data['ownerId'] = user.id;
      // Gọi API cập nhật TRƯỚC — nếu backend ném lỗi (vd không đồng bộ được
      // phòng/WC ở bước 3) thì exception PHẢI nổi lên cho UI. Trước đây dùng
      // AsyncValue.guard nên lỗi bị nuốt im lặng: `updated` vẫn null nhưng
      // _save() ở bước 3 vẫn chạy markStep + hiện toast "đã lưu", khiến người
      // dùng tưởng đã lưu trong khi thực tế chưa có phòng nào.
      final updated = await repository.updateBranch(id, data);
      refreshOwnerDashboard(ref);
      final list = await repository.loadByOwner(user.id);
      state = AsyncValue.data(list);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> completeBranch(int id) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    final repository = ref.read(branchRepositoryProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.completeBranch(id);
      refreshOwnerDashboard(ref);
      return repository.loadByOwner(user.id);
    });
  }

  Future<void> approveBranch(int id, bool approved) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    final repository = ref.read(branchRepositoryProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.approveBranch(id, approved);
      refreshOwnerDashboard(ref);
      return repository.loadByOwner(user.id);
    });
  }

  Future<void> deleteBranch(int id) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    final repository = ref.read(branchRepositoryProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteBranch(id);
      ref.invalidate(deletedBranchesProvider);
      refreshOwnerDashboard(ref);
      return repository.loadByOwner(user.id);
    });
  }

  // ─── Quản lý chi nhánh (wizard 4 bước) ───

  /// Đánh dấu hoàn tất / bỏ hoàn tất 1 bước của wizard.
  /// Trả về BranchModel sau cập nhật (null nếu lỗi).
  Future<BranchModel?> markStep(int branchId, int step, bool done) async {
    final repository = ref.read(branchRepositoryProvider);
    BranchModel? updated;
    try {
      updated = await repository.markStep(branchId, step, done);
      // ĐÂY LÀ ĐIỂM MẤU CHỐT: sau khi đăng bài / hoàn tất bước, phải làm mới
      // dashboardStatsProvider (family) để ô "Chưa đăng" tự giảm ngay lập tức.
      refreshOwnerDashboard(ref);
      // KHÔNG invalidate chính branchProvider ở đây: đây là provider đang chạy
      // (self-invalidation) → Riverpod ném assertion "A provider cannot depend
      // on itself". Thay vào đó cập nhật state tại chỗ bằng dữ liệu mới.
      _syncBranchInState(updated);
    } catch (e) {
      debugPrint('markStep error: $e');
      rethrow;
    }
    return updated;
  }

  /// Đồng bộ một chi nhánh vừa thay đổi vào state hiện tại mà KHÔNG invalidate
  /// chính provider này (tránh self-dependency). Nếu state chưa có dữ liệu thì
  /// bỏ qua — lần build kế tiếp sẽ tự nạp lại.
  void _syncBranchInState(BranchModel? updated) {
    if (updated == null) return;
    final current = state.value;
    if (current == null) return;
    final idx = current.indexWhere((b) => b.id == updated.id);
    final next = List<BranchModel>.of(current);
    if (idx >= 0) {
      next[idx] = updated;
    } else {
      next.add(updated);
    }
    state = AsyncValue.data(next);
  }

  /// Hủy chi nhánh đang khởi tạo (DRAFT).
  ///
  /// Khác với [deleteBranch] (ngừng hoạt động = xóa mềm + gắn `_OFF_`),
  /// thao tác này xóa HẲN chi nhánh nháp và giải phóng mã chi nhánh
  /// hoàn toàn — mã coi như chưa từng xuất hiện.
  Future<void> cancelDraftBranch(int id) async {
    final repository = ref.read(branchRepositoryProvider);
    // Xóa cứng trên server TRƯỚC. Nếu bước này lỗi thì mới thực sự là lỗi.
    await repository.cancelDraftBranch(id);

    // Sau khi xóa thành công, việc refresh cache chỉ là "best-effort":
    // KHÔNG invalidate chính branchProvider (self-invalidation → assertion).
    // Thay vào đó loại bỏ chi nhánh vừa hủy khỏi state tại chỗ.
    try {
      refreshOwnerDashboard(ref);
      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(
          current.where((b) => b.id != id).toList(growable: false),
        );
      }
    } catch (e) {
      debugPrint('cancelDraftBranch refresh error (ignored): $e');
    }
  }

  /// Tạm ngừng hoạt động chi nhánh.
  Future<void> suspendBranch(int id) async {
    final repository = ref.read(branchRepositoryProvider);
    final updated = await repository.suspendBranch(id);
    refreshOwnerDashboard(ref);
    _syncBranchInState(updated);
  }

  /// Kích hoạt lại chi nhánh đã tạm ngừng.
  Future<void> resumeBranch(int id) async {
    final repository = ref.read(branchRepositoryProvider);
    final updated = await repository.resumeBranch(id);
    refreshOwnerDashboard(ref);
    _syncBranchInState(updated);
  }
}
