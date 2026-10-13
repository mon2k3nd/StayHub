import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/components/safe_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/premium_empty_state_widget.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import '../../../core/services/pdf_export_service.dart';
import '../../../core/providers/feature_flag_provider.dart';
import '../application/bill_notifier.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/models/bill_model.dart';
import '../../../core/components/audit_logs_sheet.dart';
import '../../../core/components/shimmer_loading.dart';
import '../../../core/utils/biometric_utils.dart';
import '../../../core/utils/toast_utils.dart';
import 'split_bill_screen.dart';
import '../../../core/components/responsive_file_image.dart';
import 'dart:async' show unawaited;

final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class BillScreen extends ConsumerStatefulWidget {
  const BillScreen({super.key});

  @override
  ConsumerState<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends ConsumerState<BillScreen> {
  int _selectedSegment = 0;
  String _searchQuery = '';
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;

  Future<void> _exportCsv(List<BillModel> bills) async {
    try {
      if (bills.isEmpty) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thông báo'),
              content: const Text('Không có dữ liệu để xuất CSV.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
        return;
      }

      final buffer = StringBuffer();
      buffer.write('\uFEFF');
      buffer.writeln(
        'Phòng,Tháng,Tiền phòng,Tiền điện,Tiền nước,Tiền dịch vụ,Tổng cộng,Trạng thái',
      );

      for (final b in bills) {
        final room = 'Phòng ${b.roomId}';
        final month = b.periodLabel;
        final rent = b.rentAmount ?? 0;
        final elec = b.electricAmount ?? 0;
        final water = b.waterAmount ?? 0;
        final service = b.serviceAmount ?? 0;
        final total = b.totalAmount ?? 0;
        final status = b.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán';

        buffer.writeln(
          '$room,$month,$rent,$elec,$water,$service,$total,$status',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/Hoa_Don_${_filterMonth}_$_filterYear.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString());

      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: Text('Đã xuất file CSV tại:\n$path'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Mở file'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(OpenFile.open(path));
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi xuất file'),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _showDetailSheet(BillModel bill) {
    // Parse serviceDetails JSON array -> List<Map>
    List<Map<String, dynamic>> poolBreakdown = [];
    if (bill.serviceDetails != null && bill.serviceDetails!.isNotEmpty) {
      try {
        final decoded = jsonDecode(bill.serviceDetails!);
        if (decoded is List) {
          poolBreakdown = decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map) {
          // Fallback cho hóa đơn cũ lưu kiểu Map
          // BUGFIX (data): trước đây ép `(e.value as num)` — nếu giá trị là
          // String/null thì ném TypeError và cả màn hình hoá đơn không render.
          poolBreakdown = decoded.entries
              .map(
                (e) => {
                  'poolName': e.key,
                  'myShare': e.value is num
                      ? (e.value as num).toDouble()
                      : double.tryParse(e.value?.toString() ?? '') ?? 0.0,
                },
              )
              .toList();
        }
      } catch (e) {
        debugPrint('Error parsing serviceDetails for bill: $e');
      }
    }
    // Private service amount (exclude pool amounts)
    final privateService =
        (bill.serviceAmount ?? 0) - (bill.sharedPoolAmount ?? 0);

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(
            'Chi Tiết Hóa Đơn ${bill.periodLabel}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          message: Column(
            children: [
              const SizedBox(height: 8),
              // 1. Tiền phòng
              _buildDetailPopupRow(
                '🏠 Tiền thuê nhà',
                bill.rentAmount != null
                    ? _currencyFmt.format(bill.rentAmount)
                    : '0đ',
              ),
              // 2. Điện riêng phòng
              if (bill.electricCurrent != null) ...[
                const Divider(color: CupertinoColors.separator, height: 12),
                _buildDetailPopupRow(
                  '⚡ Chỉ số điện đầu kỳ',
                  '${bill.electricPrevious?.toStringAsFixed(1) ?? 0} kWh',
                ),
                _buildDetailPopupRow(
                  '⚡ Chỉ số điện cuối kỳ',
                  '${bill.electricCurrent!.toStringAsFixed(1)} kWh',
                ),
                _buildDetailPopupRow(
                  '   Tiêu thụ điện',
                  '${(bill.electricCurrent! - (bill.electricPrevious ?? 0)).toStringAsFixed(1)} kWh',
                ),
                if (bill.electricImage != null &&
                    bill.electricImage!.isNotEmpty)
                  _buildImagePopupRow('Ảnh chốt điện', bill.electricImage!),
                _buildDetailPopupRow(
                  '   Đơn giá điện',
                  bill.electricUnitPrice != null
                      ? '${_currencyFmt.format(bill.electricUnitPrice)}/kWh'
                      : '0đ',
                ),
                _buildDetailPopupRow(
                  '   Thành tiền điện',
                  bill.electricAmount != null
                      ? _currencyFmt.format(bill.electricAmount)
                      : '0đ',
                ),
              ],
              // 3. Nước riêng phòng
              if (bill.waterCurrent != null) ...[
                const Divider(color: CupertinoColors.separator, height: 12),
                _buildDetailPopupRow(
                  '💧 Chỉ số nước đầu kỳ',
                  '${bill.waterPrevious?.toStringAsFixed(1) ?? 0} m³',
                ),
                _buildDetailPopupRow(
                  '💧 Chỉ số nước cuối kỳ',
                  '${bill.waterCurrent!.toStringAsFixed(1)} m³',
                ),
                _buildDetailPopupRow(
                  '   Tiêu thụ nước',
                  '${(bill.waterCurrent! - (bill.waterPrevious ?? 0)).toStringAsFixed(1)} m³',
                ),
                if (bill.waterImage != null && bill.waterImage!.isNotEmpty)
                  _buildImagePopupRow('Ảnh chốt nước', bill.waterImage!),
                _buildDetailPopupRow(
                  '   Đơn giá nước',
                  bill.waterUnitPrice != null
                      ? '${_currencyFmt.format(bill.waterUnitPrice)}/m³'
                      : '0đ',
                ),
                _buildDetailPopupRow(
                  '   Thành tiền nước',
                  bill.waterAmount != null
                      ? _currencyFmt.format(bill.waterAmount)
                      : '0đ',
                ),
              ],
              // 4. Dịch vụ Pool CHUNG (ServicePool breakdown)
              if (poolBreakdown.isNotEmpty) ...[
                const Divider(color: CupertinoColors.separator, height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.building_2_fill,
                        size: 13,
                        color: Color(0xFF6366F1),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PHÍ DỊCH VỤ DÙNG CHUNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ...poolBreakdown.map((pool) {
                  final name = pool['poolName'] as String? ?? 'Dịch vụ';
                  final share = (pool['myShare'] as num?)?.toDouble() ?? 0.0;
                  final totalAmt = (pool['totalAmount'] as num?)?.toDouble();
                  final method = pool['allocationMethod'] as String?;
                  final divisor = (pool['divisor'] as num?)?.toDouble();

                  String formulaStr = '';
                  if (totalAmt != null && method != null && divisor != null) {
                    final fmtTotal = _currencyFmt.format(totalAmt);
                    if (method == 'FLAT_PER_ROOM') {
                      formulaStr = 'Khoán cố định theo phòng';
                    } else if (method == 'FLAT_PER_TENANT') {
                      formulaStr = 'Đơn giá x Số người';
                    } else if (method == 'SHARED_EQUAL_ROOM') {
                      formulaStr = 'Tổng $fmtTotal ÷ ${divisor.toInt()} phòng';
                    } else if (method == 'SHARED_EQUAL_HEAD') {
                      formulaStr = 'Tổng $fmtTotal ÷ ${divisor.toInt()} người';
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailPopupRow(
                        '  $name',
                        _currencyFmt.format(share),
                        isPool: true,
                      ),
                      if (formulaStr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 36, bottom: 4),
                          child: Text(
                            '($formulaStr)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.kTextSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ] else if (bill.serviceAmount != null &&
                  bill.serviceAmount! > 0 &&
                  poolBreakdown.isEmpty) ...[
                const Divider(color: CupertinoColors.separator, height: 12),
                _buildDetailPopupRow(
                  'Phí dịch vụ khác',
                  _currencyFmt.format(bill.serviceAmount),
                ),
              ],
              // 5. Dịch vụ cá nhân (addon, xe) nếu có
              if (privateService > 0 && poolBreakdown.isNotEmpty) ...[
                _buildDetailPopupRow(
                  '  Addon & Dịch vụ riêng',
                  _currencyFmt.format(privateService),
                ),
              ],
              // 6. Giảm giá voucher
              if (bill.discountAmount != null && bill.discountAmount! > 0) ...[
                const Divider(color: CupertinoColors.separator, height: 12),
                _buildDetailPopupRow(
                  '🏷️ Giảm giá Voucher',
                  '-${_currencyFmt.format(bill.discountAmount)}',
                  isDiscount: true,
                ),
              ],
              const Divider(color: CupertinoColors.separator, height: 16),
              _buildDetailPopupRow(
                'TỔNG TIỀN HÓA ĐƠN',
                bill.totalAmount != null
                    ? _currencyFmt.format(bill.totalAmount)
                    : '0đ',
                isBold: true,
              ),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_printBillPdf(bill));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.printer, color: CupertinoColors.black),
                  SizedBox(width: 8),
                  Text(
                    'In / Xuất PDF Hóa Đơn',
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) =>
                        AuditLogsSheet(entityType: 'BILL', entityId: bill.id),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.time, color: CupertinoColors.activeBlue),
                  SizedBox(width: 8),
                  Text(
                    'Lịch sử thao tác',
                    style: TextStyle(color: CupertinoColors.activeBlue),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Đóng'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  // In / Xuất PDF hóa đơn
  Future<void> _printBillPdf(BillModel bill) async {
    try {
      final bytes = await PdfExportService.generateBillPdf(bill: bill);
      // Sử dụng Printing package để mở preview print (iOS/Android/Desktop)
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      if (!mounted) return;
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Lỗi'),
            content: Text('Không thể xuất PDF: $e'),
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
  }

  Widget _buildDetailPopupRow(
    String label,
    String value, {
    bool isBold = false,
    bool isPool = false,
    bool isDiscount = false,
  }) {
    final Color valueColor = isDiscount
        ? AppTheme
              .kSuccess // green for discount
        : isPool
        ? const Color(0xFF6366F1) // indigo for shared pool
        : CupertinoColors.black;
    final Color labelColor = isPool
        ? const Color(0xFF6366F1)
        : const Color(0xFF4B5563);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: isPool ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePopupRow(String label, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          GestureDetector(
            onTap: () {
              // Popup to view image full size
              unawaited(
                showCupertinoDialog(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    content: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imagePath.startsWith('http')
                          ? SafeNetworkImage(
                              url: imagePath,
                              fit: BoxFit.cover,
                              memCacheWidth: 600,
                            )
                          : ResponsiveFileImage(
                              File(imagePath),
                              fit: BoxFit.cover,
                            ),
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('Đóng'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.photo_fill,
                  size: 14,
                  color: CupertinoColors.activeBlue,
                ),
                SizedBox(width: 4),
                Text(
                  'Xem ảnh',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentQrPopup(BillModel bill) {
    final amount = bill.totalAmount?.toInt() ?? 0;
    final info = Uri.encodeComponent('Thue phong T${bill.month}/${bill.year}');
    const bankBin = '970415';
    const bankAccount = '113366668888';

    final qrUrl =
        bill.paymentQrUrl ??
        'https://img.vietqr.io/image/$bankBin-$bankAccount-compact2.png?amount=$amount&addInfo=$info';
    final isAutoPaymentEnabled =
        ref.read(featureFlagProvider)['FEATURE_AUTO_PAYMENT'] == true;

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return Container(
            decoration: const BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              top: 12,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Swipe Indicator
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.kTextMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                // Apple Pay style Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thanh Toán',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.kSurfaceBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 16,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount Display
                Text(
                  _currencyFmt.format(amount),
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'StayHub Invoice',
                  style: TextStyle(
                    color: AppTheme.kTextSecondary,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 32),

                // QR Code Area
                if (isAutoPaymentEnabled) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kTextSecondary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SafeNetworkImage(
                        url: qrUrl,
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        memCacheWidth: 440,
                        placeholder: const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: CupertinoActivityIndicator(radius: 14),
                          ),
                        ),
                        errorWidget: const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(
                            child: Icon(
                              CupertinoIcons.qrcode,
                              size: 80,
                              color: Color(0xFF0B192C),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quét mã VietQR bằng ứng dụng Ngân hàng',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.kSurfaceBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Chuyển khoản thủ công',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ngân hàng: $bankBin\nSố TK: $bankAccount\nNội dung: $info',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: CupertinoColors.black,
                        borderRadius: BorderRadius.circular(16),
                        onPressed: () {
                          Navigator.pop(ctx);
                          unawaited(
                            ref
                                .read(billProvider.notifier)
                                .payBillOnline(bill.id),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              size: 20,
                              color: CupertinoColors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đã Chuyển Khoản',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoButton(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.kSurfaceBlue,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () {
                        Navigator.pop(ctx);
                        unawaited(
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => SplitBillScreen(bill: bill),
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        CupertinoIcons.person_2_fill,
                        color: CupertinoColors.black,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: AppTheme.kSuccess, // Emerald green
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(context.push('/ai-receipt-scanner/${bill.id}'));
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.sparkles,
                        size: 20,
                        color: CupertinoColors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AI Scan Biên Lai',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUpdateUtilitiesDialog(BillModel bill) {
    final elecCtrl = TextEditingController(
      text: bill.electricCurrent?.toStringAsFixed(1) ?? '',
    );
    final waterCtrl = TextEditingController(
      text: bill.waterCurrent?.toStringAsFixed(1) ?? '',
    );

    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Chốt Điện Nước'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Text(
                  'Hóa đơn ${bill.periodLabel}',
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: elecCtrl,
                  placeholder: 'Chỉ số điện cuối kỳ (kWh)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.kSurfaceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.bolt_fill,
                      size: 16,
                      color: CupertinoColors.systemYellow,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: waterCtrl,
                  placeholder: 'Chỉ số nước cuối kỳ (m³)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.kSurfaceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.drop_fill,
                      size: 16,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Chốt số'),
              onPressed: () {
                Navigator.pop(ctx);
                final elec = double.tryParse(elecCtrl.text.trim());
                final water = double.tryParse(waterCtrl.text.trim());
                unawaited(
                  ref
                      .read(billProvider.notifier)
                      .updateUtilities(bill.id, elec, water),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendBulkInvoices(int count) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Phát hành hàng loạt'),
          content: Text(
            'Bạn có chắc muốn gửi $count hóa đơn chưa thanh toán cho khách thuê qua ứng dụng/SMS không?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text(
                'Gửi ngay',
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ToastUtils.show(context, 'Đã gửi thành công $count hóa đơn!');
                unawaited(ref.read(billProvider.notifier).refreshBills());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billProvider);
    final userRole = ref.watch(authProvider).value?.role;
    final isOwner = userRole == 'OWNER';
    final isStaff = userRole == 'STAFF';

    return LiquidGlassScaffold(
      title: 'Hóa Đơn',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.square_arrow_up,
          color: CupertinoColors.black,
          size: 24,
        ),
        onPressed: () {
          final val = ref.read(billProvider);
          if (val.hasValue) {
            final bills = val.value!
                .where((b) => b.month == _filterMonth && b.year == _filterYear)
                .toList();
            unawaited(_exportCsv(bills));
          }
        },
      ),
      onRefresh: () async => ref.read(billProvider.notifier).refreshBills(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: state.when(
          data: (allBills) {
            final bills = allBills
                .where(
                  (b) =>
                      b.month == _filterMonth &&
                      b.year == _filterYear &&
                      ('Phòng ${b.roomId}'.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          'Khách thuê ${b.tenantId}'.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )),
                )
                .toList();

            final unpaidBills = bills.where((b) => !b.isPaid).toList();
            final paidBills = bills.where((b) => b.isPaid).toList();
            final currentList = _selectedSegment == 0 ? unpaidBills : paidBills;
            final totalUnpaid = unpaidBills.fold<double>(
              0,
              (sum, b) => sum + (b.totalAmount ?? 0),
            );

            return Column(
              children: [
                // Filter and Search Row
                Row(
                  children: [
                    Expanded(
                      child: CupertinoSearchTextField(
                        placeholder: 'Tìm phòng, người thuê...',
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: const Icon(
                              CupertinoIcons.minus_circle,
                              size: 20,
                              color: CupertinoColors.systemBlue,
                            ),
                            onPressed: () => setState(() {
                              if (_filterMonth == 1) {
                                _filterMonth = 12;
                                _filterYear--;
                              } else {
                                _filterMonth--;
                              }
                            }),
                          ),
                          Text(
                            '$_filterMonth/$_filterYear',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: const Icon(
                              CupertinoIcons.add_circled,
                              size: 20,
                              color: CupertinoColors.systemBlue,
                            ),
                            onPressed: () => setState(() {
                              if (_filterMonth == 12) {
                                _filterMonth = 1;
                                _filterYear++;
                              } else {
                                _filterMonth++;
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary Banner
                if (unpaidBills.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: PremiumGradients.fireOrange,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.kPremiumShadowLight,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemRed.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.exclamationmark_circle_fill,
                                color: CupertinoColors.systemRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${unpaidBills.length} hóa đơn chờ thanh toán',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tổng: ${NumberFormat.compactCurrency(locale: 'vi_VN', symbol: 'đ').format(totalUnpaid)}',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
                // Selector Cupertino
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedSegment,
                    thumbColor: LiquidGlassColors.tenantAccent,
                    backgroundColor: CupertinoColors.white.withValues(
                      alpha: 0.5,
                    ),
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Chưa thanh toán (${unpaidBills.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedSegment == 0
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Đã thanh toán (${paidBills.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedSegment == 1
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _selectedSegment = val);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                currentList.isEmpty
                    ? PremiumEmptyStateWidget(
                        title: _selectedSegment == 0
                            ? 'Không có hóa đơn chờ'
                            : 'Chưa có lịch sử',
                        message: _selectedSegment == 0
                            ? 'Tất cả hóa đơn đã được thanh toán. Tuyệt vời!'
                            : 'Chưa có hóa đơn nào được thanh toán.',
                        icon: _selectedSegment == 0
                            ? CupertinoIcons.checkmark_seal_fill
                            : CupertinoIcons.doc_plaintext,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isOwner &&
                              _selectedSegment == 0 &&
                              currentList.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () =>
                                    _sendBulkInvoices(currentList.length),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.kSuccess,
                                        Color(0xFF059669),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.kSuccess.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.paperplane_fill,
                                        color: CupertinoColors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Gửi Tất Cả Hóa Đơn',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: CupertinoColors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          AnimationLimiter(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentList.length,
                              itemBuilder: (ctx, idx) {
                                final b = currentList[idx];
                                final cardColor = b.isPaid
                                    ? LiquidGlassColors.tenantAccent
                                    : (b.isOverdue
                                          ? CupertinoColors.systemRed
                                          : AppTheme.kAccentColor);

                                return AnimationConfiguration.staggeredList(
                                  position: idx,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 40,
                                    child: FadeInAnimation(
                                      child: BounceClick(
                                        onPressed: () => _showDetailSheet(b),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              gradient: LinearGradient(
                                                colors: [
                                                  CupertinoColors.white
                                                      .withValues(alpha: 0.9),
                                                  AppTheme.kSurfaceBlue
                                                      .withValues(alpha: 0.9),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow:
                                                  AppTheme.kPremiumShadowLight,
                                            ),
                                            child: Stack(
                                              children: [
                                                // Nếp gấp hóa đơn (Ticket Notch Left)
                                                Positioned(
                                                  left: -12,
                                                  top: 60,
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: AppTheme
                                                              .kBackgroundLight,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                ),
                                                // Nếp gấp hóa đơn (Ticket Notch Right)
                                                Positioned(
                                                  right: -12,
                                                  top: 60,
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: AppTheme
                                                              .kBackgroundLight,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Hóa đơn ${b.periodLabel}',
                                                            style: const TextStyle(
                                                              color:
                                                                  CupertinoColors
                                                                      .black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 18,
                                                              letterSpacing:
                                                                  -0.5,
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: cardColor
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                              border: Border.all(
                                                                color: cardColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              b.isPaid
                                                                  ? 'Đã thanh toán'
                                                                  : (b.status ==
                                                                            'PENDING_CASH'
                                                                        ? 'Chờ xác nhận'
                                                                        : (b.isOverdue
                                                                              ? 'Quá hạn'
                                                                              : 'Chờ thanh toán')),
                                                              style: TextStyle(
                                                                color:
                                                                    b.status ==
                                                                        'PENDING_CASH'
                                                                    ? CupertinoColors
                                                                          .systemOrange
                                                                    : cardColor,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      // Dashed Line Simulation (using dotted text or custom widget, here we just use small dashes)
                                                      Text(
                                                        '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                                                        style: TextStyle(
                                                          color: AppTheme
                                                              .kTextMuted
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          letterSpacing: 2,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.clip,
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),

                                                      if (b.rentAmount != null)
                                                        _buildBillRow(
                                                          'Tiền thuê nhà',
                                                          _currencyFmt.format(
                                                            b.rentAmount,
                                                          ),
                                                        ),
                                                      if (b.electricAmount !=
                                                          null)
                                                        _buildBillRow(
                                                          'Tiền điện',
                                                          _currencyFmt.format(
                                                            b.electricAmount,
                                                          ),
                                                        ),
                                                      if (b.waterAmount != null)
                                                        _buildBillRow(
                                                          'Tiền nước',
                                                          _currencyFmt.format(
                                                            b.waterAmount,
                                                          ),
                                                        ),
                                                      if (b.serviceAmount !=
                                                              null &&
                                                          b.serviceAmount! > 0)
                                                        _buildBillRow(
                                                          'Phí dịch vụ khác',
                                                          _currencyFmt.format(
                                                            b.serviceAmount,
                                                          ),
                                                        ),

                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      const Divider(
                                                        color: CupertinoColors
                                                            .separator,
                                                        height: 16,
                                                        thickness: 0.5,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text(
                                                            'TỔNG CỘNG',
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFF4B5563,
                                                              ),
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          Text(
                                                            _currencyFmt.format(
                                                              b.totalAmount ??
                                                                  0.0,
                                                            ),
                                                            style: TextStyle(
                                                              color: cardColor,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      if (!b.isPaid) ...[
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        // Owner: Chốt điện nước + Xác nhận tiền mặt
                                                        if (isOwner) ...[
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: CupertinoButton(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  onPressed: () =>
                                                                      _showDetailSheet(
                                                                        b,
                                                                      ),
                                                                  child: const GlassContainer(
                                                                    borderRadius:
                                                                        14,
                                                                    padding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              10,
                                                                        ),
                                                                    color: CupertinoColors
                                                                        .white,
                                                                    child: Center(
                                                                      child: Text(
                                                                        'Chi tiết',
                                                                        style: TextStyle(
                                                                          color:
                                                                              CupertinoColors.black,
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: CupertinoButton(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  onPressed: () =>
                                                                      _showUpdateUtilitiesDialog(
                                                                        b,
                                                                      ),
                                                                  child: GlassContainer(
                                                                    borderRadius:
                                                                        14,
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              10,
                                                                        ),
                                                                    color: CupertinoColors
                                                                        .systemYellow
                                                                        .withValues(
                                                                          alpha:
                                                                              0.15,
                                                                        ),
                                                                    hasBorder:
                                                                        true,
                                                                    child: const Center(
                                                                      child: Text(
                                                                        'Chốt điện nước',
                                                                        style: TextStyle(
                                                                          color:
                                                                              CupertinoColors.systemYellow,
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              if (b.status ==
                                                                  'PENDING_CASH') ...[
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Expanded(
                                                                  child: CupertinoButton(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    onPressed: () async {
                                                                      final success =
                                                                          await BiometricUtils.authenticate(
                                                                            context,
                                                                            ref,
                                                                          );
                                                                      if (success &&
                                                                          context
                                                                              .mounted) {
                                                                        unawaited(
                                                                          ref
                                                                              .read(
                                                                                billProvider.notifier,
                                                                              )
                                                                              .confirmCashPayment(
                                                                                b.id,
                                                                              ),
                                                                        );
                                                                      }
                                                                    },
                                                                    child: GlassContainer(
                                                                      borderRadius:
                                                                          14,
                                                                      padding: const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            10,
                                                                      ),
                                                                      color: CupertinoColors
                                                                          .activeGreen
                                                                          .withValues(
                                                                            alpha:
                                                                                0.15,
                                                                          ),
                                                                      hasBorder:
                                                                          true,
                                                                      child: const Center(
                                                                        child: Text(
                                                                          'Xác nhận thu',
                                                                          style: TextStyle(
                                                                            color:
                                                                                CupertinoColors.activeGreen,
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ] else if (isStaff) ...[
                                                          // Staff: Thu tiền mặt
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: CupertinoButton(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  onPressed: () =>
                                                                      _showDetailSheet(
                                                                        b,
                                                                      ),
                                                                  child: const GlassContainer(
                                                                    borderRadius:
                                                                        14,
                                                                    padding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              10,
                                                                        ),
                                                                    color: CupertinoColors
                                                                        .white,
                                                                    child: Center(
                                                                      child: Text(
                                                                        'Chi tiết',
                                                                        style: TextStyle(
                                                                          color:
                                                                              CupertinoColors.black,
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              if (b.status ==
                                                                  'PENDING_CASH')
                                                                Expanded(
                                                                  child: Container(
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              10,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: CupertinoColors
                                                                          .systemOrange
                                                                          .withValues(
                                                                            alpha:
                                                                                0.15,
                                                                          ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            14,
                                                                          ),
                                                                    ),
                                                                    child: const Center(
                                                                      child: Text(
                                                                        'Chờ chủ nhà duyệt',
                                                                        style: TextStyle(
                                                                          color:
                                                                              CupertinoColors.systemOrange,
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              else
                                                                Expanded(
                                                                  child: CupertinoButton(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    onPressed: () async {
                                                                      final success =
                                                                          await BiometricUtils.authenticate(
                                                                            context,
                                                                            ref,
                                                                          );
                                                                      if (success &&
                                                                          context
                                                                              .mounted) {
                                                                        unawaited(
                                                                          ref
                                                                              .read(
                                                                                billProvider.notifier,
                                                                              )
                                                                              .payBill(
                                                                                b.id,
                                                                                cash: true,
                                                                              ),
                                                                        );
                                                                      }
                                                                    },
                                                                    child: GlassContainer(
                                                                      borderRadius:
                                                                          14,
                                                                      padding: const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            10,
                                                                      ),
                                                                      color: CupertinoColors
                                                                          .systemGreen
                                                                          .withValues(
                                                                            alpha:
                                                                                0.15,
                                                                          ),
                                                                      hasBorder:
                                                                          true,
                                                                      child: const Center(
                                                                        child: Text(
                                                                          'Thu tiền mặt',
                                                                          style: TextStyle(
                                                                            color:
                                                                                CupertinoColors.systemGreen,
                                                                            fontSize:
                                                                                13,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ] else ...[
                                                          // Tenant: Thanh toán
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: CupertinoButton(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  onPressed: () =>
                                                                      _showDetailSheet(
                                                                        b,
                                                                      ),
                                                                  child: const GlassContainer(
                                                                    borderRadius:
                                                                        14,
                                                                    padding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              10,
                                                                        ),
                                                                    color: CupertinoColors
                                                                        .white,
                                                                    child: Center(
                                                                      child: Text(
                                                                        'Chi tiết',
                                                                        style: TextStyle(
                                                                          color:
                                                                              CupertinoColors.black,
                                                                          fontSize:
                                                                              14,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              if (b.status ==
                                                                  'PENDING_CASH')
                                                                Expanded(
                                                                  child: Container(
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              10,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: CupertinoColors
                                                                          .systemOrange
                                                                          .withValues(
                                                                            alpha:
                                                                                0.15,
                                                                          ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            14,
                                                                          ),
                                                                    ),
                                                                    child: const Center(
                                                                      child: Text(
                                                                        'Chờ chủ nhà xác nhận',
                                                                        style: TextStyle(
                                                                          color:
                                                                              CupertinoColors.systemOrange,
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              else
                                                                Expanded(
                                                                  child: CupertinoButton(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    onPressed: () async {
                                                                      final success =
                                                                          await BiometricUtils.authenticate(
                                                                            context,
                                                                            ref,
                                                                          );
                                                                      if (success &&
                                                                          context
                                                                              .mounted) {
                                                                        _showPaymentQrPopup(
                                                                          b,
                                                                        );
                                                                      }
                                                                    },
                                                                    child: GlassContainer(
                                                                      borderRadius:
                                                                          14,
                                                                      padding: const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            10,
                                                                      ),
                                                                      color: AppTheme
                                                                          .kAccentColor
                                                                          .withValues(
                                                                            alpha:
                                                                                0.15,
                                                                          ),
                                                                      hasBorder:
                                                                          true,
                                                                      child: const Center(
                                                                        child: Text(
                                                                          'Thanh toán',
                                                                          style: TextStyle(
                                                                            color:
                                                                                AppTheme.kAccentColor,
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 100),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: ShimmerListLoading(),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 150),
              child: Text(
                'Lỗi: $err',
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
