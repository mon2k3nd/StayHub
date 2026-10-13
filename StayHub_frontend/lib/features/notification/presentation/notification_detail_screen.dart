import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../data/notification_model.dart';
import '../data/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../bill/data/models/bill_model.dart';
import '../../checkout/presentation/dispute_chat_screen.dart';
import '../../branch/presentation/branch_detailed_config_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async' show unawaited;

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  bool _isLoading = false;
  bool _isFetchingPayload = false;
  Map<String, dynamic>? _fetchedPayload;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchCheckoutPayloadIfNeeded());
  }

  /// Coerces an arbitrary decoded value into a `Map<String, dynamic>?`.
  /// Returns null when the value is not a map, so callers can safely fall back.
  static Map<String, dynamic>? _asPayloadMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<void> _fetchCheckoutPayloadIfNeeded() async {
    final notif = widget.notification;
    if (notif.type == 'CHECKOUT_REQUESTED' && notif.refId != null) {
      try {
        // actionMetadata is untrusted: decode defensively and only treat it as
        // a map when it actually is one, otherwise fall back to an empty map.
        Map<String, dynamic> meta = const {};
        final rawMeta = notif.actionMetadata;
        if (rawMeta is String && rawMeta.isNotEmpty) {
          final decoded = json.decode(rawMeta);
          if (decoded is Map) meta = Map<String, dynamic>.from(decoded);
        }
        if (meta['payload'] == null) {
          if (!mounted) return;
          setState(() => _isFetchingPayload = true);
          final dio = ref.read(dioProvider);
          final res = await dio.get('/v1/checkouts/${notif.refId}/details');
          if (res.statusCode == 200 && mounted) {
            final data = res.data is Map ? res.data['data'] : null;
            final fetched = _asPayloadMap(data);
            if (fetched != null) {
              setState(() {
                _fetchedPayload = fetched;
              });
            }
          }
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isFetchingPayload = false);
      }
    }
  }

  Future<void> _handleAction(String status) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // actionMetadata is an untrusted JSON string: it may be null, malformed,
      // or hold non-String/non-Map values. Decode defensively and coerce every
      // field to the exact type executeAction expects.
      Map<String, dynamic> meta = const {};
      final rawMeta = widget.notification.actionMetadata;
      if (rawMeta is String && rawMeta.isNotEmpty) {
        final decoded = json.decode(rawMeta);
        if (decoded is Map) {
          meta = Map<String, dynamic>.from(decoded);
        }
      }

      final endpointRaw = meta['endpoint'];
      final endpoint = endpointRaw is String && endpointRaw.isNotEmpty
          ? endpointRaw
          : null;
      final methodRaw = meta['method'];
      final method = methodRaw is String && methodRaw.isNotEmpty
          ? methodRaw
          : 'POST';
      final payloadRaw = meta['payload'];
      final payload = payloadRaw is Map
          ? Map<String, dynamic>.from(payloadRaw)
          : (status == 'APPROVED' ? {'approved': true} : {'approved': false});

      if (endpoint != null) {
        final success = await ref
            .read(notificationActionProvider)
            .executeAction(
              widget.notification.id,
              endpoint,
              method,
              payload,
              status,
            );

        if (!mounted) return;
        if (success) {
          ref.invalidate(notificationsProvider);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xử lý thất bại. Vui lòng thử lại!')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi xử lý dữ liệu!')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final isPending = notif.isActionable && notif.actionStatus == 'PENDING';
    final hasResponded =
        notif.isActionable &&
        notif.actionStatus != null &&
        notif.actionStatus != 'PENDING';

    Map<String, dynamic> metadata = {};
    String? roomContext;
    String? userInfo;

    try {
      if (notif.actionMetadata != null) {
        final decoded = json.decode(notif.actionMetadata!);
        if (decoded is Map) {
          metadata = Map<String, dynamic>.from(decoded);
        }
        final payload = _asPayloadMap(metadata['payload']) ?? _fetchedPayload;
        if (payload != null) {
          if (payload['roomName'] != null) {
            String rName = payload['roomName'].toString();
            if (payload['branchName'] != null &&
                payload['branchName'].toString().isNotEmpty) {
              rName += ' - ${payload['branchName']}';
            }
            // Ensure we don't duplicate 'Phòng'
            if (rName.toLowerCase().startsWith('phòng')) {
              roomContext = rName;
            } else {
              roomContext = 'Phòng $rName';
            }
          } else if (payload['roomId'] != null) {
            roomContext = 'Mã Phòng: ${payload['roomId']}';
          }
          if (payload['customerName'] != null) {
            userInfo = '${payload['customerName']}';
            if (payload['phoneNumber'] != null &&
                payload['phoneNumber'].toString().isNotEmpty) {
              userInfo += ' - ${payload['phoneNumber']}';
            }
          }
        }
      } else if (_fetchedPayload != null) {
        final payload = _fetchedPayload!;
        if (payload['roomName'] != null) {
          String rName = payload['roomName'].toString();
          if (payload['branchName'] != null &&
              payload['branchName'].toString().isNotEmpty) {
            rName += ' - ${payload['branchName']}';
          }
          if (rName.toLowerCase().startsWith('phòng')) {
            roomContext = rName;
          } else {
            roomContext = 'Phòng $rName';
          }
        } else if (payload['roomId'] != null) {
          roomContext = 'Mã Phòng: ${payload['roomId']}';
        }
        if (payload['customerName'] != null) {
          userInfo = '${payload['customerName']}';
          if (payload['phoneNumber'] != null &&
              payload['phoneNumber'].toString().isNotEmpty) {
            userInfo += ' - ${payload['phoneNumber']}';
          }
        }
      }
    } catch (_) {}

    roomContext ??= 'Chưa có thông tin phòng';
    userInfo ??= notif.senderId == null
        ? 'Hệ thống StayHub'
        : 'Khách hàng #${notif.senderId}';

    // Single, type-safe payload map used by every detailed block below.
    // Prefers the inline metadata payload, falling back to the fetched one.
    final Map<String, dynamic>? payloadMap =
        _asPayloadMap(metadata['payload']) ?? _fetchedPayload;

    String screenTitle = 'Chi tiết thông báo';
    if (notif.type == 'CHECKOUT_REQUESTED') {
      screenTitle = 'Yêu cầu trả phòng';
    } else if (notif.type == 'MAINTENANCE_ASSIGNED') {
      screenTitle = 'Yêu cầu sửa chữa';
    } else if (notif.type == 'ROOM_RESERVED' ||
        notif.type == 'RENTAL_REQUESTED') {
      screenTitle = 'Yêu cầu thuê phòng';
    }

    String mainTitle = roomContext == 'Chưa có thông tin phòng'
        ? notif.title
        : roomContext;
    if ((notif.type == 'CHECKOUT_REQUESTED' ||
            notif.type == 'MAINTENANCE_ASSIGNED' ||
            notif.type == 'ROOM_RESERVED' ||
            notif.type == 'RENTAL_REQUESTED') &&
        mainTitle == notif.title) {
      final match = RegExp(r'Phòng [^\s]+').firstMatch(notif.content);
      if (match != null) {
        mainTitle = match.group(0)!;
      } else {
        mainTitle = 'Phòng không xác định';
      }
    }

    return GlassScaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F2FE),
              Color(0xFFF3E8FF),
              AppTheme.kBackgroundLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.6],
          ),
        ),
      ),
      appBar: GlassAppBar(
        title: Text(screenTitle),
        leading: Navigator.canPop(context)
            ? GlassButton(
                icon: const Icon(CupertinoIcons.back),
                onTap: () => Navigator.pop(context),
              )
            : null,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              await ref.read(notificationsProvider.future);
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).top + 64),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Khối nhận diện & Ngữ cảnh (Header Card)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(
                                        notif.type,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getTypeIcon(notif.type),
                                        color: _getTypeColor(notif.type),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mainTitle,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1A1A1A),
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              CupertinoIcons.time,
                                              size: 14,
                                              color: Color(0xFF8C8C8C),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDate(notif.createdAt),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF8C8C8C),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              CupertinoIcons.person_solid,
                                              size: 14,
                                              color: Color(0xFF8C8C8C),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                userInfo,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF8C8C8C),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Khối nội dung & Dữ liệu chi tiết
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'THÔNG TIN CHI TIẾT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8C8C8C),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _isFetchingPayload
                                ? const [
                                    Center(child: CircularProgressIndicator()),
                                  ]
                                : (notif.type == 'CHECKOUT_REQUESTED' &&
                                      payloadMap != null)
                                ? _buildCheckoutDetailedBlock(
                                    payloadMap,
                                    notif.content,
                                    userInfo,
                                  )
                                : (notif.type == 'MAINTENANCE_ASSIGNED' &&
                                      payloadMap != null)
                                ? _buildMaintenanceDetailedBlock(
                                    notif,
                                    payloadMap,
                                    notif.content,
                                  )
                                : (notif.type == 'ROOM_RESERVED' ||
                                          notif.type == 'RENTAL_REQUESTED') &&
                                      payloadMap != null
                                ? _buildRentalRequestDetailedBlock(
                                    notif,
                                    payloadMap,
                                    notif.content,
                                  )
                                : [
                                    const Text(
                                      'Nội dung diễn giải',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notif.content,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    if (payloadMap != null) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        height: 1,
                                        color: const Color(0xFFF3F4F6),
                                      ),
                                      const SizedBox(height: 16),
                                      ..._buildMetadataRows(payloadMap),
                                    ],
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom > 0
                  ? MediaQuery.paddingOf(context).bottom
                  : 20,
              top: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AppTheme.kBackgroundLight.withValues(alpha: 0.75),
              border: const Border(
                top: BorderSide(color: Colors.white, width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (notif.type == 'CHECKOUT_REQUESTED' ||
                    notif.type == 'ROOM_RESERVED' ||
                    notif.type == 'RENTAL_REQUESTED')
                  _buildNavAction(notif)
                else if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(24),
                          onPressed: _isLoading
                              ? null
                              : () => _handleAction('REJECTED'),
                          child: const Text(
                            'Từ Chối',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.activeBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            onPressed: _isLoading
                                ? null
                                : () => _handleAction('APPROVED'),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Phê Duyệt',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (hasResponded)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: notif.actionStatus == 'APPROVED'
                          ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                          : CupertinoColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notif.actionStatus == 'APPROVED'
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemRed,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          notif.actionStatus == 'APPROVED'
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.clear_circled_solid,
                          color: notif.actionStatus == 'APPROVED'
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notif.actionStatus == 'APPROVED'
                              ? 'Đã Phê Duyệt'
                              : 'Đã Từ Chối',
                          style: TextStyle(
                            color: notif.actionStatus == 'APPROVED'
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildNavAction(notif),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavAction(NotificationModel notif) {
    if (notif.type == 'CHECKOUT_REQUESTED') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.activeOrange,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.activeOrange.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          onPressed: () {
            unawaited(context.push('/owner/checkout-list'));
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.doc_text,
                color: CupertinoColors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Quản lý Trả Phòng',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── BRANCH_CREATED: Dẫn đến màn cấu hình chi tiết ──
    if (notif.type == 'BRANCH_CREATED') {
      try {
        final decoded = notif.actionMetadata != null
            ? json.decode(notif.actionMetadata!)
            : null;
        final meta = decoded is Map ? decoded : const {};
        final branchId = meta['branchId'];
        final branchName = meta['branchName'] ?? 'Chi nhánh';
        // Resolve the numeric id up-front so a malformed value can never crash
        // the tap handler (which runs outside this try/catch).
        final int? branchIdInt = branchId is int
            ? branchId
            : int.tryParse(branchId?.toString() ?? '');
        if (branchIdInt != null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF298FFF), Color(0xFF1A6FD4)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF298FFF).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                unawaited(
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => BranchDetailedConfigScreen(
                        branchId: branchIdInt,
                        branchName: branchName.toString(),
                      ),
                    ),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.settings_solid,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cấu hình chi tiết phòng ngay',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (_) {}
    }

    // ── BRANCH_CONFIG_COMPLETED: Gợi ý đăng bài cho thuê ──
    if (notif.type == 'BRANCH_CONFIG_COMPLETED') {
      try {
        final decoded = notif.actionMetadata != null
            ? json.decode(notif.actionMetadata!)
            : null;
        final meta = decoded is Map ? decoded : const {};
        final branchId = meta['branchId'];
        if (branchId != null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                unawaited(context.push('/create-post'));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.square_pencil,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đăng bài cho thuê ngay',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (_) {}
    }

    if (notif.type == 'SYSTEM_ALERT') {
      try {
        if (notif.actionMetadata != null) {
          final decoded = json.decode(notif.actionMetadata!);
          if (decoded is Map) {
            final rawUrl = decoded['actionUrl'];
            final actionUrl = rawUrl is String && rawUrl.isNotEmpty
                ? rawUrl
                : null;
            if (actionUrl != null) {
              final rawLabel = decoded['actionLabel'];
              final actionLabel = rawLabel is String && rawLabel.isNotEmpty
                  ? rawLabel
                  : 'Đi tới';
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF298FFF),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF298FFF).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () {
                    if (!mounted) return;
                    unawaited(context.push(actionUrl));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.arrow_right_circle_fill,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        actionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    if (notif.type == 'ROOM_RESERVED') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: const Color(
                  0xFFFEF2F2,
                ).withValues(alpha: 0.8), // Glassmorphism red
                borderRadius: BorderRadius.circular(24),
                onPressed: _isLoading ? null : () => _handleAction('REJECTED'),
                child: const Text(
                  'Từ Chối',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                    fontSize: 16,
                  ),
                ), // Tăng độ tương phản (darker red)
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF298FFF), // Sky Blue
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF298FFF).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  onPressed: _isLoading
                      ? null
                      : () => _handleAction('APPROVED'),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Phê Duyệt / Tạo HĐ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (notif.title.toLowerCase().contains('được duyệt') &&
        notif.refId != null) {
      return Container(
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          onPressed: () {
            unawaited(
              context.push(
                '/digital-signature',
                extra: {'contractId': notif.refId},
              ),
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.signature,
                color: CupertinoColors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Ký hợp đồng ngay',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      if (notif.actionMetadata != null) {
        final decoded = json.decode(notif.actionMetadata!);
        final meta = decoded is Map ? decoded : const {};
        if (meta['event'] == 'BILL_DISPUTED' && notif.refId != null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.activeOrange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.activeOrange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  final res = await dio.get('/v1/bills/${notif.refId}');
                  if (res.statusCode == 200) {
                    final bill = BillModel.fromJson(res.data['data']);
                    if (!mounted) return;
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DisputeChatScreen(
                            initialBill: bill,
                            isOwner: true,
                          ),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi tải hóa đơn')),
                  );
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Vào Thương Lượng Ngay',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (_) {}

    // Nút điều hướng mặc định (Secondary)
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(16),
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.back, color: Color(0xFF4B5563), size: 20),
          SizedBox(width: 8),
          Text(
            'Quay lại danh sách',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetadataRows(dynamic payload) {
    final map = _asPayloadMap(payload);
    if (map == null) return [];

    return map.entries.map((e) {
      if (e.key == 'approved' ||
          e.key == 'roomName' ||
          e.key == 'customerName' ||
          e.key == 'phoneNumber') {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                _translateKey(e.key),
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                e.value.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildMaintenanceDetailedBlock(
    NotificationModel notif,
    Map<String, dynamic> payload,
    String content,
  ) {
    return [
      _buildSectionHeader('1. Thông tin Khách thuê & Liên hệ'),
      const SizedBox(height: 12),
      _buildRow(
        'Họ và tên',
        payload['customerName']?.toString() ?? 'Khách hàng',
        isBold: true,
      ),
      _buildRow(
        'Số điện thoại',
        payload['phoneNumber']?.toString() ?? 'N/A',
        icon: CupertinoIcons.phone_fill,
        onTap: () async {
          final phone = payload['phoneNumber']?.toString() ?? '';
          if (phone.isNotEmpty) {
            final uri = Uri.parse('tel:$phone');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          }
        },
      ),
      _buildRow('Căn hộ / Phòng', payload['roomName']?.toString() ?? 'N/A'),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Color(0xFFF3F4F6), height: 1),
      ),

      _buildSectionHeader('2. Thông tin Sự cố / Sửa chữa'),
      const SizedBox(height: 12),
      _buildRow(
        'Loại sự cố',
        payload['issueType']?.toString() ?? 'Sự cố Khác',
        isBold: true,
      ),
      _buildRow(
        'Mức độ ưu tiên',
        (payload['priority']?.toString() == 'HIGH' ||
                payload['priority']?.toString() == 'KHẨN CẤP')
            ? '🔴 Khẩn cấp'
            : (payload['priority']?.toString() ?? 'Bình thường'),
        color:
            (payload['priority']?.toString() == 'HIGH' ||
                payload['priority']?.toString() == 'KHẨN CẤP')
            ? CupertinoColors.systemRed
            : null,
      ),
      if (payload['imageCount'] != null &&
          payload['imageCount'].toString() != '0')
        _buildRow(
          'Hình ảnh đính kèm',
          '${payload['imageCount']} ảnh ➔',
          color: CupertinoColors.activeBlue,
          onTap: () {
            // Logic xem ảnh (nếu cần thiết sau này)
          },
        ),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Color(0xFFF3F4F6), height: 1),
      ),

      _buildSectionHeader('3. Nội dung diễn giải / Lời nhắn'),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          (payload['description']?.toString() ?? '').isNotEmpty
              ? payload['description']!.toString()
              : content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4B5563),
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRentalRequestDetailedBlock(
    NotificationModel notif,
    Map<String, dynamic> payload,
    String content,
  ) {
    return [
      _buildSectionHeader('1. Thông tin Khách đăng ký thuê'),
      const SizedBox(height: 12),
      _buildRow(
        'Họ và tên',
        payload['customerName']?.toString() ?? 'Khách hàng',
        isBold: true,
      ),
      _buildRow(
        'Số điện thoại',
        payload['phoneNumber']?.toString() ?? 'N/A',
        icon: CupertinoIcons.phone_fill,
        onTap: () async {
          final phone = payload['phoneNumber']?.toString() ?? '';
          if (phone.isNotEmpty) {
            final uri = Uri.parse('tel:$phone');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          }
        },
      ),
      _buildRow(
        'Căn hộ / Phòng đăng ký',
        payload['roomName']?.toString() ?? 'N/A',
      ),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Color(0xFFF3F4F6), height: 1),
      ),

      _buildSectionHeader('2. Thông tin Dự kiến Thuê (Đặc thù Thuê mới)'),
      const SizedBox(height: 12),
      _buildRow(
        'Ngày bắt đầu ở dự kiến',
        _formatDateOnly(payload['startDate']?.toString() ?? ''),
      ),
      _buildRow(
        'Thời hạn hợp đồng',
        payload['duration']?.toString().isNotEmpty == true
            ? payload['duration'].toString()
            : 'Thỏa thuận',
      ),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Color(0xFFF3F4F6), height: 1),
      ),

      _buildSectionHeader('3. Thông tin Tài chính & Ghi chú'),
      const SizedBox(height: 12),
      _buildRow(
        'Giá thuê thỏa thuận',
        '${_formatCurrency(payload['price']?.toString() ?? '0')} / tháng',
      ),
      _buildRow(
        'Tiền đặt cọc dự kiến',
        _formatCurrency(payload['deposit']?.toString() ?? '0'),
      ),
      if ((payload['note']?.toString() ?? '').isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            payload['note']!.toString(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildCheckoutDetailedBlock(
    dynamic payload,
    String content,
    String? userInfo,
  ) {
    final map = _asPayloadMap(payload);
    if (map == null) return [];

    return [
      _buildSectionHeader('1. Thông tin Khách thuê & Liên hệ'),
      const SizedBox(height: 12),
      _buildRow(
        'Họ và tên',
        map['customerName']?.toString() ?? userInfo ?? 'Khách hàng',
        isBold: true,
      ),
      _buildRow(
        'Số điện thoại',
        map['phoneNumber']?.toString() ?? 'N/A',
        icon: CupertinoIcons.phone_fill,
        onTap: () async {
          final phone = map['phoneNumber']?.toString() ?? '';
          if (phone.isNotEmpty) {
            final uri = Uri.parse('tel:$phone');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          }
        },
      ),
      _buildRow('Căn hộ / Phòng', map['roomName']?.toString() ?? 'N/A'),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Color(0xFFF3F4F6), height: 1),
      ),

      _buildSectionHeader('2. Thông tin Hợp đồng & Cọc'),
      const SizedBox(height: 12),
      _buildRow(
        'Mã hợp đồng',
        map['contractCode']?.toString() ?? 'N/A',
        isBold: true,
      ),
      _buildRow(
        'Bắt đầu thuê',
        _formatDateOnly(map['startDate']?.toString() ?? ''),
      ),
      _buildRow(
        'Hạn hợp đồng',
        _formatDateOnly(map['endDate']?.toString() ?? ''),
      ),
      _buildRow(
        'Tiền đặt cọc',
        _formatCurrency(map['deposit']?.toString() ?? '0'),
      ),
      if (map['outstandingBalance'] != null)
        Builder(
          builder: (_) {
            // The balance may arrive as a comma/dot-formatted string
            // ("1,000,000" / "1.000.000") — strip separators before parsing so
            // a non-zero debt is never mis-reported as fully paid.
            final rawBalance = map['outstandingBalance'].toString();
            final normalized = rawBalance.replaceAll(RegExp(r'[^0-9.-]'), '');
            final balance = double.tryParse(normalized) ?? 0;
            return _buildRow(
              'Công nợ hiện tại',
              balance == 0
                  ? '0 VNĐ (Đã thanh toán hết)'
                  : '${_formatCurrency(normalized)} (Còn nợ)',
              color: balance == 0
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemRed,
            );
          },
        ),
      if (map['equipmentCount'] != null)
        _buildRow(
          'Tài sản bàn giao',
          '${map['equipmentCount']} thiết bị ➔',
          color: CupertinoColors.activeBlue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng xem chi tiết tài sản đang phát triển'),
              ),
            );
          },
        ),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Color(0xFFF3F4F6), height: 1),
      ),

      _buildSectionHeader('3. Thông tin Yêu cầu trả phòng'),
      const SizedBox(height: 12),
      _buildRow(
        'Ngày dự kiến trả',
        _formatDateOnly(map['targetDate']?.toString() ?? ''),
        isBold: true,
        color: CupertinoColors.systemRed,
        hasEarlyTag: _isEarlyCheckout(
          map['targetDate']?.toString(),
          map['endDate']?.toString(),
        ),
      ),
      _buildRow(
        'Ghi chú / Lời nhắn',
        (map['note']?.toString() ?? '').isNotEmpty
            ? map['note']?.toString()
            : content,
      ),
    ];
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String? value, {
    bool isBold = false,
    Color? color,
    IconData? icon,
    VoidCallback? onTap,
    bool hasEarlyTag = false,
  }) {
    final contentWidget = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasEarlyTag)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Trả trước hạn',
              style: TextStyle(
                fontSize: 10,
                color: CupertinoColors.systemRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (icon != null) ...[
          Icon(icon, size: 14, color: CupertinoColors.activeBlue),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            value ?? 'N/A',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
              color: color ?? const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: onTap != null
                ? GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: contentWidget,
                  )
                : contentWidget,
          ),
        ],
      ),
    );
  }

  String _formatDateOnly(String dateString) {
    if (dateString.isEmpty || dateString == 'N/A') return 'N/A';
    try {
      final dt = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(String amountString) {
    // Accept both raw numbers ("1000000") and pre-formatted strings
    // ("1,000,000" / "1.000.000") by stripping every non-numeric separator
    // before parsing, so the output is always consistently grouped.
    final normalized = amountString.replaceAll(RegExp(r'[^0-9.-]'), '');
    final amount = double.tryParse(normalized);
    if (amount == null) return '$amountString VNĐ';
    return '${NumberFormat('#,###').format(amount)} VNĐ';
  }

  String _translateKey(String key) {
    switch (key) {
      case 'roomId':
        return 'Mã Phòng';
      case 'userId':
        return 'Mã Khách Hàng';
      case 'amount':
        return 'Số Tiền';
      case 'date':
        return 'Ngày';
      case 'time':
        return 'Giờ';
      case 'type':
        return 'Loại';
      case 'status':
        return 'Trạng Thái';
      default:
        return key;
    }
  }

  String _formatDate(String dateString) {
    try {
      final dt = DateTime.parse(dateString);
      return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
    } catch (e) {
      return dateString;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'INFO':
        return CupertinoColors.activeBlue;
      case 'WARNING':
        return CupertinoColors.systemYellow;
      case 'ERROR':
        return CupertinoColors.systemRed;
      case 'SUCCESS':
        return CupertinoColors.systemGreen;
      case 'ACTION_REQUIRED':
        return const Color(0xFF298FFF); // Dùng Sky Blue cho action
      case 'SYSTEM_ALERT':
        return CupertinoColors.systemRed;
      case 'ROOM_RESERVED':
      case 'CONTRACT_SIGNED':
        return CupertinoColors.systemGreen;
      case 'CHECKOUT_REQUESTED':
      case 'TICKET_CREATED':
      case 'TICKET_UPDATED':
      case 'MAINTENANCE_ASSIGNED':
      case 'MAINTENANCE_RESOLVED':
        return CupertinoColors.systemOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'INFO':
        return CupertinoIcons.info_circle_fill;
      case 'WARNING':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'ERROR':
        return CupertinoIcons.xmark_octagon_fill;
      case 'SUCCESS':
        return CupertinoIcons.check_mark_circled_solid;
      case 'ACTION_REQUIRED':
        return CupertinoIcons.flame_fill;
      case 'SYSTEM_ALERT':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'ROOM_RESERVED':
        return CupertinoIcons.house_fill;
      case 'CONTRACT_SIGNED':
        return CupertinoIcons.doc_text_fill;
      case 'CHECKOUT_REQUESTED':
        return CupertinoIcons.square_arrow_right_fill;
      case 'TICKET_CREATED':
      case 'TICKET_UPDATED':
      case 'MAINTENANCE_ASSIGNED':
      case 'MAINTENANCE_RESOLVED':
        return CupertinoIcons.wrench_fill;
      default:
        return CupertinoIcons.bell_fill;
    }
  }

  bool _isEarlyCheckout(String? targetStr, String? endStr) {
    if (targetStr == null ||
        targetStr.isEmpty ||
        endStr == null ||
        endStr.isEmpty) {
      return false;
    }
    try {
      final targetDate = DateTime.parse(targetStr);
      final endDate = DateTime.parse(endStr);
      return targetDate.isBefore(endDate.subtract(const Duration(days: 1)));
    } catch (_) {
      return false;
    }
  }
}
