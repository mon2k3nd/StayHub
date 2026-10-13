import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

class CreateStaffScreen extends ConsumerStatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  ConsumerState<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends ConsumerState<CreateStaffScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _selectedRole = 0; // 0 = Staff, 1 = Manager

  late AnimationController _btnAnimCtrl;
  late Animation<double> _btnScaleAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _btnAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _btnScaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnAnimCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _btnAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Tạo tài khoản Nhân viên',
      backgroundColors: AppTheme.kBackgroundLight,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm nhân sự mới',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cấp quyền truy cập hệ thống quản lý cho nhân viên hoặc quản lý chi nhánh.',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
            ),
            const SizedBox(height: 32),

            _buildInput(
              controller: _nameCtrl,
              placeholder: 'Họ và Tên',
              icon: CupertinoIcons.person_fill,
            ),
            const SizedBox(height: 16),
            _buildInput(
              controller: _emailCtrl,
              placeholder: 'Email đăng nhập',
              icon: CupertinoIcons.mail_solid,
            ),
            const SizedBox(height: 16),
            _buildInput(
              controller: _phoneCtrl,
              placeholder: 'Số điện thoại',
              icon: CupertinoIcons.phone_fill,
            ),
            const SizedBox(height: 24),

            const Text(
              'Vai trò',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedRole,
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Nhân viên'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Quản lý'),
                ),
              },
              onValueChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
            ),
            const SizedBox(height: 48),

            GestureDetector(
              onTapDown: (_) => _btnAnimCtrl.forward(),
              onTapUp: (_) {
                unawaited(_btnAnimCtrl.reverse());
                unawaited(_submit());
              },
              onTapCancel: () => _btnAnimCtrl.reverse(),
              child: ScaleTransition(
                scale: _btnScaleAnim,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.kBrand,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kBrand.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Tạo Tài Khoản',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w400,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(icon, color: AppTheme.kBrand, size: 20),
        ),
        decoration: null,
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty) {
      _showDialog('Lỗi', 'Vui lòng nhập đầy đủ thông tin.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        throw Exception("Chưa đăng nhập");
      }

      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/v1/staff/create',
        data: {
          "name": _nameCtrl.text.trim(),
          "phoneNumber": _phoneCtrl.text.trim(),
          "password": "123", // Mật khẩu mặc định hoặc gửi email
          "ownerId": user.id,
          "branchIds": [], // Chọn dãy trọ sau
        },
      );

      if (res['success'] == true) {
        _showDialog(
          'Thành công',
          'Tài khoản nhân viên đã được tạo thành công!',
          onSuccess: () {
            if (mounted) context.pop();
          },
        );
      } else {
        _showDialog('Thất bại', res['message'] ?? 'Có lỗi xảy ra');
      }
    } catch (e) {
      _showDialog('Lỗi', 'Không thể tạo tài khoản nhân viên. $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDialog(String title, String message, {VoidCallback? onSuccess}) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.pop(ctx);
                onSuccess?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
