import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/application/analytics_provider.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/branch/application/branch_notifier.dart';
import '../../features/dashboard/application/dashboard_notifier.dart';
import '../../features/marketplace/application/owner_posts_provider.dart';
import '../../features/room/application/room_notifier.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// TRUNG TÂM LÀM MỚI DỮ LIỆU (REACTIVITY HUB)
/// ─────────────────────────────────────────────────────────────────────────────
///
/// VẤN ĐỀ GỐC:
/// `dashboardStatsProvider` là một **family provider** được sinh bởi
/// `@riverpod` với tham số `({int? month, int? year})`. Điều này có nghĩa:
///
///   • `dashboardStatsProvider()`                  → instance A (month=null, year=null)
///   • `dashboardStatsProvider(month: null, year: null)` → instance B (KHÁC A!)
///   • `dashboardStatsProvider(month: 9, year: 2026)`    → instance C
///
/// Khi gọi `ref.invalidate(dashboardStatsProvider)` (KHÔNG truyền tham số),
/// Riverpod chỉ vô hiệu hoá **family gốc**, KHÔNG hề chạm tới các instance
/// đang được `ref.watch(...)` thực tế. Vì vậy UI không bao giờ tự cập nhật —
/// phải kéo refresh (lúc đó code gọi đúng `dashboardStatsProvider()`) mới thấy
/// số liệu mới.
///
/// GIẢI PHÁP:
/// Tập trung mọi thao tác "ghi" (create/update/delete/publish/markStep...) đi
/// qua helper này để vô hiệu hoá **tất cả** instance đang sống của family,
/// cùng các provider phái sinh (analytics, posts, rooms, branches).
///
/// Dùng `ref.invalidate(dashboardStatsProvider(month: m, year: y))` cho từng
/// tổ hợp tham số mà app thực sự dùng. Riverpod bỏ qua an toàn nếu instance
/// chưa từng được tạo.
void refreshOwnerDashboard(Ref ref) {
  // 1) Dashboard stats — invalidate MỌI instance của family đang được dùng.
  //    (arg-less invalidate là vô nghĩa với family → phải chỉ định tham số)
  ref.invalidate(dashboardStatsProvider());
  ref.invalidate(dashboardStatsProvider(month: null, year: null));

  // 2) Danh sách chi nhánh / bản nháp.
  ref.invalidate(branchProvider);
  ref.invalidate(managedBranchesProvider);
  ref.invalidate(draftBranchesProvider);

  // 3) Phòng & bài đăng.
  ref.invalidate(allOwnerRoomsProvider);
  ref.invalidate(roomProvider);
  ref.invalidate(ownerPostsProvider);

  // 4) Analytics của chủ trọ (nếu đã đăng nhập).
  final ownerId = ref.read(authProvider).value?.id;
  if (ownerId != null) {
    ref.invalidate(ownerAnalyticsProvider(ownerId));
  }
}

/// Biến thể dùng được từ `WidgetRef` (trong widget/ConsumerState).
/// Uỷ quyền cho [refreshOwnerDashboard] để đảm bảo một nguồn sự thật duy nhất.
void refreshOwnerDashboardFromWidget(WidgetRef ref) {
  ref.invalidate(dashboardStatsProvider());
  ref.invalidate(dashboardStatsProvider(month: null, year: null));
  ref.invalidate(branchProvider);
  ref.invalidate(managedBranchesProvider);
  ref.invalidate(draftBranchesProvider);
  ref.invalidate(allOwnerRoomsProvider);
  ref.invalidate(roomProvider);
  ref.invalidate(ownerPostsProvider);
  final ownerId = ref.read(authProvider).value?.id;
  if (ownerId != null) {
    ref.invalidate(ownerAnalyticsProvider(ownerId));
  }
}
