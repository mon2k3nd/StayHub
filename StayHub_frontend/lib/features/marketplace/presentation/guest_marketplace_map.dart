// ================================================================
//  Guest Marketplace - Map View Extension
//  (split from guest_marketplace_builders.dart to keep files manageable)
//  Contains: geocoding, user location, map rendering, radius picker,
//            map search sheet, camera fit.
// ================================================================
part of 'guest_marketplace_screen.dart';

class _BuildingGroup {
  final LatLng position;
  final List<int> roomIndices = [];
  final List<dynamic> rooms = [];

  _BuildingGroup({required this.position});
}

class _MarkerArrowPainter extends CustomPainter {
  final Color color;
  final Color? borderColor;

  _MarkerArrowPainter({required this.color, this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Overlap by 1.2px at top to seamlessly connect with pill bottom border
    final path = Path()
      ..moveTo(0, -1.2)
      ..lineTo(size.width, -1.2)
      ..lineTo(size.width / 2, size.height)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    if (borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      final borderPath = Path()
        ..moveTo(0, -1.2)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, -1.2);
      canvas.drawPath(borderPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkerArrowPainter oldDelegate) =>
      color != oldDelegate.color || borderColor != oldDelegate.borderColor;
}

mixin _GuestMarketplaceMapMixin on _GuestMarketplaceStateMixin {
  // ── Geocoding ──────────────────────────────────────────────────────────────
  Future<void> _geocodeAddress(String address) async {
    if (_pendingGeocode.contains(address)) return;
    _pendingGeocode.add(address);
    try {
      final res = await Dio().get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': 1,
          'countrycodes': 'vn',
        },
        options: Options(headers: {'User-Agent': 'StayHubApp/1.0'}),
      );
      if (res.data is List && (res.data as List).isNotEmpty) {
        final data = (res.data as List).first;
        // BUGFIX (data): tránh NoSuchMethodError khi phần tử không phải Map
        // (ví dụ String) — `data['lat']` sẽ ném lỗi.
        if (data is! Map) return;
        final lat = double.tryParse(data['lat'].toString());
        final lon = double.tryParse(data['lon'].toString());
        if (lat != null && lon != null && mounted) {
          setState(() {
            _geocodedAddresses[address] = LatLng(lat, lon);
          });
        }
      }
    } catch (_) {
      // Bỏ qua lỗi mạng — sẽ thử lại ở lần build kế tiếp.
    } finally {
      // LUÔN giải phóng khoá đang chờ. Trước đây chỉ thêm mà không xoá nên khi
      // geocode thất bại (mất mạng / không tìm thấy), địa chỉ đó bị kẹt vĩnh
      // viễn trong _pendingGeocode → không bao giờ thử lại được.
      _pendingGeocode.remove(address);
    }
  }

