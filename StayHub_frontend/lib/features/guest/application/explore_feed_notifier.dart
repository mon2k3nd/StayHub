import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/services/viewed_history_service.dart';
import '../../marketplace/application/location_provider.dart';

class ExploreSectionConfig {
  final String id;
  final String title;
  final String? subtitle;
  final String? endpoint;
  final Map<String, dynamic>? query;
  final List<dynamic>? preloadedItems;

  const ExploreSectionConfig({
    required this.id,
    required this.title,
    this.subtitle,
    this.endpoint,
    this.query,
    this.preloadedItems,
  });
}

class ExploreSectionState {
  final List<dynamic> items;
  final bool isLoading;
  final String? error;

  const ExploreSectionState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  bool get isEmpty => items.isEmpty && !isLoading && error == null;

  ExploreSectionState copyWith({
    List<dynamic>? items,
    bool? isLoading,
    Object? error = _unset,
  }) {
    // BUGFIX: trước đây `error as String?` ném TypeError nếu caller truyền một
    // Object không phải String (vd Exception). Nay chuẩn hoá an toàn: null giữ
    // null, String giữ nguyên, còn lại dùng `.toString()`.
    final Object? nextError = identical(error, _unset)
        ? this.error
        : error?.toString();
    return ExploreSectionState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: nextError as String?,
    );
  }
}

const Object _unset = Object();

class ExploreFeedState {
  final List<ExploreSectionConfig> configs;
  final Map<String, ExploreSectionState> sections;

  const ExploreFeedState({this.configs = const [], this.sections = const {}});

  ExploreSectionState section(String id) =>
      sections[id] ?? const ExploreSectionState(isLoading: true);

  ExploreFeedState copyWith({
    List<ExploreSectionConfig>? configs,
    Map<String, ExploreSectionState>? sections,
  }) {
    return ExploreFeedState(
      configs: configs ?? this.configs,
      sections: sections ?? this.sections,
    );
  }
}

class ExploreFeedNotifier extends Notifier<ExploreFeedState> {
  static const int _sectionSize = 8;
  int _requestId = 0;

  @override
  ExploreFeedState build() {
    unawaited(Future.microtask(refresh));
    return const ExploreFeedState();
  }

  Future<void> refresh() async {
    _requestId++;
    final id = _requestId;

    final List<ExploreSectionConfig> configs = [];

    // 1. Dành cho bạn (Recommendations)
    configs.add(
      const ExploreSectionConfig(
        id: 'forYou',
        title: 'Dành cho bạn',
        subtitle: 'Gợi ý từ StayHub',
        endpoint: '/v1/rooms/public/search',
        query: {'sortBy': 'newest'},
      ),
    );

    // 2. Nhà ở [Location]
    // WEB-SAFE: KHÔNG await Geocoding trước khi set state. Plugin `geocoding`
    // không có implementation trên web → lời gọi có thể treo vô hạn (không ném
    // lỗi), khiến `configs` không bao giờ được gán → màn "Tìm phòng" trắng trơn.
    // Vì vậy ta dựng config NGAY với tên mặc định, rồi cập nhật tên địa điểm
    // sau (best-effort) mà không chặn luồng render.
    final locState = ref.read(locationProvider);
    configs.add(
      ExploreSectionConfig(
        id: 'location',
        title: 'Nhà ở Gần Bạn',
        subtitle: 'Phù hợp với vị trí của bạn',
        endpoint: '/v1/rooms/public/search',
        query: {
          // Khi có vị trí → sắp xếp theo khoảng cách gần nhất; nếu không → mới nhất.
          'sortBy': locState.hasLocation ? 'distance' : 'newest',
          if (locState.hasLocation) 'lat': locState.latitude,
          if (locState.hasLocation) 'lng': locState.longitude,
        },
      ),
    );

    // 3. Các danh mục động — dùng MÃ canonical (id mô hình) khớp với
    // RoomTypeCodes ở cả frontend lẫn backend. KHÔNG dùng nhãn làm id.
    final categories = [
      {'id': 'PHONG_TRO', 'name': 'Phòng trọ'},
      {'id': 'CHUNG_CU', 'name': 'Chung cư'},
      {'id': 'NHA_NGUYEN_CAN', 'name': 'Nhà ở'},
      {'id': 'O_GHEP_KTX', 'name': 'Ở ghép / KTX'},
      {'id': 'KIOT', 'name': 'Mặt bằng'},
      {'id': 'OFFICE', 'name': 'Văn phòng'},
      {'id': 'KHO_BAI', 'name': 'Kho xưởng'},
      {'id': 'KHONG_GIAN_CD', 'name': 'Không gian'},
      {'id': 'LUU_TRU', 'name': 'Lưu trú'},
      {'id': 'DAT_CHO_THUE', 'name': 'Đất trống'},
    ];

    for (final c in categories) {
      configs.add(
        ExploreSectionConfig(
          id: 'category_${c['id']}',
          title: '${c['name']} mới nhất',
          subtitle: 'Cập nhật liên tục',
          endpoint: '/v1/rooms/public/search',
          query: {
            // Backend nhận List<String> roomTypes (tham số lặp), không phải roomType.
            'roomTypes': [c['id']],
            'sortBy': 'newest',
          },
        ),
      );
    }

    // 4. Lịch sử xem (best-effort, không chặn render).
    List<dynamic> history = const [];
    try {
      history = await ViewedHistoryService.getHistory();
    } catch (_) {
      history = const [];
    }
    if (history.isNotEmpty) {
      configs.add(
        ExploreSectionConfig(
          id: 'history',
          title: 'Lịch sử xem',
          subtitle: 'Bạn đã xem gần đây',
          preloadedItems: history,
        ),
      );
    }

    final initialSections = <String, ExploreSectionState>{};
    for (final config in configs) {
      if (config.preloadedItems != null) {
        initialSections[config.id] = ExploreSectionState(
          items: config.preloadedItems!,
          isLoading: false,
        );
      } else {
        initialSections[config.id] = const ExploreSectionState(isLoading: true);
      }
    }

    // Gán state NGAY để UI render được các section (đang loading) thay vì trắng.
    state = state.copyWith(configs: configs, sections: initialSections);

    // Tải song song tất cả section từ API.
    await Future.wait(
      configs
          .where((c) => c.preloadedItems == null)
          .map((c) => _fetchSection(c, id)),
    );

    // Cập nhật tên địa điểm (best-effort, sau khi đã render) — chỉ chạy khi có
    // vị trí và chỉ trên nền tảng hỗ trợ geocoding.
    if (locState.hasLocation) {
      unawaited(_updateLocationTitle(locState.latitude!, locState.longitude!));
    }
  }

