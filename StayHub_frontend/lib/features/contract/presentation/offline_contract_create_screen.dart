import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/premium_button.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../../core/services/pdf_export_service.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:async' show unawaited;

class OfflineContractCreateScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String roomName;

  const OfflineContractCreateScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<OfflineContractCreateScreen> createState() =>
      _OfflineContractCreateScreenState();
}

class _OfflineContractCreateScreenState
    extends ConsumerState<OfflineContractCreateScreen> {
  final _tenantNameController = TextEditingController();
  final _tenantPhoneController = TextEditingController();
  final _tenantCccdController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _elecPriceController = TextEditingController(text: '3500');
  final _waterPriceController = TextEditingController(text: '80000');
  final _initialElecController = TextEditingController();
  final _initialWaterController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(
    const Duration(days: 180),
  ); // 6 months default
  bool _isDepositPaid = false;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _mockScanCCCD() async {
    // unawaited(Show a loading dialog)
    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: CupertinoColors.black,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(
                  radius: 16,
                  color: CupertinoColors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'Đang phân tích AI...',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading

    // Auto-fill mock data
    setState(() {
      _tenantNameController.text = 'NGUYỄN VĂN A';
      _tenantPhoneController.text = '0901234567';
      _tenantCccdController.text = '001099000123';
    });

    // Show success haptic and toast
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Trích xuất CCCD thành công!'),
        backgroundColor: CupertinoColors.activeGreen,
      ),
    );
  }

  Future<void> _submit() async {
    if (_tenantNameController.text.isEmpty ||
        _tenantPhoneController.text.isEmpty ||
        _tenantCccdController.text.isEmpty ||
        _tenantCccdController.text.length != 12 ||
        _rentAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng điền đủ Tên, SĐT, đúng 12 số CCCD và Tiền thuê',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final owner = ref.read(authProvider).value;
      if (owner == null) throw Exception('Không tìm thấy thông tin chủ nhà');

      final depositAmount = double.tryParse(_depositAmountController.text) ?? 0;
      final rentAmount = double.tryParse(_rentAmountController.text) ?? 0;
      final elecPrice = double.tryParse(_elecPriceController.text) ?? 0;
      final waterPrice = double.tryParse(_waterPriceController.text) ?? 0;
      final initialElec = double.tryParse(_initialElecController.text) ?? 0;
      final initialWater = double.tryParse(_initialWaterController.text) ?? 0;

      final api = ref.read(apiClientProvider);

      // Lấy thông tin Branch để xuất địa chỉ chuẩn pháp lý 34 tỉnh
      String fullAddress = '';
      try {
        final roomData = await api.get('/v1/rooms/${widget.roomId}');
        final branchData = roomData['branch'];
        if (branchData != null) {
          final legalProv = branchData['legalProvince'];
          final prov = branchData['province'];
          if ((legalProv == null || legalProv.toString().isEmpty) &&
              (prov == null || prov.toString().isEmpty)) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chi nhánh chưa cập nhật địa chỉ. Vui lòng cập nhật trước khi xuất hợp đồng.',
                  ),
                ),
              );
            }
            return;
          }
          final p = (legalProv?.toString().isNotEmpty == true)
              ? legalProv
              : prov;
          final d = branchData['legalDistrict'] ?? branchData['district'] ?? '';
          final w = branchData['legalWard'] ?? branchData['ward'] ?? '';
          final detail = branchData['addressDetail'] ?? '';

          final addrParts = [
            detail,
            w,
            d,
            p,
          ].where((e) => e.toString().trim().isNotEmpty).toList();
          fullAddress = addrParts.join(', ');
        }
      } catch (e) {
        debugPrint('Failed to load room/branch data: $e');
      }

      // Lấy custom template của chủ nhà
      String? customTerms;
      try {
        final res = await api.get('/v1/owner-contract-templates/${owner.id}');
        if (res['templateText'] != null &&
            res['templateText'].toString().trim().isNotEmpty) {
          customTerms = res['templateText'].toString();
        }
      } catch (e) {
        debugPrint('Failed to load custom terms: $e');
      }

      // Gen PDF first
      final pdfBytes = await PdfExportService.generateOfflineContractPdf(
        ownerName: owner.fullName,
        ownerPhone: owner.phoneNumber,
        tenantName: _tenantNameController.text,
        tenantPhone: _tenantPhoneController.text,
        tenantCccd: _tenantCccdController.text,
        roomName: widget.roomName,
        address: fullAddress,
        rentAmount: rentAmount,
        depositAmount: depositAmount,
        electricityPrice: elecPrice,
        waterPrice: waterPrice,
        startDate: _startDate,
        endDate: _endDate,
        initialElectricity: initialElec,
        initialWater: initialWater,
        customTerms: customTerms,
      );

      // Create Contract in Backend
      final reqData = {
        'roomId': widget.roomId,
        'tenantName': _tenantNameController.text,
        'tenantPhone': _tenantPhoneController.text,
        'tenantCccd': _tenantCccdController.text,
        'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
        'monthlyRent': rentAmount,
        'depositAmount': depositAmount,
        'electricityPrice': elecPrice,
        'waterPrice': waterPrice,
        'terms': customTerms ?? 'Hợp đồng Offline',
      };

      await api.post('/v1/contracts/offline-create', data: reqData);

      // Cập nhật lại danh sách phòng + thống kê dashboard (trạng thái phòng đổi).
      refreshOwnerDashboardFromWidget(ref);

      setState(() => _isLoading = false);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );

      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('✅ Tạo Hợp Đồng Thành Công!'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Hợp đồng đã được tạo. Phòng hiện ở trạng thái CHờ KÍCH HOẠT.\n\nIn hợp đồng, cho khách ký, sau đó quay lại kích hoạt để hoàn tất.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/contract');
              },
              child: const Text('Xem Danh sách Hợp Đồng'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: const Text('Cho thuê Offline'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Smart Auto-Fill Button
              PremiumButton(
                text: '📸 Quét CCCD tự động điền',
                onPressed: _mockScanCCCD,
                gradient: PremiumGradients.purpleNebula,
              ),
              const SizedBox(height: 32),
              _buildSection('Thông tin Khách', [
                TextField(
                  controller: _tenantNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên khách hàng (*)',
                  ),
                ),
                TextField(
                  controller: _tenantPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại (*)',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _tenantCccdController,
                  decoration: const InputDecoration(labelText: 'CCCD/CMND (*)'),
                  keyboardType: TextInputType.number,
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection('Hợp đồng & Tài chính', [
                TextField(
                  controller: _rentAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Giá thuê/tháng (*)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _depositAmountController,
                  decoration: const InputDecoration(labelText: 'Tiền cọc'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _elecPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Giá điện',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _waterPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Giá nước',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                ListTile(
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),
                ListTile(
                  title: const Text('Ngày kết thúc'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection('Bàn giao ban đầu', [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _initialElecController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện đầu vào',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _initialWaterController,
                        decoration: const InputDecoration(
                          labelText: 'Số nước đầu vào',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Khách đã thanh toán Cọc / Tháng đầu'),
                value: _isDepositPaid,
                onChanged: (val) =>
                    setState(() => _isDepositPaid = val ?? false),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : () => _submit(),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Tạo Hợp Đồng & In PDF',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
