import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/marketplace_repository.dart';

final marketplacePostsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.getPosts();
});

class MarketplaceNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createPost(
    String title,
    String content,
    double price,
    String tag,
    String tagColor,
  ) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.createPost({
        'title': title,
        'content': content,
        'price': price,
        'tag': tag,
        'tagColor': tagColor,
      });
      ref.invalidate(marketplacePostsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final marketplaceProvider = AsyncNotifierProvider<MarketplaceNotifier, void>(
  () => MarketplaceNotifier(),
);
