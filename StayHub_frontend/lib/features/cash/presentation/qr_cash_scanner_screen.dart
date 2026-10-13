import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/toast_utils.dart';
import 'dart:async' show unawaited;

class QrCashScannerScreen extends ConsumerStatefulWidget {
  const QrCashScannerScreen({super.key});

  @override
  ConsumerState<QrCashScannerScreen> createState() =>
      _QrCashScannerScreenState();
}

class _QrCashScannerScreenState extends ConsumerState<QrCashScannerScreen> {
  bool isScanning = true;
  String? detectedSessionId;

  late ApiClient _apiClient;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          isScanning = false;
          detectedSessionId = barcode.rawValue;
        });

        await _fetchPreviewAndShowSheet(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _fetchPreviewAndShowSheet(String sessionId) async {
    try {
      // unawaited(Show loading overlay)
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(
            child: CircularProgressIndicator(color: AppTheme.kBrand),
          ),
        ),
      );

      final response = await _apiClient.dio.get(
        '/v1/cash/preview-scan',
        queryParameters: {'sessionId': sessionId},
      );

      if (mounted) Navigator.pop(context); // close loading

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> bills = data['bills'] ?? [];
        final String sessionType = data['sessionType'] ?? '';
        final String creatorName = data['creatorName'] ?? 'Người dùng';
        final String creatorRole = data['creatorRole'] ?? 'Quản lý';
        _showChecklistSheet(bills, sessionType, creatorName, creatorRole);
      } else {
        if (mounted) {
          ToastUtils.show(
            context,
            response.data['message'] ?? 'Lỗi tải thông tin QR',
          );
          setState(() => isScanning = true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ToastUtils.show(context, 'Lỗi kết nối khi quét QR: $e');
        setState(() => isScanning = true);
      }
    }
  }

  void _showChecklistSheet(
    List<dynamic> bills,
    String sessionType,
    String creatorName,
    String creatorRole,
  ) {
    Set<int> selectedBillIds = {};
    double totalAmount = 0.0;

    void updateSelection(
      bool? selected,
      dynamic bill,
      void Function(void Function()) setModalState,
    ) {
      setModalState(() {
        if (selected == true) {
          selectedBillIds.add(bill['id']);
          totalAmount += bill['totalAmount'] ?? 0.0;
        } else {
          selectedBillIds.remove(bill['id']);
          totalAmount -= bill['totalAmount'] ?? 0.0;
        }
        if (totalAmount < 0) totalAmount = 0;
      });
    }

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: AppTheme.kBrand,
                ),
                const SizedBox(height: 16),
                Text(
                  sessionType == 'OWNER_RECEIVE' ||
                          sessionType == 'TENANT_PAY_BILL'
                      ? 'Chọn hóa đơn cần nộp'
                      : 'Chọn khoản tiền cần nộp',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Người nhận: $creatorName ($creatorRole)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: bills.isEmpty
                      ? const Center(
                          child: Text('Không có khoản tiền nào chờ xử lý'),
                        )
                      : ListView.builder(
                          itemCount: bills.length,
                          itemBuilder: (context, index) {
                            final bill = bills[index];
                            final isSelected = selectedBillIds.contains(
                              bill['id'],
                            );
                            final title =
                                sessionType == 'OWNER_RECEIVE' ||
                                    sessionType == 'TENANT_PAY_BILL'
                                ? 'Hóa đơn tháng ${bill['month']}/${bill['year']}'
                                : 'Tiền thu - HĐ T${bill['month']}/${bill['year']}';
                            return CheckboxListTile(
                              title: Text(title),
                              subtitle: Text(
                                '${(bill['totalAmount'] ?? 0.0).toStringAsFixed(0)} VNĐ',
                              ),
                              value: isSelected,
                              activeColor: AppTheme.kBrand,
                              onChanged: (val) =>
                                  updateSelection(val, bill, setModalState),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.kBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${totalAmount.toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.kBrand,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => isScanning = true);
                        },
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (isSubmitting || selectedBillIds.isEmpty)
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                try {
                                  final response = await _apiClient.dio.post(
                                    '/v1/cash/scan-qr',
                                    queryParameters: {
                                      'sessionId': detectedSessionId,
                                      'amount': totalAmount,
                                      'itemIds': selectedBillIds.join(','),
                                    },
                                  );
                                  if (response.statusCode == 200 &&
                                      response.data['success'] == true) {
                                    if (context.mounted) {
                                      Navigator.pop(context); // close sheet
                                      context.pop(); // close scanner screen
                                      ToastUtils.show(
                                        context,
                                        'Đã gửi yêu cầu, vui lòng chờ Chủ nhà duyệt!',
                                        isError: false,
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ToastUtils.show(
                                        context,
                                        response.data['message'] ??
                                            'Lỗi không xác định',
                                      );
                                    }
                                    setModalState(() => isSubmitting = false);
                                    setState(() => isScanning = true);
                                  }
                                } catch (e) {
                                  String errorMsg = e.toString();
                                  if (e is DioException) {
                                    errorMsg = (e.response?.data is Map)
                                        ? (e.response?.data['message'] ??
                                              e.message)
                                        : (e.message ?? 'Lỗi kết nối mạng');
                                  }
                                  if (!context.mounted) return;
                                  ToastUtils.show(
                                    context,
                                    'Lỗi kết nối: $errorMsg',
                                  );
                                  setModalState(() => isSubmitting = false);
                                  setState(() => isScanning = true);
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Xác nhận nộp'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).whenComplete(() {
        if (!isSubmitting) {
          setState(() => isScanning = true);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã thanh toán')),
      body: Stack(
        children: [
          MobileScanner(onDetect: (capture) => _onDetect(capture)),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.kBrand, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
