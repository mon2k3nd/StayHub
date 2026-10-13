import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../data/repositories/voucher_repository.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import 'dart:async' show unawaited;

class CreateVoucherScreen extends ConsumerStatefulWidget {
  const CreateVoucherScreen({super.key});

  @override
  ConsumerState<CreateVoucherScreen> createState() =>
      _CreateVoucherScreenState();
}

class _CreateVoucherScreenState extends ConsumerState<CreateVoucherScreen>
    with SingleTickerProviderStateMixin {
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController(text: '1');
  final _usageLimitCtrl = TextEditingController(text: '10');

  String _discountType = 'FIXED_AMOUNT'; // or PERCENTAGE
  bool _applyAllRooms = true;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    unawaited(_animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _monthsCtrl.dispose();
    _usageLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.isEmpty || _valueCtrl.text.isEmpty) {
      ToastUtils.show(
        context,
        'Vui lòng điền đầy đủ thông tin.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(voucherRepositoryProvider);
      final rawValue = _valueCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final val = double.tryParse(rawValue) ?? 0.0;

      final data = {
        'code': _codeCtrl.text.trim().toUpperCase(),
        'discountType': _discountType,
        'discountAmount': _discountType == 'FIXED_AMOUNT' ? val : 0.0,
        'discountPercent': _discountType == 'PERCENTAGE' ? val : 0.0,
        'appliesToTarget': 'RENT_ONLY',
        'scopeType': 'ROOM',
        'applyAllRooms': _applyAllRooms,
        'totalUsageLimit': int.tryParse(_usageLimitCtrl.text) ?? 10,
        'monthsPerTenant': int.tryParse(_monthsCtrl.text) ?? 1,
      };

      await repo.createLandlordVoucher(data);

      if (mounted) {
        ToastUtils.show(context, 'Tạo mã ưu đãi thành công!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Lỗi: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Tạo Mã Ưu Đãi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        previousPageTitle: 'Quay lại',
      ),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Preview Card ──
                _buildPreviewCard(),
                const SizedBox(height: 28),

                // ── Section: Thông tin mã ──
                _sectionHeader(
                  '🎟️ Thông tin mã',
                  'Mã sẽ được gửi cho khách thuê',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _codeCtrl,
                  placeholder: 'VD: TET2026',
                  prefix: const Icon(
                    CupertinoIcons.tag,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  inputType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // ── Section: Loại giảm giá ──
                _sectionHeader(
                  '💰 Loại giảm giá',
                  'Chọn giảm tiền mặt hoặc phần trăm',
                ),
                const SizedBox(height: 12),
                _buildTypeToggle(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _valueCtrl,
                  placeholder: _discountType == 'FIXED_AMOUNT'
                      ? '500000 (VNĐ)'
                      : '10 (%)',
                  prefix: Icon(
                    _discountType == 'FIXED_AMOUNT'
                        ? CupertinoIcons.money_dollar_circle
                        : CupertinoIcons.percent,
                    size: 18,
                    color: const Color(0xFF6B7280),
                  ),
                  inputType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // ── Section: Thiết lập ──
                _sectionHeader(
                  '⚙️ Thiết lập',
                  'Số tháng áp dụng và tổng quota',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _monthsCtrl,
                        placeholder: 'Số tháng',
                        prefix: const Icon(
                          CupertinoIcons.calendar,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        inputType: TextInputType.number,
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _usageLimitCtrl,
                        placeholder: 'Tổng lượt',
                        prefix: const Icon(
                          CupertinoIcons.person_2,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        inputType: TextInputType.number,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const StayHubLogoIcon(size: 20, color: Color(0xFF298FFF)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Áp dụng tất cả phòng',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Không giới hạn theo phòng cụ thể',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _applyAllRooms,
                        activeTrackColor: const Color(0xFF298FFF),
                        onChanged: (v) => setState(() => _applyAllRooms = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // ── Submit Button ──
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppTheme.kAccentColor,
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Tạo Mã Giảm Giá',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
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

  Widget _buildPreviewCard() {
    final code = _codeCtrl.text.isEmpty
        ? 'MAGIAMGIA'
        : _codeCtrl.text.toUpperCase();
    final value = _valueCtrl.text.isEmpty ? '???' : _valueCtrl.text;
    final suffix = _discountType == 'FIXED_AMOUNT' ? 'đ' : '%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF298FFF), Color(0xFF6FA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF298FFF).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.ticket, size: 34, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Giảm $value$suffix',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PREVIEW',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _typeOption('FIXED_AMOUNT', '💵 Tiền mặt'),
          _typeOption('PERCENTAGE', '% Phần trăm'),
        ],
      ),
    );
  }

  Widget _typeOption(String type, String label) {
    final selected = _discountType == type;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: GestureDetector(
          onTap: () => setState(() => _discountType = type),
          behavior: HitTestBehavior.opaque,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: selected
                  ? const Color(0xFF111827)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required Widget prefix,
    required TextInputType inputType,
    required void Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        keyboardType: inputType,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: prefix,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: const BoxDecoration(color: Colors.transparent),
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w500,
        ),
        placeholderStyle: const TextStyle(
          fontSize: 15,
          color: Color(0xFFD1D5DB),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}
