import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/toast_utils.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/core_providers.dart';

import 'package:dio/dio.dart';
import 'dart:async' show unawaited;

// Removed hardcoded popular banks

class BankConfigScreen extends ConsumerStatefulWidget {
  const BankConfigScreen({super.key});

  @override
  ConsumerState<BankConfigScreen> createState() => _BankConfigScreenState();
}

class _BankConfigScreenState extends ConsumerState<BankConfigScreen> {
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  String? _selectedBankBin;
  String? _selectedBankName;
  String? _selectedBankLogo;

  bool _isLoading = false;
  List<dynamic> _allBanks = [];
  bool _isLoadingBanks = false;

  @override
  void initState() {
    super.initState();
    _loadExistingBankInfo();
  }

  void _loadExistingBankInfo() {
    unawaited(_fetchBanks());
    final user = ref.read(authProvider).value;
    if (user != null) {
      _accountNumberCtrl.text = user.bankAccountNumber ?? '';
      _accountNameCtrl.text = user.bankAccountName ?? user.fullName;
      _selectedBankName = user.bankName;
      // Note: The bin and logo will be matched when banks finish loading.
    }
  }

  Future<void> _fetchBanks() async {
    setState(() => _isLoadingBanks = true);
    try {
      final dio = Dio();
      final res = await dio.get('https://api.vietqr.io/v2/banks');
      if (res.data != null && res.data['data'] != null) {
        setState(() {
          _allBanks = res.data['data'];
          if (_selectedBankName != null) {
            final match = _allBanks
                .where(
                  (b) =>
                      b['name'] == _selectedBankName ||
                      b['shortName'] == _selectedBankName,
                )
                .firstOrNull;
            if (match != null) {
              _selectedBankBin = match['bin'];
              _selectedBankLogo = match['logo'];
              _selectedBankName = match['name']; // normalize name
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load banks: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBanks = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_selectedBankBin == null ||
        _accountNumberCtrl.text.isEmpty ||
        _accountNameCtrl.text.isEmpty) {
      ToastUtils.show(
        context,
        'Vui lòng điền đầy đủ thông tin ngân hàng!',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.put(
        '/v1/users/me',
        data: {
          'bankName': _selectedBankName,
          'bankAccountNumber': _accountNumberCtrl.text,
          'bankAccountName': _accountNameCtrl.text,
        },
      );

      // Refresh user auth data so it fetches the new bank info
      await ref.read(authProvider.notifier).checkAuth();

      if (mounted) {
        ToastUtils.show(context, 'Đã lưu cấu hình ngân hàng thành công!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Lỗi: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBankPicker() {
    if (_allBanks.isEmpty) {
      if (_isLoadingBanks) {
        ToastUtils.show(context, 'Đang tải danh sách ngân hàng...');
        return;
      }
      ToastUtils.show(
        context,
        'Không tải được danh sách ngân hàng',
        isError: true,
      );
      return;
    }

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              List<dynamic> filtered = _allBanks;

              void filter(String query) {
                final q = query.toLowerCase();
                setModalState(() {
                  filtered = _allBanks.where((b) {
                    final name = b['name']?.toString().toLowerCase() ?? '';
                    final shortName =
                        b['shortName']?.toString().toLowerCase() ?? '';
                    return name.contains(q) || shortName.contains(q);
                  }).toList();
                });
              }

              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chọn Ngân hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: CupertinoSearchTextField(
                        placeholder: 'Tìm kiếm ngân hàng...',
                        onChanged: filter,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final b = filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  b['logo'] ?? '',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.account_balance,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              b['shortName'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              b['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedBankBin = b['bin'];
                                _selectedBankName = b['name'];
                                _selectedBankLogo = b['logo'];
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kTextPrimary, // Deep rich blue-dark background
      body: Stack(
        children: [
          // Premium glowing mesh background effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.kBrandLight.withValues(alpha: 0.15),
                boxShadow: const [
                  BoxShadow(blurRadius: 100, color: AppTheme.kBrandLight),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                boxShadow: const [
                  BoxShadow(blurRadius: 100, color: Color(0xFF8B5CF6)),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.back,
                          color: Colors.white,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Cấu hình Ngân hàng',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Balance the back button
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Virtual Card
                        _buildVirtualCard(),
                        const SizedBox(height: 32),

                        const Text(
                          'Cài đặt thanh toán VietQR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thông tin này sẽ được dùng để tự động tạo mã QR thanh toán trên hóa đơn.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        _buildLabel('Ngân hàng thụ hưởng'),
                        GestureDetector(
                          onTap: _showBankPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_selectedBankLogo != null)
                                  Container(
                                    width: 40,
                                    height: 30,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        _selectedBankLogo!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.account_balance,
                                              color: Colors.grey,
                                              size: 16,
                                            ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    _selectedBankName ?? 'Chọn ngân hàng',
                                    style: TextStyle(
                                      color: _selectedBankName != null
                                          ? Colors.white
                                          : Colors.white54,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  CupertinoIcons.chevron_down,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildLabel('Số tài khoản'),
                        _buildTextField(
                          _accountNumberCtrl,
                          'Nhập số tài khoản',
                          TextInputType.number,
                        ),

                        const SizedBox(height: 20),
                        _buildLabel('Tên chủ tài khoản'),
                        _buildTextField(
                          _accountNameCtrl,
                          'Tên in hoa không dấu',
                          TextInputType.name,
                          TextCapitalization.characters,
                        ),

                        const SizedBox(height: 40),

                        // Save Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [AppTheme.kBrand, Color(0xFF3B82F6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.kBrand.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onPressed: _isLoading ? null : _saveConfig,
                            child: _isLoading
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  )
                                : const Text(
                                    'LƯU CẤU HÌNH',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
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
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String placeholder,
    TextInputType type, [
    TextCapitalization cap = TextCapitalization.none,
  ]) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: type,
      textCapitalization: cap,
      padding: const EdgeInsets.all(18),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      placeholderStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      onChanged: (val) => setState(() {}), // Trigger rebuild for Virtual Card
    );
  }

  Widget _buildVirtualCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), AppTheme.kTextPrimary],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                CupertinoIcons.creditcard,
                color: Colors.white54,
                size: 32,
              ),
              Text(
                _selectedBankName ?? 'STAYHUB BANK',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _accountNumberCtrl.text.isEmpty
                ? '•••• •••• •••• ••••'
                : _accountNumberCtrl.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHỦ TÀI KHOẢN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _accountNameCtrl.text.isEmpty
                        ? 'TÊN CỦA BẠN'
                        : _accountNameCtrl.text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const Icon(
                CupertinoIcons.checkmark_seal_fill,
                color: AppTheme.kBrandLight,
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