  // ── User location ──────────────────────────────────────────────────────────
  Future<void> _getUserLocation({bool isUserInitiated = false}) async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (isUserInitiated) throw Exception('Dịch vụ định vị đang bị tắt.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!isUserInitiated) return;
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (isUserInitiated && mounted) {
          unawaited(
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Quyền bị chặn vĩnh viễn'),
                content: const Text(
                  'Vui lòng vào Cài đặt → Quyền → Vị trí và bật quyền cho StayHub.',
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Để sau'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('Mở Cài đặt'),
                    onPressed: () {
                      unawaited(Geolocator.openAppSettings());
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        }
        if (isUserInitiated) {
          throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
        }
        return;
      }

      Position? position;
      try {
        final service = ref.read(locationServiceProvider);
        position = await service.getAccuratePosition().timeout(
          const Duration(seconds: 4),
        );
      } catch (e) {
        debugPrint('getAccuratePosition error: $e');
        try {
          position = await Geolocator.getLastKnownPosition().timeout(
            const Duration(seconds: 3),
          );
        } catch (_) {}
      }

      if (position == null) {
        if (isUserInitiated && mounted) {
          ToastUtils.show(
            context,
            'Không thể lấy vị trí hiện tại.',
            isError: true,
          );
        }
        return;
      }
      final newCenter = LatLng(position.latitude, position.longitude);

      setState(() {
        _mapCenter = newCenter;
      });
      if (_isMapView) _mapController.move(newCenter, 14.0);

      // Reverse geocode để lấy địa chỉ thực tế
      try {
        final osmService = OsmMapService();
        final addr = await osmService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
        if (addr != null && addr.displayAddress.isNotEmpty && mounted) {
          setState(() => _userAddress = addr.displayAddress);
        }
      } catch (_) {
        // Không quan trọng nếu reverse geocode thất bại
      }
    } catch (e) {
      if (isUserInitiated && mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Reload map rooms & bounds ───────────────────────────────────────────────
  Future<void> _handleMapReload() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isReloading = true);
    try {
      ref.invalidate(publicRoomsProvider);
      ref.invalidate(sortedPublicRoomsProvider);
      _mapController.fitCamera(_getMapFit());
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) {
        setState(() => _isReloading = false);
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() => _isLocating = true);
    try {
      final osmService = OsmMapService();
      final latLng = await osmService.geocode(trimmed);
      if (!mounted) return;
      if (latLng != null) {
        setState(() {
          _mapCenter = latLng;
          // Lưu lại địa chỉ đã tìm để nhãn trên bản đồ khớp với vị trí mới
          // (trước đây không cập nhật → nhãn cũ vẫn hiển thị sai địa điểm).
          _mapSearchAddress = trimmed;
        });
        // Fit theo bán kính đang chọn để vòng tròn + kết quả vừa khung nhìn,
        // thay vì zoom cứng 14.0 (có thể cắt mất kết quả khi bán kính lớn).
        _mapController.fitCamera(_getMapFit());
      } else {
        _showErrorDialog('Không tìm thấy địa chỉ này');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Lỗi khi tìm kiếm địa chỉ');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thông báo'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // ── Camera fit ─────────────────────────────────────────────────────────────
  CameraFit _getMapFit() {
    // Bán kính hợp lệ: chặn NaN/Infinity/âm để tránh bounds vô cực làm sập map.
    final double rawRadius = _mapSearchRadius;
    final double radiusInKm = (rawRadius.isFinite && rawRadius > 0)
        ? rawRadius
        : 2.0;
    final double latDelta = radiusInKm / 111.32;

    // Gần cực (|lat| → 90°) thì cos(lat) → 0 khiến lngDelta → vô cực và
    // LatLngBounds ném lỗi. Kẹp cos về tối thiểu để bounds luôn hợp lệ.
    final double cosLat = cos(_mapCenter.latitude * pi / 180);
    final double safeCosLat = cosLat.abs() < 0.01 ? 0.01 : cosLat.abs();
    final double lngDelta = radiusInKm / (111.32 * safeCosLat);

    // Kẹp vĩ độ về [-90, 90] để LatLng không ném assertion.
    final double minLat = (_mapCenter.latitude - latDelta).clamp(-90.0, 90.0);
    final double maxLat = (_mapCenter.latitude + latDelta).clamp(-90.0, 90.0);

    final bounds = LatLngBounds(
      LatLng(minLat, _mapCenter.longitude - lngDelta),
      LatLng(maxLat, _mapCenter.longitude + lngDelta),
    );

    return CameraFit.bounds(
      bounds: bounds,
      padding: EdgeInsets.only(
        top: widget.showTopHeader ? 80 : 220,
        bottom: 180,
        left: 30,
        right: 30,
      ),
    );
  }

  // ── Radius picker ──────────────────────────────────────────────────────────
  void _showRadiusPicker() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext ctx) => CupertinoActionSheet(
          title: const Text(
            'Chọn bán kính tìm kiếm',
            style: TextStyle(fontFamily: AppTheme.kFontFamily, fontSize: 14),
          ),
          // Danh sách bán kính PHẢI khớp với picker inline ở dưới
          // ([1,2,3,5,10,15,20]) — trước đây thiếu 15km nên người dùng chọn
          // 15km ở picker inline sẽ không thấy mục nào được đánh dấu ở đây.
          actions: [1, 2, 3, 5, 10, 15, 20]
              .map(
                (km) => CupertinoActionSheetAction(
                  child: Text(
                    '$km km',
                    style: const TextStyle(
                      fontFamily: AppTheme.kFontFamily,
                      color: AppTheme.kAccentColor,
                    ),
                  ),
                  onPressed: () {
                    setState(() => _mapSearchRadius = km.toDouble());
                    _mapController.fitCamera(_getMapFit());
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(fontFamily: AppTheme.kFontFamily),
            ),
          ),
        ),
      ),
    );
  }

  // ── Map rendering ──────────────────────────────────────────────────────────
  Widget _buildMap(List<dynamic> rooms, NumberFormat currencyFmt) {
    // ── Gom nhóm các phòng theo Toà nhà / Chi nhánh / Toạ độ thực tế ──
    final buildingMap = <String, _BuildingGroup>{};
    final roomIndexToPosition = <int, LatLng>{};

    for (int i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      double? lat = room['latitude'] is num
          ? (room['latitude'] as num).toDouble()
          : double.tryParse(room['latitude']?.toString() ?? '');
      double? lng = room['longitude'] is num
          ? (room['longitude'] as num).toDouble()
          : double.tryParse(room['longitude']?.toString() ?? '');

      if (lat == null || lng == null) {
        final address = room['address']?.toString() ?? '';
        if (address.isNotEmpty && _geocodedAddresses.containsKey(address)) {
          final c = _geocodedAddresses[address]!;
          lat = c.latitude;
          lng = c.longitude;
        } else if (address.isNotEmpty) {
          unawaited(_geocodeAddress(address));
        }
      }

      if (lat == null || lng == null) {
        continue;
      }

      final resolvedLat = lat;
      final resolvedLng = lng;
      final branchId = room['branchId']?.toString();
      final key = (branchId != null && branchId.isNotEmpty)
          ? 'branch_$branchId'
          : '${resolvedLat.toStringAsFixed(5)}_${resolvedLng.toStringAsFixed(5)}';

      final group = buildingMap.putIfAbsent(
        key,
        () => _BuildingGroup(position: LatLng(resolvedLat, resolvedLng)),
      );
      group.roomIndices.add(i);
      group.rooms.add(room);
      roomIndexToPosition[i] = LatLng(resolvedLat, resolvedLng);
    }

    final sortedBuildings = buildingMap.values.toList()
      ..sort((a, b) {
        final aSelected = a.roomIndices.contains(_currentCarouselIndex);
        final bSelected = b.roomIndices.contains(_currentCarouselIndex);
        if (aSelected && !bSelected) return 1;
        if (!aSelected && bSelected) return -1;
        return 0;
      });

    final markers = sortedBuildings.map((building) {
      double minPrice = double.infinity;
      for (final r in building.rooms) {
        final p = extractPrice(r['price']);
        if (p > 0 && p < minPrice) minPrice = p;
      }
      if (minPrice == double.infinity) minPrice = 0.0;
      final minPriceTr = (minPrice / 1000000)
          .toStringAsFixed(1)
          .replaceAll('.0', '');
      final hasMultiple = building.rooms.length > 1;
      final isSelected = building.roomIndices.contains(_currentCarouselIndex);

      final displayText = hasMultiple
          ? 'Từ ${minPriceTr}tr'
          : '${minPriceTr}tr';
      final tp = TextPainter(
        text: TextSpan(
          text: displayText,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: isSelected ? 13.0 : 11.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final markerWidth = (tp.width + (isSelected ? 26.0 : 20.0))
          .ceilToDouble();
      final markerHeight = isSelected ? 40.0 : 32.0;

      return Marker(
        point: building.position,
        width: markerWidth,
        height: markerHeight,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            final target = building.roomIndices.first;
            unawaited(
              _mapCarouselController.animateToPage(
                target,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            );
          },
          child: SizedBox(
            width: markerWidth,
            height: markerHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      height: isSelected ? 32.0 : 25.0,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 10.0 : 7.0,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.kBrand : Colors.white,
                        borderRadius: BorderRadius.circular(
                          isSelected ? 16 : 12.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppTheme.kBrand.withValues(alpha: 0.50)
                                : Colors.black.withValues(alpha: 0.12),
                            blurRadius: isSelected ? 14 : 5,
                            offset: Offset(0, isSelected ? 4 : 2),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppTheme.kBorderColor,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        displayText,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.kTextPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          fontSize: isSelected ? 12.5 : 11.0,
                        ),
                      ),
                    ),
                    if (hasMultiple)
                      Positioned(
                        top: isSelected ? -6 : -5,
                        right: isSelected ? -6 : -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppTheme.kBrand,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.kBrand
                                  : Colors.white,
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '${building.rooms.length}',
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.kBrand
                                  : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: isSelected ? 10.5 : 9.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                CustomPaint(
                  size: Size(isSelected ? 11 : 9, isSelected ? 6 : 5),
                  painter: _MarkerArrowPainter(
                    color: isSelected ? AppTheme.kBrand : Colors.white,
                    borderColor: isSelected ? null : AppTheme.kBorderColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final double carouselBottom =
        (widget.bottomInset > 0 ? widget.bottomInset : 10) + bottomSafe;
    const double carouselHeight = 145;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: _getMapFit(),
            minZoom: 5.0,
            maxZoom: 18.5,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                final lat = camera.center.latitude;
                final lng = camera.center.longitude;
                if (lat < 8.15 || lat > 23.45 || lng < 102.10 || lng > 117.50) {
                  final clampedLat = lat.clamp(8.15, 23.45);
                  final clampedLng = lng.clamp(102.10, 117.50);
                  _mapController.move(
                    LatLng(clampedLat, clampedLng),
                    camera.zoom,
                  );
                }
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: OsmMapService.tileUrl,
              subdomains: OsmMapService.tileSubdomains,
              userAgentPackageName: 'com.stayhub.guest',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _mapCenter,
                  radius: _mapSearchRadius * 1000,
                  useRadiusInMeter: true,
                  color: AppTheme.kBrand.withValues(alpha: 0.08),
                  borderColor: AppTheme.kBrand.withValues(alpha: 0.55),
                  borderStrokeWidth: 1.8,
                ),
              ],
            ),
            MarkerLayer(markers: markers),
            MarkerLayer(
              markers: [
                Marker(
                  point: _mapCenter,
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.kBrand,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kBrand.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Lớp chạm nền để đóng menu chọn cự ly khi người dùng bấm ra ngoài ──
        if (_showDistancePicker)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showDistancePicker = false),
              behavior: HitTestBehavior.translucent,
            ),
          ),

        // ── Nút Thoát Bản Đồ (nằm bên trái, ngang hàng với Pill Capsule bên phải) ──
        if (widget.onExitMap != null)
          Positioned(
            left: 14,
            bottom: carouselBottom + carouselHeight + 12,
            child: GestureDetector(
              onTap: widget.onExitMap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.kBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.list_bullet,
                      size: 18,
                      color: AppTheme.kTextPrimary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Danh sách',
                      style: TextStyle(
                        fontFamily: AppTheme.kFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Cụm điều khiển tối giản bên cạnh phải (Pill Capsule tích hợp: Cự ly, Reload, GPS) ──
        Positioned(
          right: 14,
          bottom: carouselBottom + carouselHeight + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Menu cự ly tối giản xổ lên ngay trên dock
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  );
                },
                child: _showDistancePicker
                    ? Container(
                        key: const ValueKey('distance_flyout'),
                        width: 48,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.98),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.kBorderColor,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.kBrand.withValues(alpha: 0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [1, 2, 3, 5, 10, 15, 20].map((km) {
                            final isSelected =
                                _mapSearchRadius == km.toDouble();
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 1.5,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  unawaited(HapticFeedback.selectionClick());
                                  setState(() {
                                    _mapSearchRadius = km.toDouble();
                                    _showDistancePicker = false;
                                  });
                                  _mapController.fitCamera(_getMapFit());
                                },
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 40,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.kBrand
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Text(
                                    '${km}km',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.kTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_flyout')),
              ),

              // 2. Dock điều khiển dạng con nhộng tối giản (Unified Capsule)
              Container(
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.kBorderColor, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nút Cự ly (Top)
                    GestureDetector(
                      onTap: () {
                        unawaited(HapticFeedback.lightImpact());
                        setState(
                          () => _showDistancePicker = !_showDistancePicker,
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _showDistancePicker
                              ? AppTheme.kBrand
                              : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(23),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${_mapSearchRadius.toInt()}km',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _showDistancePicker
                                  ? Colors.white
                                  : AppTheme.kBrand,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Đường phân cách mỏng
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: AppTheme.kBorderColor.withValues(alpha: 0.6),
                    ),

                    // Nút Reload (Bottom)
                    GestureDetector(
                      onTap: _isReloading ? null : _handleMapReload,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 48,
                        height: 38,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(23),
                          ),
                        ),
                        child: Center(
                          child: _isReloading
                              ? const CupertinoActivityIndicator(radius: 7)
                              : const Icon(
                                  CupertinoIcons.arrow_clockwise,
                                  color: AppTheme.kTextMuted,
                                  size: 17,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Map Carousel
        Positioned(
          bottom: carouselBottom,
          left: 0,
          right: 0,
          height: carouselHeight,
          child: PageView.builder(
            controller: _mapCarouselController,
            itemCount: rooms.length + 1,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentCarouselIndex = index);
              if (index < rooms.length) {
                final target = roomIndexToPosition[index];
                if (target != null) {
                  final camera = _mapController.camera;
                  // Không zoom cận vào phòng, giữ nguyên mức zoom hiện tại của người dùng.
                  // Chỉ nhẹ nhàng dịch camera nếu phòng nằm ngoài màn hình hiển thị:
                  if (!camera.visibleBounds.contains(target)) {
                    _mapController.move(target, camera.zoom);
                  }
                }
              }
            },
            itemBuilder: (context, index) {
              if (index == rooms.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: GestureDetector(
                    onTap: _showRadiusPicker,
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppTheme.kAccentColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.kAccentColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.search_circle_fill,
                              color: AppTheme.kAccentColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rooms.isEmpty
                                ? 'Chưa có phòng phù hợp'
                                : 'Khám phá thêm',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            rooms.isEmpty
                                ? 'Thử mở rộng bán kính tìm kiếm'
                                : 'Mở rộng bán kính tìm kiếm',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final room = rooms[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: GuestMapRoomCard(
                    room: room,
                    currencyFmt: currencyFmt,
                    isMapCard: true,
                    mapCenter: _mapCenter,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Map search sheet ───────────────────────────────────────────────────────
  Widget _buildMapSearchSheet(BuildContext ctx) {
    // Dùng lại controller đã được quản lý & dispose ở State thay vì tạo mới
    // mỗi lần build (trước đây tạo TextEditingController cục bộ → RÒ RỈ BỘ NHỚ
    // vì không bao giờ được dispose).
    final addressController = _mapSearchController;
    // BUGFIX: KHÔNG gán `addressController.text` mỗi lần build. Trước đây dòng
    // `addressController.text = _mapSearchAddress ?? '';` chạy lại mỗi khi
    // `setSheetState` (gõ phím / chọn gợi ý) → đặt con trỏ về vị trí 0 và
    // "giật" chữ đang gõ. Chỉ seed MỘT LẦN khi mở sheet và controller còn rỗng.
    if (addressController.text.isEmpty) {
      final seed = _mapSearchAddress ?? '';
      if (seed.isNotEmpty) {
        addressController.text = seed;
        addressController.selection = TextSelection.collapsed(
          offset: addressController.text.length,
        );
      }
    }
    List<Map<String, dynamic>> suggestions = [];
    String? selectedDisplayName;
    LatLng? selectedLatLng;

    bool isSearching = false;

    final osmService = OsmMapService();

    void fetchSuggestions(String query, StateSetter setSheetState) {
      if (query.trim().length < 2) {
        setSheetState(() {
          suggestions = [];
          isSearching = false;
        });
        return;
      }

      setSheetState(() => isSearching = true);
      osmService.getSuggestionsDebounced(query, (results) {
        if (!mounted) return;
        setSheetState(() {
          suggestions = results
              .map(
                (s) => {
                  'shortName': s.shortName,
                  'displayName': s.displayName,
                  'lat': s.latLng.latitude,
                  'lon': s.latLng.longitude,
                },
              )
              .toList();
          isSearching = false;
        });
      });
    }

    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        String buildLabel(Map<String, dynamic> s) {
          // BUGFIX (data): trước đây ép `as String?` — nếu shortName/displayName
          // là số/object (JSON lỗi) thì ném TypeError. Dùng toString an toàn.
          final short = s['shortName']?.toString() ?? '';
          if (short.isNotEmpty) return short;
          return s['displayName']?.toString() ?? '';
        }

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.kBackgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.kBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.kBrandDeep.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.map_fill,
                        color: AppTheme.kBrandDeep,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tìm phòng trên bản đồ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📍 Địa chỉ tìm kiếm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: addressController,
                      autofocus: true,
                      placeholder: 'Nhập tên đường, phường, quận, thành phố...',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(
                          CupertinoIcons.search,
                          color: AppTheme.kTextMuted,
                          size: 18,
                        ),
                      ),
                      suffix: addressController.text.isNotEmpty
                          ? CupertinoButton(
                              padding: const EdgeInsets.only(right: 8),
                              onPressed: () {
                                addressController.clear();
                                setSheetState(() {
                                  suggestions = [];
                                  selectedLatLng = null;
                                  selectedDisplayName = null;
                                });
                              },
                              child: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                size: 18,
                                color: AppTheme.kTextMuted,
                              ),
                            )
                          : null,
                      decoration: BoxDecoration(
                        color: AppTheme.kSurface2Light,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedLatLng != null
                              ? AppTheme.kBrandDeep
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      onChanged: (val) {
                        setSheetState(() => selectedLatLng = null);
                        fetchSuggestions(val, setSheetState);
                      },
                    ),
                  ],
                ),
              ),

              // ── Danh sách gợi ý ──
              if (isSearching)
                const Expanded(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (suggestions.isNotEmpty && selectedLatLng == null)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: suggestions.length,
                    itemBuilder: (_, i) {
                      final s = suggestions[i];
                      final label = buildLabel(s);
                      final displayName = s['displayName'] as String? ?? '';
                      final displayParts = displayName.split(', ');
                      final city = displayParts.length > 2
                          ? displayParts.last
                          : '';

                      return GestureDetector(
                        onTap: () {
                          final lat = s['lat'] is num
                              ? (s['lat'] as num).toDouble()
                              : double.tryParse(s['lat'].toString());
                          final lon = s['lon'] is num
                              ? (s['lon'] as num).toDouble()
                              : double.tryParse(s['lon'].toString());
                          if (lat != null && lon != null) {
                            addressController.text = label;
                            setSheetState(() {
                              selectedLatLng = LatLng(lat, lon);
                              selectedDisplayName = label;
                              suggestions = [];
                            });
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.kBorderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppTheme.kBrandDeep.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  CupertinoIcons.location_solid,
                                  color: AppTheme.kBrandDeep,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.kTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (city.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        city,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.arrow_up_left,
                                color: AppTheme.kTextMuted,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedLatLng != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.kSurfaceBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.kBorderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  color: AppTheme.kBrandDeep,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedDisplayName ?? '',
                                    style: const TextStyle(
                                      color: AppTheme.kBrandDeep,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

              // ── Nút xác nhận ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(ctx).padding.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppTheme.kBrandDeep,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: isSearching
                        ? null
                        : () async {
                            final addr =
                                selectedDisplayName ??
                                addressController.text.trim();
                            setSheetState(() => isSearching = true);
                            // Đóng sheet TRƯỚC khi chạy tác vụ nặng (định vị /
                            // geocode) để tránh setState lên sheet đã bị huỷ.
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (addr.isEmpty) {
                              // Không nhập gì → thực sự đưa bản đồ về vị trí
                              // hiện tại của người dùng (trước đây chỉ đổi nhãn
                              // chữ mà KHÔNG di chuyển bản đồ → sai vị trí).
                              setState(() {
                                _mapSearchAddress = 'Vị trí hiện tại';
                                _isMapView = true;
                              });
                              await _getUserLocation(isUserInitiated: true);
                            } else if (selectedLatLng != null) {
                              setState(() {
                                _mapCenter = selectedLatLng!;
                                _mapSearchAddress = addr;
                                _isMapView = true;
                              });
                              _mapController.fitCamera(_getMapFit());
                            } else {
                              await _searchAddress(addr);
                              if (mounted) {
                                setState(() {
                                  _mapSearchAddress = addr;
                                  _isMapView = true;
                                });
                              }
                            }
                          },
                    child: isSearching
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.map_fill,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tìm kiếm vị trí này',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
