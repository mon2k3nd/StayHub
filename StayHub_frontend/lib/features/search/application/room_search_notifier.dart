import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/room_search_repository.dart';
import '../domain/models/room_search_filter.dart';

/// Trạng thái của màn tìm phòng: bộ lọc hiện tại + danh sách đã tích luỹ.
class RoomSearchState {
  final RoomSearchFilter filter;
  final List<Map<String, dynamic>> items;
  final int totalElements;
  final int page;
  final bool isLast;
  final bool isLoadingMore;
  final Object? error;

  const RoomSearchState({
    this.filter = RoomSearchFilter.empty,
    this.items = const [],
    this.totalElements = 0,
    this.page = 0,
    this.isLast = true,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => !isLast;

  RoomSearchState copyWith({
    RoomSearchFilter? filter,
    List<Map<String, dynamic>>? items,
    int? totalElements,
    int? page,
    bool? isLast,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return RoomSearchState(
      filter: filter ?? this.filter,
      items: items ?? this.items,
      totalElements: totalElements ?? this.totalElements,
      page: page ?? this.page,
      isLast: isLast ?? this.isLast,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier tìm phòng: gọi backend, debounce từ khoá, phân trang tích luỹ.
///
/// Mọi thay đổi bộ lọc đều reset về trang 0 và tải lại từ server → kết quả
/// luôn khớp bộ lọc, không lọc client-side trên danh sách đã tải.
class RoomSearchNotifier extends AsyncNotifier<RoomSearchState> {
  static const int _pageSize = 20;
  static const Duration _debounce = Duration(milliseconds: 350);

  Timer? _debounceTimer;
  int _requestSeq = 0;

  @override
  Future<RoomSearchState> build() async {
    ref.onDispose(() => _debounceTimer?.cancel());
    return _load(RoomSearchFilter.empty);
  }

  RoomSearchRepository get _repo => ref.read(roomSearchRepositoryProvider);

  Future<RoomSearchState> _load(RoomSearchFilter filter) async {
    final seq = ++_requestSeq;
    final page = await _repo.searchRooms(filter, page: 0, size: _pageSize);
    // Bỏ qua kết quả cũ nếu đã có request mới hơn.
    if (seq != _requestSeq) {
      return state.value ?? RoomSearchState(filter: filter);
    }
    return RoomSearchState(
      filter: filter,
      items: page.items,
      totalElements: page.totalElements,
      page: page.page,
      isLast: page.isLast,
    );
  }

  /// Cập nhật bộ lọc. Nếu chỉ đổi `keyword` thì debounce cho mượt khi gõ.
  void applyFilter(RoomSearchFilter filter, {bool debounce = false}) {
    _debounceTimer?.cancel();
    if (debounce) {
      _debounceTimer = Timer(_debounce, () => _reload(filter));
    } else {
      _reload(filter);
    }
  }

  /// Đổi từ khoá (debounced) — dùng cho ô search gõ liên tục.
  void setKeyword(String keyword) {
    final current = state.value?.filter ?? RoomSearchFilter.empty;
    if (current.keyword == keyword) return;
    applyFilter(current.copyWith(keyword: keyword), debounce: true);
  }

  /// Xoá toàn bộ bộ lọc.
  void clearFilter() => applyFilter(RoomSearchFilter.empty);

  void _reload(RoomSearchFilter filter) {
    if (state.hasValue) {
      // Giữ dữ liệu cũ trong lúc tải lại để tránh nhấp nháy (flicker) UI.
      // ignore: invalid_use_of_internal_member
      state = const AsyncLoading<RoomSearchState>().copyWithPrevious(state);
    } else {
      state = const AsyncLoading<RoomSearchState>();
    }
    unawaited(_runLoad(filter));
  }

  Future<void> _runLoad(RoomSearchFilter filter) async {
    state = await AsyncValue.guard(() => _load(filter));
  }

  /// Tải thêm trang kế tiếp (infinite scroll).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || current.isLast) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final next = await _repo.searchRooms(
        current.filter,
        page: current.page + 1,
        size: _pageSize,
      );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...next.items],
          totalElements: next.totalElements,
          page: next.page,
          isLast: next.isLast,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  /// Tải lại từ đầu với bộ lọc hiện tại (pull-to-refresh).
  Future<void> refresh() async {
    final filter = state.value?.filter ?? RoomSearchFilter.empty;
    state = AsyncData(
      (state.value ?? const RoomSearchState()).copyWith(
        isLoadingMore: false,
        clearError: true,
      ),
    );
    state = await AsyncValue.guard(() => _load(filter));
  }
}

final roomSearchProvider =
    AsyncNotifierProvider<RoomSearchNotifier, RoomSearchState>(
      RoomSearchNotifier.new,
    );

/// Metadata bộ lọc (khoảng giá/diện tích, loại phòng, tiện ích) — cache lại.
final roomFilterMetadataProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final repo = ref.watch(roomSearchRepositoryProvider);
      return repo.getFilterMetadata();
    });
