import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { list, map }

class GuestViewModeNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() => ViewMode.list;

  void setMode(ViewMode mode) {
    state = mode;
  }
}

final guestViewModeProvider = NotifierProvider<GuestViewModeNotifier, ViewMode>(
  () => GuestViewModeNotifier(),
);

class GuestActiveCategoryNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setCategory(int? category) {
    state = category;
  }
}

final guestActiveCategoryProvider =
    NotifierProvider<GuestActiveCategoryNotifier, int?>(
      () => GuestActiveCategoryNotifier(),
    );

final guestHeaderHeightProvider = Provider<double>((ref) {
  final activeCategory = ref.watch(guestActiveCategoryProvider);
  return activeCategory != null ? 160.0 : 224.0;
});
