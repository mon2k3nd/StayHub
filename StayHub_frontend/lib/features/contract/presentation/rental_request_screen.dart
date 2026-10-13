import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/components/slide_to_confirm.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/rental_request_notifier.dart';
import 'dart:async';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';

class RentalRequestScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String roomName;
  final int? branchId;
  final String? branchName;
  final double price;
  final String sessionToken;

  const RentalRequestScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    this.branchId,
    this.branchName,
    required this.price,
    required this.sessionToken,
  });

  @override
  ConsumerState<RentalRequestScreen> createState() =>
      _RentalRequestScreenState();
}

class _RentalRequestScreenState extends ConsumerState<RentalRequestScreen> {
  final _dateFmt = DateFormat('dd/MM/yyyy');

  // Controllers for text fields
  final _nameCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hometownCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _tenantsCtrl = TextEditingController(text: "1");
  final _noteCtrl = TextEditingController();
  DateTime _moveInDate = DateTime.now().add(const Duration(days: 3));

  Timer? _timer;
  int _remainingSeconds = 3600; // 1 Giờ session (3600 giây)
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Load data to controllers
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(rentalRequestProvider.notifier);
      await notifier.initDraft(widget.roomId.toString());

      final user = ref.read(authProvider).value;
      final name = user?.fullName ?? '';
      final cccd = user?.cccdNumber ?? '';
      final phone = user?.phoneNumber ?? '';
      final hometown = user?.hometown ?? '';
      final occupation = user?.occupation ?? '';

      _nameCtrl.text = name;
      _idCardCtrl.text = cccd;
      _phoneCtrl.text = phone;
      _hometownCtrl.text = hometown;
      _occupationCtrl.text = occupation;

      // Auto-fill form data so it's submitted
      notifier.updateFormData('fullName', name);
      notifier.updateFormData('idCardNumber', cccd);
      notifier.updateFormData('phoneNumber', phone);
      notifier.updateFormData('hometown', hometown);
      notifier.updateFormData('occupation', occupation);

