import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../contract/data/models/contract_model.dart';
import '../data/models/checkout_request_model.dart';
import '../application/owner_checkout_notifier.dart';
import '../application/checkout_provider.dart';
import 'create_checkout_bill_screen.dart';
import 'package:flutter/cupertino.dart';
import '../../room/presentation/room_inventory_screen.dart';
import 'dart:async' show unawaited;

class OwnerCheckoutDetailScreen extends ConsumerStatefulWidget {
  final CheckoutRequestModel request;
  final ContractModel contract;

  const OwnerCheckoutDetailScreen({
    super.key,
    required this.request,
    required this.contract,
  });

  @override
  ConsumerState<OwnerCheckoutDetailScreen> createState() =>
      _OwnerCheckoutDetailScreenState();
}

class _OwnerCheckoutDetailScreenState
    extends ConsumerState<OwnerCheckoutDetailScreen> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Map<int, bool> _assetDamaged = {};
  final Map<int, TextEditingController> _damageDescControllers = {};
  final Map<int, TextEditingController> _penaltyControllers = {};

  @override
  void initState() {
    super.initState();
  }

  double _computeTotalDamageFee() {
    double total = 0;
    _assetDamaged.forEach((index, isDamaged) {
      if (isDamaged) {
        total += double.tryParse(_penaltyControllers[index]?.text ?? '0') ?? 0;
      }
    });
    return total;
  }

  String _computeDamageReason() {
    final parts = <String>[];
    _assetDamaged.forEach((index, isDamaged) {
      if (isDamaged) {
        final desc = _damageDescControllers[index]?.text.trim() ?? '';
        if (desc.isNotEmpty) parts.add(desc);
      }
    });
    return parts.join('; ');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    for (var c in _damageDescControllers.values) {
      c.dispose();
    }
    for (var c in _penaltyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showRejectDialog() {
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Từ chối Yêu cầu',
            style: TextStyle(color: Colors.red),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vui lòng nhập lý do từ chối để khách thuê biết đường chụp lại/bổ sung (Bắt buộc):',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do từ chối',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Không được để trống lý do từ chối.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final reason = _reasonController.text;
                  Navigator.pop(ctx);
                  final success = await ref
                      .read(ownerCheckoutProvider.notifier)
                      .rejectRequest(widget.request.id, reason);
                  if (success && mounted) {
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text(
                          'Thành công',
                          style: TextStyle(color: Colors.green),
                        ),
                        content: const Text('Đã từ chối yêu cầu!'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                    if (mounted) context.pop();
                  }
                }
              },
              child: const Text(
                'Từ chối',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseImages(String? jsonString) {
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [jsonString];
    } catch (e) {
      return [jsonString];
    }
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    final url = path.startsWith('http') ? path : '${ApiClient.baseUrl}$path';
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerCheckoutProvider);
    final beforeImages = _parseImages(widget.contract.contractImages);
    final afterImages = _parseImages(widget.request.checkoutImages);
    final assetsAsync = ref.watch(roomAssetListProvider(widget.request.roomId));
    final assets = assetsAsync.value ?? [];

    ref.listen(ownerCheckoutProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        unawaited(
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Lỗi', style: TextStyle(color: Colors.red)),
              content: Text(next.error!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      }
    });

    final asyncData = ref.watch(checkoutTrackingProvider(widget.request.id));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: const Text(
          'Thẩm Định Trả Phòng',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.activeBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : asyncData.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Center(child: Text('Lỗi: $err')),
                data: (summary) {
                  return CustomScrollView(
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: () async {
                          ref.invalidate(
                            checkoutTrackingProvider(widget.request.id),
                          );
                          await ref.read(
                            checkoutTrackingProvider(widget.request.id).future,
                          );
                        },
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildTimelineCard(context, widget.request.status),
                            const SizedBox(height: 16),
                            _buildCustomerInfoCard(summary),
                            const SizedBox(height: 16),
                            _buildOverviewCard(summary),
                            const SizedBox(height: 16),
                            _buildStayStatisticsCard(summary),
                            const SizedBox(height: 24),

                            const Text(
                              'ĐỐI SOÁT TÀI SẢN (BEFORE/AFTER)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8C8C8C),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Side by Side View
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: afterImages.length,
                              itemBuilder: (context, index) {
                                final before = beforeImages.length > index
                                    ? beforeImages[index]
                                    : '';
                                final after = afterImages[index];
                                final assetName = assets.length > index
                                    ? assets[index].assetName
                                    : 'Tài sản ${index + 1}';

                                _damageDescControllers.putIfAbsent(
                                  index,
                                  () => TextEditingController(),
                                );
                                _penaltyControllers.putIfAbsent(
                                  index,
                                  () => TextEditingController(),
                                );
                                final isDamaged = _assetDamaged[index] ?? false;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Lúc nhận phòng',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      _buildImage(before),
                                                      Positioned(
                                                        bottom: 0,
                                                        left: 0,
                                                        right: 0,
                                                        child: Container(
                                                          color: Colors.black54,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 4,
                                                              ),
                                                          child: Text(
                                                            assetName,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
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
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Hiện tại',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          AppTheme.kAccentColor,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      _buildImage(after),
                                                      Positioned(
                                                        bottom: 0,
                                                        left: 0,
                                                        right: 0,
                                                        child: Container(
                                                          color: AppTheme
                                                              .kAccentColor
                                                              .withValues(
                                                                alpha: 0.85,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 4,
                                                              ),
                                                          child: Text(
                                                            assetName,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
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
                                        ],
                                      ),
                                      if (widget.request.status ==
                                          'PENDING') ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: isDamaged,
                                              activeColor: Colors.red,
                                              onChanged: (val) {
                                                setState(
                                                  () => _assetDamaged[index] =
                                                      val ?? false,
                                                );
                                              },
                                            ),
                                            const Expanded(
                                              child: Text(
                                                'Tài sản bị hư hại? (Có tính phí phạt)',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isDamaged)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 40,
                                              right: 0,
                                              top: 4,
                                            ),
                                            child: Column(
                                              children: [
                                                CupertinoTextField(
                                                  controller:
                                                      _damageDescControllers[index],
                                                  placeholder:
                                                      'Mô tả hư hại (VD: móp méo, nứt...)',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                CupertinoTextField(
                                                  controller:
                                                      _penaltyControllers[index],
                                                  placeholder: 'Giá phạt (VNĐ)',
                                                  keyboardType:
                                                      TextInputType.number,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            if (widget.request.status == 'PENDING') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _showRejectDialog,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      child: const Text(
                                        'Từ chối',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        unawaited(
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CreateCheckoutBillScreen(
                                                    request: widget.request,
                                                    contract: widget.contract,
                                                    initialDamageFee:
                                                        _computeTotalDamageFee(),
                                                    initialDamageReason:
                                                        _computeDamageReason(),
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        backgroundColor: AppTheme.kAccentColor,
                                      ),
                                      child: const Text(
                                        'Duyệt & Tính Tiền',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (widget.request.status ==
                                    'PENDING_PAYMENT' ||
                                widget.request.status == 'COMPLETED') ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    unawaited(context.push('/bill'));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: AppTheme.kAccentColor,
                                  ),
                                  child: const Text(
                                    'Quản lý Hóa đơn',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // --- Helper Methods ---
  Widget _buildTimelineCard(BuildContext context, String status) {
    int currentStep = 0;
    if (status == 'PENDING') currentStep = 1;
    if (status == 'APPROVED' || status == 'REJECTED') currentStep = 2;
    if (status == 'PAYMENT_PENDING') currentStep = 3;
    if (status == 'COMPLETED') currentStep = 4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRẠNG THÁI YÊU CẦU',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stepWidth = constraints.maxWidth / 4;
              final totalLineWidth = constraints.maxWidth - stepWidth;
              final progress = (currentStep - 1) / 3.0;
              final activeWidth = totalLineWidth * progress;

              return Stack(
                children: [
                  Positioned(
                    top: 15,
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Container(height: 2, color: const Color(0xFFE5E7EB)),
                  ),
                  Positioned(
                    top: 15,
                    left: stepWidth / 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOutQuart,
                      height: 2,
                      width: activeWidth,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimelineStep(
                        1,
                        'Gửi\nyêu cầu',
                        isActive: currentStep >= 1,
                        isCurrent: currentStep == 1,
                      ),
                      _buildTimelineStep(
                        2,
                        'Thẩm\nđịnh',
                        isActive: currentStep >= 2,
                        isCurrent: currentStep == 2,
                      ),
                      _buildTimelineStep(
                        3,
                        'Thanh\ntoán',
                        isActive: currentStep >= 3,
                        isCurrent: currentStep == 3,
                      ),
                      _buildTimelineStep(
                        4,
                        'Hoàn\ntất',
                        isActive: currentStep >= 4,
                        isCurrent: currentStep == 4,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          if (status == 'REJECTED') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã từ chối yêu cầu này. Đang chờ khách tạo yêu cầu mới.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'PAYMENT_PENDING') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.time_solid,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đang chờ khách thanh toán hóa đơn quyết toán.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    int step,
    String label, {
    required bool isActive,
    required bool isCurrent,
  }) {
    Color color = isActive
        ? CupertinoColors.activeBlue
        : const Color(0xFFE5E7EB);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: isActive && !isCurrent
                    ? Icon(Icons.check, size: 16, color: color)
                    : Text(
                        '$step',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              color: isCurrent ? color : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(Map<String, dynamic> summary) {
    final tenant = summary['tenant'];
    final name = tenant != null ? tenant['fullName']?.toString() : 'Khách hàng';
    final phone = tenant != null
        ? tenant['phone']?.toString()
        : 'Chưa cập nhật';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'THÔNG TIN KHÁCH THUÊ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8C8C8C),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.phone_fill,
                      size: 16,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.chat_bubble_fill,
                      size: 16,
                      color: CupertinoColors.activeGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.kAccentColor.withValues(alpha: 0.2),
                child: Text(
                  name != null && name.isNotEmpty ? name[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    color: AppTheme.kAccentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone ?? '',
                      style: const TextStyle(
                        color: AppTheme.kTextMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> summary) {
    final room = summary['room'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN CHUNG',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            'Căn hộ / Phòng',
            room != null
                ? room['roomName']?.toString()
                : 'Phòng ${widget.contract.roomId}',
            icon: CupertinoIcons.house_fill,
          ),
          _buildRow(
            'Ngày bắt đầu thuê',
            DateFormat('dd/MM/yyyy').format(widget.contract.startDate),
          ),
          _buildRow(
            'Ngày dự kiến trả',
            DateFormat('dd/MM/yyyy').format(widget.request.targetCheckoutDate),
            isBold: true,
            color: CupertinoColors.systemRed,
          ),
          if (widget.request.tenantNote.isNotEmpty) ...[
            _buildRow(
              'Lý do trả phòng',
              widget.request.tenantNote,
              isBold: false,
            ),
          ],
          _buildRow('Mã hợp đồng', 'HD-${widget.contract.id}'),
          _buildRow(
            'Tiền đặt cọc',
            '${NumberFormat('#,###').format(widget.contract.depositAmount)} VNĐ',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStayStatisticsCard(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THỐNG KÊ QUÁ TRÌNH Ở',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Thời gian đã ở',
            '${summary['stayDurationDays'] ?? 0} ngày',
            CupertinoIcons.calendar_today,
            CupertinoColors.activeBlue,
          ),
          const Divider(color: Color(0xFFF3F4F6), height: 24),
          _buildStatRow(
            'Sự cố khách báo',
            '${summary['incidentCount'] ?? 0} lần',
            CupertinoIcons.wrench_fill,
            CupertinoColors.systemOrange,
          ),
          const Divider(color: Color(0xFFF3F4F6), height: 24),
          _buildStatRow(
            'Thanh toán trọ',
            '${summary['paidBills'] ?? 0}/${summary['totalBills'] ?? 0} hóa đơn',
            CupertinoIcons.money_dollar_circle_fill,
            CupertinoColors.systemGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String? value, {
    bool isBold = false,
    Color? color,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: CupertinoColors.activeBlue),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    value ?? '',
                    style: TextStyle(
                      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                      color: color ?? const Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
