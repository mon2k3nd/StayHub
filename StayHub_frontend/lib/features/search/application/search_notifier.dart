import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/datasources/search_remote_data_source.dart';
import '../data/models/search_result_model.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return SearchRepositoryImpl(SearchRemoteDataSource(apiClient));
});

final searchProvider =
    AsyncNotifierProvider<SearchNotifier, GlobalSearchResponse?>(() {
      return SearchNotifier();
    });

class SearchNotifier extends AsyncNotifier<GlobalSearchResponse?> {
  Timer? _debounce;
  // BUGFIX (race condition): debounce chỉ huỷ Timer CHƯA bắn, không huỷ được
  // request đang bay. Nếu gõ nhanh, response của query CŨ có thể về SAU và
  // ghi đè kết quả của query MỚI → hiển thị sai. Dùng số thứ tự để chỉ nhận
  // kết quả của lần tìm mới nhất.
  int _requestSeq = 0;

  @override
  FutureOr<GlobalSearchResponse?> build() {
    ref.onDispose(() => _debounce?.cancel());
    return null; // Initial state is null (no search)
  }

  void search(String query) {
    if (query.trim().isEmpty) {
      _debounce?.cancel();
      _requestSeq++; // vô hiệu hoá mọi response đang bay
      state = const AsyncData(null);
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    state = const AsyncLoading();
    final int seq = ++_requestSeq;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final repository = ref.read(searchRepositoryProvider);
        final results = await repository.searchGlobal(query.trim());
        // Bỏ qua nếu đã có lần tìm mới hơn được phát đi trong lúc chờ.
        if (seq != _requestSeq) return;
        state = AsyncData(results);
      } catch (e, st) {
        if (seq != _requestSeq) return;
        state = AsyncError(e, st);
      }
    });
  }
}
