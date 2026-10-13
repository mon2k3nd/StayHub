import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/user_entity.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/wishlist_service.dart';
import 'dart:async' show unawaited;

class WishlistState {
  final Set<String> ids;
  final List<Map<String, dynamic>> available;
  final List<Map<String, dynamic>> upcoming;
  final List<Map<String, dynamic>> rented;
  final bool loading;

  WishlistState({
    this.ids = const {},
    this.available = const [],
    this.upcoming = const [],
    this.rented = const [],
    this.loading = false,
  });

  WishlistState copyWith({
    Set<String>? ids,
    List<Map<String, dynamic>>? available,
    List<Map<String, dynamic>>? upcoming,
    List<Map<String, dynamic>>? rented,
    bool? loading,
  }) {
    return WishlistState(
      ids: ids ?? this.ids,
      available: available ?? this.available,
      upcoming: upcoming ?? this.upcoming,
      rented: rented ?? this.rented,
      loading: loading ?? this.loading,
    );
  }
}

class WishlistNotifier extends Notifier<WishlistState> {
  @override
  WishlistState build() {
    // Listen for auth state changes to reload wishlist automatically
    ref.listen<AsyncValue<UserEntity?>>(authProvider, (previous, next) {
      if (next is AsyncData) {
        final prevId = previous?.value?.id;
        final nextId = next.value?.id;
        if (prevId != nextId) {
          unawaited(load());
        }
      }
    });

    // Load initial data asynchronously
    unawaited(Future.microtask(() => load()));

    return WishlistState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);

    final authUser = ref.read(authProvider).value;
    final client = ref.read(apiClientProvider);

    if (authUser?.id != null) {
      final res = await WishlistService.loadFromServer(
        authUser!.id.toString(),
        client,
      );

      final available = List<Map<String, dynamic>>.from(res['available'] ?? []);
      final upcoming = List<Map<String, dynamic>>.from(res['upcoming'] ?? []);
      final rented = List<Map<String, dynamic>>.from(res['rented'] ?? []);
      final ids = <String>{};

      for (final r in available) {
        final id = r['id']?.toString() ?? r['roomId']?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
      for (final r in upcoming) {
        final id = r['id']?.toString() ?? r['roomId']?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
      for (final r in rented) {
        final id = r['id']?.toString() ?? r['roomId']?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }

      state = WishlistState(
        ids: ids,
        available: available,
        upcoming: upcoming,
        rented: rented,
        loading: false,
      );
    } else {
      final local = await WishlistService.loadLocal();
      final ids = <String>{};
      for (final r in local) {
        final id = r['id']?.toString() ?? r['roomId']?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }

      state = WishlistState(
        ids: ids,
        available: local,
        upcoming: [],
        rented: [],
        loading: false,
      );
    }
  }

  Future<void> toggle(Map<String, dynamic> room) async {
    final authUser = ref.read(authProvider).value;
    final client = ref.read(apiClientProvider);
    final roomId = (room['id'] ?? room['roomId'])?.toString() ?? '';
    if (roomId.isEmpty) return;

    final wasLiked = state.ids.contains(roomId);

    // Optimistic Update
    final updatedIds = Set<String>.from(state.ids);
    if (wasLiked) {
      updatedIds.remove(roomId);
    } else {
      updatedIds.add(roomId);
    }
    state = state.copyWith(ids: updatedIds);

    try {
      if (authUser?.id != null) {
        await WishlistService.toggleOnServer(
          authUser!.id.toString(),
          roomId,
          client,
        );
      } else {
        await WishlistService.toggleLocal(room);
      }
      // Reload details after server success to update the lists
      await load();
    } catch (e) {
      // Revert optimistic update on failure
      final revertedIds = Set<String>.from(state.ids);
      if (wasLiked) {
        revertedIds.add(roomId);
      } else {
        revertedIds.remove(roomId);
      }
      state = state.copyWith(ids: revertedIds);
    }
  }

  Future<void> clear() async {
    final authUser = ref.read(authProvider).value;
    final client = ref.read(apiClientProvider);

    state = state.copyWith(ids: {}, available: [], rented: [], loading: true);

    try {
      await WishlistService.clearWishlist(
        authUser?.id.toString(),
        client: client,
      );
      state = state.copyWith(loading: false);
    } catch (e) {
      // Reload on failure to restore states
      await load();
    }
  }

  Future<void> updateNoteAndVisited(
    String roomId, {
    String? note,
    bool? isVisited,
  }) async {
    final authUser = ref.read(authProvider).value;
    final client = ref.read(apiClientProvider);

    void updateInList(List<Map<String, dynamic>> list) {
      for (final r in list) {
        final id = (r['id'] ?? r['roomId'])?.toString();
        if (id == roomId) {
          if (note != null) r['privateNote'] = note;
          if (isVisited != null) r['isVisited'] = isVisited;
        }
      }
    }

    final newAvail = List<Map<String, dynamic>>.from(state.available);
    final newUpcoming = List<Map<String, dynamic>>.from(state.upcoming);
    final newRented = List<Map<String, dynamic>>.from(state.rented);
    updateInList(newAvail);
    updateInList(newUpcoming);
    updateInList(newRented);
    state = state.copyWith(
      available: newAvail,
      upcoming: newUpcoming,
      rented: newRented,
    );

    try {
      if (authUser?.id != null) {
        await WishlistService.updateNoteAndVisited(
          authUser!.id.toString(),
          roomId,
          privateNote: note,
          isVisited: isVisited,
          client: client,
        );
      }
    } catch (_) {}
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, WishlistState>(() {
  return WishlistNotifier();
});