  /// Cập nhật tiêu đề "Nhà ở <Tỉnh/Thành>" sau khi geocode xong (best-effort).
  /// Không bao giờ ném lỗi ra ngoài để tránh làm hỏng feed.
  Future<void> _updateLocationTitle(double lat, double lng) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return;
      final p = placemarks.first;
      var locationName = p.administrativeArea ?? p.locality ?? 'Gần Bạn';
      locationName = locationName
          .replaceAll('Thành phố ', '')
          .replaceAll('Tỉnh ', '');
      final idx = state.configs.indexWhere((c) => c.id == 'location');
      if (idx == -1) return;
      final updated = List<ExploreSectionConfig>.from(state.configs);
      updated[idx] = ExploreSectionConfig(
        id: 'location',
        title: 'Nhà ở $locationName',
        subtitle: 'Phù hợp với vị trí của bạn',
        endpoint: '/v1/rooms/public/search',
        query: updated[idx].query,
      );
      state = state.copyWith(configs: updated);
    } catch (_) {
      // Bỏ qua — giữ tiêu đề mặc định "Nhà ở Gần Bạn".
    }
  }

  Future<void> refreshSection(String configId) async {
    final config = state.configs.firstWhere((c) => c.id == configId);
    if (config.preloadedItems != null) return;

    final id = ++_requestId;
    _patch(
      configId,
      state.section(configId).copyWith(isLoading: true, error: null),
    );
    await _fetchSection(config, id);
  }

  Future<void> _fetchSection(ExploreSectionConfig config, int requestId) async {
    try {
      final dio = ref.read(dioProvider);
      // PERF3: fail-fast cho dữ liệu công khai — không retry để tránh treo
      // shimmer 60s+ khi backend không tới được.
      final response = await dio.get(
        config.endpoint!,
        queryParameters: {'page': 0, 'size': _sectionSize, ...?config.query},
        options: Options(extra: {'_failFast': true}),
      );

      if (requestId != _requestId) return;

      final items = _parseItems(response.data);

      _patch(config.id, ExploreSectionState(items: items, isLoading: false));
    } catch (e) {
      if (requestId != _requestId) return;
      _patch(
        config.id,
        ExploreSectionState(
          items: const [],
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  void _patch(String id, ExploreSectionState next) {
    state = state.copyWith(sections: {...state.sections, id: next});
  }

  List<dynamic> _parseItems(dynamic root) {
    final data = (root is Map && root.containsKey('data'))
        ? root['data']
        : root;

    List<dynamic> content = [];
    if (data is Map && data.containsKey('content')) {
      content = (data['content'] as List<dynamic>?) ?? [];
    } else if (data is List) {
      content = data;
    }

    return content.map((room) {
      if (room is Map) {
        final r = Map<String, dynamic>.from(room);
        if (r['ownerAvatar'] != null) {
          r['ownerAvatar'] = ImageUrlHelper.buildUrl(
            r['ownerAvatar'].toString(),
          );
        }
        return r;
      }
      return room;
    }).toList();
  }
}

final exploreFeedProvider =
    NotifierProvider<ExploreFeedNotifier, ExploreFeedState>(
      ExploreFeedNotifier.new,
    );