      final state = ref.read(rentalRequestProvider);
      if (state.formData.isNotEmpty) {
        _tenantsCtrl.text =
            state.formData['numberOfTenants']?.toString() ?? '1';
        _noteCtrl.text = state.formData['note'] ?? '';
        if (state.formData['moveInDate'] != null) {
          _moveInDate =
              DateTime.tryParse(state.formData['moveInDate']) ?? _moveInDate;
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    if (!mounted) return;
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Hết Thời Gian'),
          content: const Text(
            'Session 1 giờ đã hết hạn. Vui lòng quét lại mã QR.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đồng ý'),
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateForm(String key, dynamic value) {
    ref.read(rentalRequestProvider.notifier).updateFormData(key, value);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameCtrl.dispose();
    _idCardCtrl.dispose();
    _phoneCtrl.dispose();
    _hometownCtrl.dispose();
    _occupationCtrl.dispose();
    _tenantsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate
    if (_nameCtrl.text.isEmpty ||
        _idCardCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin cá nhân bắt buộc');
      return;
    }

    ref
        .read(rentalRequestProvider.notifier)
        .updateFormData('fullName', _nameCtrl.text);
    ref
        .read(rentalRequestProvider.notifier)
        .updateFormData('idCardNumber', _idCardCtrl.text);
    ref
        .read(rentalRequestProvider.notifier)
        .updateFormData('phoneNumber', _phoneCtrl.text);
    ref
        .read(rentalRequestProvider.notifier)
        .updateFormData('hometown', _hometownCtrl.text);
    ref
        .read(rentalRequestProvider.notifier)
        .updateFormData('occupation', _occupationCtrl.text);
    ref
        .read(rentalRequestProvider.notifier)
        .updateFormData(
          'numberOfTenants',
          int.tryParse(_tenantsCtrl.text) ?? 1,
        );
    ref
        .read(rentalRequestProvider.notifier)
        .updateFormData(
          'moveInDate',
          _moveInDate.toIso8601String().substring(0, 10),
        );
    ref
        .read(rentalRequestProvider.notifier)
        .updateFormData('note', _noteCtrl.text);

    try {
      await ref
          .read(rentalRequestProvider.notifier)
          .submitRequest(
            roomId: widget.roomId,
            branchId: widget.branchId,
            moveInDate: _moveInDate.toIso8601String().substring(0, 10),
            note: _noteCtrl.text.trim(),
            sessionToken: widget.sessionToken,
          );

      setState(() => _submitted = true);
    } on Exception catch (e) {
      // Race condition alert handling
      if (e.toString().contains('không còn trống')) {
        if (!mounted) return;
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Phòng Đã Có Người Thuê'),
              content: const Text(
                'Rất tiếc, phòng vừa có người thuê. Thông tin của bạn đã được lưu lại bản nháp để dùng cho phòng khác.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        _showError(e.toString());
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lỗi'),
          content: Text(msg),
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

  void _showDatePicker() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 250,
          color: const Color(0xFF162032),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoButton(
                    child: const Text(
                      'Xong',
                      style: TextStyle(
                        color: AppTheme.kAccentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _moveInDate,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime.now().add(const Duration(days: 90)),
                  onDateTimeChanged: (val) {
                    setState(() => _moveInDate = val);
                    _updateForm(
                      'moveInDate',
                      val.toIso8601String().substring(0, 10),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEkycRequiredView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(
          CupertinoIcons.exclamationmark_shield_fill,
          color: CupertinoColors.systemRed,
          size: 80,
        ),
        const SizedBox(height: 24),
        const Text(
          'Yêu cầu xác thực eKYC',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Để bảo vệ cộng đồng và ngăn chặn lừa đảo, StayHub yêu cầu tất cả khách thuê phải xác thực danh tính (eKYC) trước khi gửi yêu cầu thuê phòng.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF4B5563), height: 1.5),
        ),
        const SizedBox(height: 32),
        GlassButton(
          text: 'Xác thực ngay',
          onPressed: () => context.push('/ekyc-verification'),
          color: const Color(0xFF298FFF),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalRequestProvider);
    final user = ref.watch(authProvider).value;
    final isEkycApproved = user != null && user.kycStatus == 'APPROVED';
    final isDraftSaved = state.lastSavedAt != null;

    return CupertinoPageScaffold(
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text(
                    'Thuê Phòng',
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                  backgroundColor: const Color(0x00000000),
                  border: null,
                  trailing: !_submitted && isEkycApproved
                      ? _buildTimerBadge()
                      : null,
                  leading: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (!isEkycApproved)
                        _buildEkycRequiredView()
                      else if (_submitted)
                        _buildSuccessView()
                      else
                        _buildProgressiveForm(state.currentStep),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
            if (state.isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 20,
                      color: LiquidGlassColors.tenantAccent,
                    ),
                  ),
                ),
              ),
            if (!_submitted && isDraftSaved)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Đã lưu nháp ngầm lúc ${DateFormat('HH:mm:ss').format(state.lastSavedAt!)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressiveForm(int currentStep) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room info summary
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const StayHubLogoIcon(
                  color: LiquidGlassColors.tenantAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomName,
                      style: const TextStyle(
                        color: CupertinoColors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Steps indicator
        Row(
          children: [
            _buildStepIndicator(0, currentStep, 'Cá nhân'),
            _buildStepDivider(),
            _buildStepIndicator(1, currentStep, 'Lưu trú'),
            _buildStepDivider(),
            _buildStepIndicator(2, currentStep, 'Xác nhận'),
          ],
        ),
        const SizedBox(height: 28),

        // Step Content
        if (currentStep == 0) _buildStep0(),
        if (currentStep == 1) _buildStep1(),
        if (currentStep == 2) _buildStep2(),

        const SizedBox(height: 32),

        // Navigation Buttons
        Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: CupertinoButton(
                  color: const Color(0xFFE5E7EB),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () =>
                      ref.read(rentalRequestProvider.notifier).previousStep(),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 16),
            if (currentStep < 2)
              Expanded(
                child: GlassButton(
                  text: 'Tiếp tục',
                  color: LiquidGlassColors.tenantAccent,
                  onPressed: () {
                    if (currentStep == 0 &&
                        (_nameCtrl.text.isEmpty || _idCardCtrl.text.isEmpty)) {
                      _showError('Vui lòng điền đủ thông tin');
                      return;
                    }
                    ref.read(rentalRequestProvider.notifier).nextStep();
                  },
                ),
              ),
            if (currentStep == 2)
              Expanded(
                flex: 2,
                child: SlideToConfirm(
                  text: 'Vuốt để Đặt phòng',
                  activeColor: LiquidGlassColors.tenantAccent,
                  onConfirm: () async {
                    await _submit();
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, int currentStep, String label) {
    final isActive = stepIndex <= currentStep;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? LiquidGlassColors.tenantAccent
                : const Color(0xFFE5E7EB),
          ),
          alignment: Alignment.center,
          child: Text(
            '${stepIndex + 1}',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? LiquidGlassColors.tenantAccent : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 2,
        color: const Color(0xFFE5E7EB),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      children: [
        _buildTextField('Họ và tên', _nameCtrl, 'fullName', readOnly: true),
        const SizedBox(height: 16),
        _buildTextField(
          'Số CCCD/CMND',
          _idCardCtrl,
          'idCardNumber',
          isNumber: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Số điện thoại',
          _phoneCtrl,
          'phoneNumber',
          isNumber: true,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        _buildTextField('Quê quán', _hometownCtrl, 'hometown', readOnly: true),
        const SizedBox(height: 16),
        _buildTextField(
          'Nghề nghiệp',
          _occupationCtrl,
          'occupation',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Số người ở',
          _tenantsCtrl,
          'numberOfTenants',
          isNumber: true,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showDatePicker,
          child: GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar,
                  color: AppTheme.kAccentColor,
                  size: 22,
                ),
                const SizedBox(width: 14),
                const Text(
                  'Ngày dọn vào dự kiến',
                  style: TextStyle(color: CupertinoColors.black, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  _dateFmt.format(_moveInDate),
                  style: const TextStyle(
                    color: AppTheme.kAccentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: CupertinoTextField(
            controller: _noteCtrl,
            maxLines: 4,
            placeholder: 'Ghi chú cho chủ nhà...',
            onChanged: (val) => _updateForm('note', val),
            style: const TextStyle(color: CupertinoColors.black, fontSize: 14),
            decoration: null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    String stateKey, {
    bool isNumber = false,
    bool readOnly = false,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CupertinoTextField(
        controller: ctrl,
        placeholder: label,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: readOnly ? null : (val) => _updateForm(stateKey, val),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: null,
        readOnly: readOnly,
        style: TextStyle(
          color: readOnly ? CupertinoColors.systemGrey : CupertinoColors.black,
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: LiquidGlassColors.tenantAccent,
              size: 72,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Gửi Yêu Cầu Thành Công!',
            style: TextStyle(
              color: CupertinoColors.black,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Yêu cầu thuê phòng của bạn đã được gửi đến Chủ nhà. Vui lòng chờ Chủ nhà xét duyệt trong vòng 24h. Bạn sẽ nhận được thông báo khi yêu cầu được duyệt.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 250,
            child: CupertinoButton(
              color: AppTheme.kAccentColor,
              borderRadius: BorderRadius.circular(14),
              onPressed: () {
                context.go('/tenant-dashboard');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StayHubLogoIcon(color: CupertinoColors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Về trang chủ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBadge() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$minutes:$seconds',
        style: const TextStyle(color: LiquidGlassColors.tenantAccent),
      ),
    );
  }
}
