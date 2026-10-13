import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/osm_map_service.dart';
import '../../../../core/services/address_mapping_service.dart';

// ─── Result returned from the fullscreen picker ──────────────────────────────
class MapPickResult {
  final LatLng latLng;
  final String? street;
  final String? houseNumber;
  final String? ward;
  final String? district;
  final String? province;

  const MapPickResult({
    required this.latLng,
    this.street,
    this.houseNumber,
    this.ward,
    this.district,
    this.province,
  });
}

// ─── Fullscreen Professional Map Picker ──────────────────────────────────────
class MapPickerDialog extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final String? fallbackAddressTitle;
  final String? fallbackAddressSubtitle;
  final String? formWardName;
  final String? formDistrictName;
  final String? formProvinceName;

  const MapPickerDialog({
    super.key,
    this.initialLat,
    this.initialLon,
    this.fallbackAddressTitle,
    this.fallbackAddressSubtitle,
    this.formWardName,
    this.formDistrictName,
    this.formProvinceName,
  });

  @override
  ConsumerState<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends ConsumerState<MapPickerDialog>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(21.028511, 105.804817);
  bool _isLoadingGPS = true;
  bool _isGeocoding = false;
  bool _hasMovedMap = false;
  Timer? _debounce;

  String? _previewStreet;
  String? _previewHouseNumber;
  String? _previewWard;
  String? _previewDistrict;
  String? _previewProvince;
  String _previewFull = '';

  late AnimationController _panelAnim;
  late Animation<Offset> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelAnim, curve: Curves.easeOutCubic));

    if (widget.initialLat != null && widget.initialLon != null) {
      _center = LatLng(widget.initialLat!, widget.initialLon!);
      _isLoadingGPS = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_panelAnim.forward());
        unawaited(_reverseGeocodeAt(_center));
      });
    } else {
      unawaited(_fetchGPS());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _panelAnim.dispose();
    super.dispose();
  }

  Future<void> _fetchGPS() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoadingGPS = false);

          unawaited(
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Thiếu quyền Vị trí'),
                content: const Text(
                  'Để lấy vị trí chính xác của bất động sản, vui lòng cấp quyền Vị trí cho StayHub trong Cài đặt máy.',
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: const Text('Đã hiểu'),
                  ),
                  if (perm == LocationPermission.deniedForever)
                    CupertinoDialogAction(
                      onPressed: () {
                        Navigator.pop(ctx);
                        unawaited(Geolocator.openAppSettings());
                      },
                      child: const Text(
                        'Mở Cài đặt',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
        unawaited(_panelAnim.forward());
        unawaited(_reverseGeocodeAt(_center));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _center = LatLng(pos.latitude, pos.longitude);
          _isLoadingGPS = false;
        });
        try {
          _mapController.move(_center, 16.5);
        } catch (_) {}
        unawaited(_panelAnim.forward());
        unawaited(_reverseGeocodeAt(_center));
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGPS = false);
      unawaited(_panelAnim.forward());
      unawaited(_reverseGeocodeAt(_center));
    }
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    if (!_hasMovedMap) {
      setState(() => _hasMovedMap = true);
    }
    _center = camera.center;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 550), () {
      unawaited(_reverseGeocodeAt(_center));
    });
  }

  Future<void> _reverseGeocodeAt(LatLng pos) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);
    try {
      final osmService = ref.read(osmMapServiceProvider);
      final addr = await osmService.reverseGeocode(
        pos.latitude,
        pos.longitude,
        provinceHint: widget.formProvinceName,
      );

      if (!mounted) return;
      if (addr != null) {
        setState(() {
          _previewStreet = (addr.street?.isEmpty ?? true) ? null : addr.street;
          _previewHouseNumber = (addr.houseNumber?.isEmpty ?? true)
              ? null
              : addr.houseNumber;
          _previewWard = (addr.ward?.isEmpty ?? true) ? null : addr.ward;
          _previewDistrict = (addr.district?.isEmpty ?? true)
              ? null
              : addr.district;
          _previewProvince = (addr.province?.isEmpty ?? true)
              ? null
              : addr.province;
          _previewFull = addr.displayAddress;
          _isGeocoding = false;
        });
      } else {
        setState(() => _isGeocoding = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(
      MapPickResult(
        latLng: _center,
        street: _previewStreet,
        houseNumber: _previewHouseNumber,
        ward: _previewWard,
        district: _previewDistrict,
        province: _previewProvince,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final safeTop = MediaQuery.of(context).padding.top;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Material(
            color: Colors.black,
            child: Stack(
              children: [
                // ── Map ────────────────────────────────────────────────────────
                if (!_isLoadingGPS)
                  Hero(
                    tag: 'map_hero',
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: 16.0,
                        maxZoom: 20.0,
                        minZoom: 8.0,
                        onPositionChanged: _onMapMoved,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                          userAgentPackageName: 'com.stayhub.app',
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoActivityIndicator(radius: 18),
                          SizedBox(height: 14),
                          Text(
                            'Đang lấy vị trí GPS...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Centre Crosshair Pin ────────────────────────────────────────
                if (!_isLoadingGPS)
                  Center(
                    child: Transform.translate(
                      offset: const Offset(0, -26),
                      child: AnimatedScale(
                        scale: _isGeocoding ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 52,
                              color: Color(0xFFFF3B30),
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            Container(
                              width: 8,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Top Bar ─────────────────────────────────────────────────────
                Positioned(
                  top: safeTop + 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.hand_draw,
                                size: 16,
                                color: Color(0xFF0EA5E9),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Kéo bản đồ đến đúng vị trí toà nhà',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              if (_isGeocoding) ...[
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0EA5E9),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom Address Panel ─────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _panelSlide,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(20, 18, 20, safeBottom + 18),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 24,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Address Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFECEC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 22,
                                  color: Color(0xFFFF3B30),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Check for conflict
                                    Builder(
                                      builder: (context) {
                                        bool isConflict = false;
                                        if (widget.formProvinceName != null &&
                                            _previewProvince != null) {
                                          final formP =
                                              AddressMappingService.normalizeString(
                                                widget.formProvinceName!,
                                              );
                                          final osmP =
                                              AddressMappingService.normalizeString(
                                                _previewProvince!,
                                              );
                                          if (formP.isNotEmpty &&
                                              osmP.isNotEmpty &&
                                              formP != osmP) {
                                            isConflict = true;
                                          }
                                        }
                                        if (widget.formDistrictName != null &&
                                            _previewDistrict != null &&
                                            !isConflict) {
                                          final formD =
                                              AddressMappingService.normalizeString(
                                                widget.formDistrictName!,
                                              );
                                          final osmD =
                                              AddressMappingService.normalizeString(
                                                _previewDistrict!,
                                              );
                                          if (formD.isNotEmpty &&
                                              osmD.isNotEmpty &&
                                              formD != osmD) {
                                            isConflict = true;
                                          }
                                        }
                                        if (widget.formWardName != null &&
                                            _previewWard != null &&
                                            !isConflict) {
                                          final formW =
                                              AddressMappingService.normalizeString(
                                                widget.formWardName!,
                                              );
                                          final osmW =
                                              AddressMappingService.normalizeString(
                                                _previewWard!,
                                              );
                                          if (formW.isNotEmpty &&
                                              osmW.isNotEmpty &&
                                              formW != osmW) {
                                            isConflict = true;
                                          }
                                        }

                                        String title = '';
                                        if (widget.fallbackAddressTitle !=
                                            null) {
                                          title = widget.fallbackAddressTitle!;
                                        } else {
                                          final titleParts = <String>[];
                                          if (_previewWard != null &&
                                              _previewWard!.isNotEmpty) {
                                            titleParts.add(_previewWard!);
                                          }
                                          if (_previewDistrict != null &&
                                              _previewDistrict!.isNotEmpty) {
                                            titleParts.add(_previewDistrict!);
                                          }
                                          if (_previewProvince != null &&
                                              _previewProvince!.isNotEmpty) {
                                            titleParts.add(_previewProvince!);
                                          }
                                          title = titleParts.isNotEmpty
                                              ? titleParts.join(', ')
                                              : (_previewStreet ?? '');
                                        }

                                        if (title.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                                color: isConflict
                                                    ? const Color(0xFFFF3B30)
                                                    : const Color(0xFF111827),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                          ],
                                        );
                                      },
                                    ),
                                    // Full address (small)
                                    Builder(
                                      builder: (context) {
                                        bool isConflict = false;
                                        if (widget.formProvinceName != null &&
                                            _previewProvince != null) {
                                          final formP =
                                              AddressMappingService.normalizeString(
                                                widget.formProvinceName!,
                                              );
                                          final osmP =
                                              AddressMappingService.normalizeString(
                                                _previewProvince!,
                                              );
                                          if (formP.isNotEmpty &&
                                              osmP.isNotEmpty &&
                                              formP != osmP) {
                                            isConflict = true;
                                          }
                                        }
                                        if (widget.formDistrictName != null &&
                                            _previewDistrict != null &&
                                            !isConflict) {
                                          final formD =
                                              AddressMappingService.normalizeString(
                                                widget.formDistrictName!,
                                              );
                                          final osmD =
                                              AddressMappingService.normalizeString(
                                                _previewDistrict!,
                                              );
                                          if (formD.isNotEmpty &&
                                              osmD.isNotEmpty &&
                                              formD != osmD) {
                                            isConflict = true;
                                          }
                                        }
                                        if (widget.formWardName != null &&
                                            _previewWard != null &&
                                            !isConflict) {
                                          final formW =
                                              AddressMappingService.normalizeString(
                                                widget.formWardName!,
                                              );
                                          final osmW =
                                              AddressMappingService.normalizeString(
                                                _previewWard!,
                                              );
                                          if (formW.isNotEmpty &&
                                              osmW.isNotEmpty &&
                                              formW != osmW) {
                                            isConflict = true;
                                          }
                                        }

                                        String subtitle = '';
                                        if (widget.fallbackAddressSubtitle !=
                                            null) {
                                          subtitle =
                                              widget.fallbackAddressSubtitle!;
                                        } else {
                                          subtitle = _previewFull;
                                        }

                                        if (subtitle.isNotEmpty) {
                                          return Text(
                                            subtitle,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: isConflict
                                                  ? const Color(
                                                      0xFFFF3B30,
                                                    ).withValues(alpha: 0.8)
                                                  : const Color(0xFF6B7280),
                                              height: 1.45,
                                            ),
                                          );
                                        } else if (_isGeocoding) {
                                          return const Text(
                                            'Đang tra cứu địa chỉ...',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          );
                                        } else {
                                          return const Text(
                                            'Di chuyển bản đồ để xem địa chỉ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 5),
                                    // Coordinates badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Text(
                                        '${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9CA3AF),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Confirm button
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              color: const Color(0xFF0EA5E9),
                              borderRadius: BorderRadius.circular(16),
                              onPressed: _confirm,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Xác nhận vị trí này',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
