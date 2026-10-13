import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/auth_notifier.dart';

class QrCashReceiverScreen extends ConsumerStatefulWidget {
  final String? sessionType;
  final String? branchId;

  const QrCashReceiverScreen({super.key, this.sessionType, this.branchId});

  @override
  ConsumerState<QrCashReceiverScreen> createState() =>
      _QrCashReceiverScreenState();
}

class _QrCashReceiverScreenState extends ConsumerState<QrCashReceiverScreen> {
  String? qrData;
  bool isLoading = true;
  String? sessionId;
  Timer? _qrTimer;
  int _secondsLeft = 300;

  final List<Map<String, dynamic>> _pendingTransactions = [];
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    unawaited(_generateQr());
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    SSEClient.unsubscribeFromSSE();
    super.dispose();
  }

  Future<void> _generateQr() async {
    setState(() {
      isLoading = true;
      qrData = null;
    });

    try {
      final response = await _apiClient.dio.post(
        '/v1/cash/generate-qr',
        queryParameters: {
          'sessionType': widget.sessionType ?? 'OWNER_RECEIVE',
          if (widget.branchId != null) 'branchId': widget.branchId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          sessionId = response.data['data']['sessionId'];
          qrData = sessionId;
          isLoading = false;
          _secondsLeft = 300; // 5 minutes
        });
        _startTimer();
        unawaited(_subscribeSSE());
      }
    } catch (e) {
      setState(() => isLoading = false);
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = (e.response?.data is Map)
            ? (e.response?.data['message'] ?? e.message)
            : (e.message ?? 'Lỗi kết nối mạng');
      }
      if (mounted) ToastUtils.show(context, 'Lỗi tạo QR: $errorMsg');
    }
  }

  void _startTimer() {
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        unawaited(_generateQr());
      }
    });
  }

  Future<void> _subscribeSSE() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    final token = await const FlutterSecureStorage().read(key: 'access_token');

    SSEClient.unsubscribeFromSSE();
    SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: '${ApiClient.baseUrl}/v1/cash/stream/${user.id}',
      header: {"Authorization": "Bearer $token", "Accept": "text/event-stream"},
    ).listen((event) {
      if (event.event == 'QR_SCANNED' && event.data != null) {
        try {
          final data = jsonDecode(event.data!);
          if (data['sessionId'] == sessionId && mounted) {
            setState(() {
              final scannerName = data['scannerName'] ?? 'Người dùng';
              final scannerRole = data['scannerRole'] ?? 'Khách';
              _pendingTransactions.add({
                'id': data['sessionId'],
                'title': 'Người nộp: $scannerName ($scannerRole)',
                'subtitle': data['type'] == 'STAFF_HANDOVER_CASH'
                    ? 'Bàn giao tiền mặt'
                    : 'Thanh toán hóa đơn',
                'amount': data['amount'],
                'time': 'Vừa xong',
              });
            });
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _approveTransaction(int index) async {
    final tx = _pendingTransactions[index];

    try {
      final response = await _apiClient.dio.post(
        '/v1/cash/confirm',
        queryParameters: {'sessionId': tx['id']},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _pendingTransactions.removeAt(index);
        });
        if (mounted) {
          ToastUtils.show(
            context,
            'Đã xác nhận nhận tiền thành công!',
            isError: false,
          );
        }
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = (e.response?.data is Map)
            ? (e.response?.data['message'] ?? e.message)
            : (e.message ?? 'Lỗi kết nối mạng');
      }
      if (mounted) ToastUtils.show(context, 'Lỗi duyệt tiền: $errorMsg');
    }
  }

  Future<void> _rejectTransaction(int index) async {
    final tx = _pendingTransactions[index];

    try {
      final response = await _apiClient.dio.post(
        '/v1/cash/cancel',
        queryParameters: {'sessionId': tx['id']},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _pendingTransactions.removeAt(index);
        });
        if (mounted) {
          ToastUtils.show(context, 'Đã từ chối giao dịch', isError: false);
        }
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = (e.response?.data is Map)
            ? (e.response?.data['message'] ?? e.message)
            : (e.message ?? 'Lỗi kết nối mạng');
      }
      if (mounted) ToastUtils.show(context, 'Lỗi từ chối: $errorMsg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      appBar: AppBar(title: const Text('Nhận Tiền Mặt (QR)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Phần hiển thị mã QR
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Sử dụng mã QR này để Khách thuê hoặc Nhân viên quét và nộp tiền mặt cho bạn.',
                    style: TextStyle(
                      color: AppTheme.kTextSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Làm mới sau: ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppTheme.kBrand,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading || qrData == null)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Phần danh sách chờ duyệt
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: AppTheme.kWarning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Yêu cầu chờ duyệt (${_pendingTransactions.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_pendingTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppTheme.kSuccess.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không có giao dịch nào đang chờ duyệt',
                      style: TextStyle(color: AppTheme.kTextMuted),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingTransactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tx = _pendingTransactions[index];
                  return GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tx['subtitle']} • ${tx['time']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currencyFormat.format(tx['amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.kBrand,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => _approveTransaction(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.kSuccess,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                minimumSize: const Size(100, 36),
                              ),
                              child: const Text('Duyệt'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _rejectTransaction(index),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.kError,
                                minimumSize: const Size(100, 36),
                              ),
                              child: const Text('Từ chối'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
