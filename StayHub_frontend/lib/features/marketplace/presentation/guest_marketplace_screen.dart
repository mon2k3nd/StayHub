import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:shimmer/shimmer.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/components/app_error_widget.dart';
import '../../../core/constants/room_type_codes.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/osm_map_service.dart';
import '../../../core/services/recent_search_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/toast_utils.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/presentation/widgets/ekyc_verification_dialog.dart';
import '../../auth/presentation/widgets/guest_auth_bottom_sheet.dart';
import '../../chat/application/conversation_provider.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../marketplace/application/location_provider.dart';
import '../../marketplace/application/wishlist_provider.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../room/application/public_rooms_provider.dart';
import '../../room/application/public_rooms_filter_provider.dart';
import '../../tenant/presentation/business_landing_screen.dart';
import '../../tenant/presentation/rental_scan_landing_screen.dart';
import 'widgets/guest_feed_view.dart';
import 'widgets/map/guest_map_room_card.dart';
import 'widgets/marketplace_filter_sheet.dart';

part 'guest_marketplace_builders.dart';
part 'guest_marketplace_map.dart';
part 'guest_marketplace_filters.dart';
part 'guest_marketplace_nearby.dart';

class GuestMarketplaceScreen extends ConsumerStatefulWidget {
  final double bottomInset;

  /// Khi `true`, màn hình mở thẳng ở chế độ Bản đồ.
  /// Dùng cho route riêng `/marketplace-map` để tách tính năng tìm trọ trên map
  /// ra khỏi màn "lướt phòng".
  final bool initialMapView;

  /// Khi `false`, ẩn hàng header nổi phía trên (logo + action icons).
  /// Dùng khi màn này được nhúng bên trong `GuestHomeScreen` — lúc đó
  /// `GuestHomeScreen` đã sở hữu phần chrome (toggle Danh sách/Lướt) nên
  /// không được render trùng để tránh 2 header chồng lên nhau.
  final bool showTopHeader;

  /// Callback khi người dùng muốn thoát chế độ bản đồ.
  final VoidCallback? onExitMap;

  const GuestMarketplaceScreen({
    super.key,
    this.bottomInset = 0.0,
    this.initialMapView = false,
    this.showTopHeader = true,
    this.onExitMap,
  });

  @override
  ConsumerState<GuestMarketplaceScreen> createState() =>
      _GuestMarketplaceScreenState();
}
