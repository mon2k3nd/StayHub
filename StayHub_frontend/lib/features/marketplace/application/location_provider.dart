import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/core_providers.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum LocationStatus {
  unknown,
  checking,
  granted,
  denied,
  deniedForever,
  disabled,
}

class LocationState {
  final LocationStatus status;
  final double? latitude;
  final double? longitude;
  final List<Map<String, dynamic>> nearbyBranches;
  final bool isFetchingBranches;

  const LocationState({
    this.status = LocationStatus.unknown,
    this.latitude,
    this.longitude,
    this.nearbyBranches = const [],
    this.isFetchingBranches = false,
  });

  LocationState copyWith({
    LocationStatus? status,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>>? nearbyBranches,
    bool? isFetchingBranches,
  }) {
    return LocationState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nearbyBranches: nearbyBranches ?? this.nearbyBranches,
      isFetchingBranches: isFetchingBranches ?? this.isFetchingBranches,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
}

// ─── Notifier (Riverpod v3 compatible) ───────────────────────────────────────

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  /// Kiểm tra quyền đã có chưa (không xin lại nếu đã có).
  Future<void> checkExistingPermission() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      await _fetchPositionAndBranches();
    } else if (perm == LocationPermission.deniedForever) {
      state = state.copyWith(status: LocationStatus.deniedForever);
    }
  }

  /// Xin quyền vị trí (gọi khi user bấm nút ở Onboarding).
  Future<LocationStatus> requestPermission() async {
    state = state.copyWith(status: LocationStatus.checking);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(status: LocationStatus.disabled);
      return LocationStatus.disabled;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      state = state.copyWith(status: LocationStatus.deniedForever);
      return LocationStatus.deniedForever;
    }

    if (perm == LocationPermission.denied) {
      state = state.copyWith(status: LocationStatus.denied);
      return LocationStatus.denied;
    }

    // Quyền được cấp → lấy vị trí & pre-fetch phòng gần
    await _fetchPositionAndBranches();
    return LocationStatus.granted;
  }

  /// Lấy vị trí hiện tại và gọi API nearby branches ngầm.
  Future<void> _fetchPositionAndBranches() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      state = state.copyWith(
        status: LocationStatus.granted,
        latitude: position.latitude,
        longitude: position.longitude,
        isFetchingBranches: true,
      );

      // Gọi API nearby branches ngầm
      await _loadNearbyBranches(position.latitude, position.longitude);
    } catch (_) {
      state = state.copyWith(
        status: LocationStatus.granted,
        isFetchingBranches: false,
      );
    }
  }

  Future<void> _loadNearbyBranches(double lat, double lng) async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get(
        '/api/v1/branches/nearby',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': 5, 'limit': 20},
      );
      final data = resp.data['data'] as List? ?? [];
      state = state.copyWith(
        nearbyBranches: data.cast<Map<String, dynamic>>(),
        isFetchingBranches: false,
      );
    } catch (_) {
      state = state.copyWith(isFetchingBranches: false);
    }
  }

  /// Làm mới danh sách phòng gần (kéo refresh ở màn hình Home).
  Future<void> refresh() async {
    if (!state.hasLocation) return;
    state = state.copyWith(isFetchingBranches: true);
    await _loadNearbyBranches(state.latitude!, state.longitude!);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(() {
  return LocationNotifier();
});

/// Notifier điều phối toạ độ / địa chỉ tìm kiếm trên bản đồ giữa Search Header và GuestMarketplaceScreen
class MapSearchLocationNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setLocation(Map<String, dynamic>? location) {
    state = location;
  }
}

final mapSearchLocationProvider =
    NotifierProvider<MapSearchLocationNotifier, Map<String, dynamic>?>(
      MapSearchLocationNotifier.new,
    );
