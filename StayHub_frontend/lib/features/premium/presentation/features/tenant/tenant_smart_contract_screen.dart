import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_glass_scaffold.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/tenant_smart_contract_notifier.dart';

class TenantSmartContractScreen extends ConsumerStatefulWidget {
  const TenantSmartContractScreen({super.key});

  @override
  ConsumerState<TenantSmartContractScreen> createState() =>
      _TenantSmartContractScreenState();
}

class _TenantSmartContractScreenState
    extends ConsumerState<TenantSmartContractScreen>
    with TickerProviderStateMixin {
  late AnimationController _sealController;
  late Animation<double> _sealScaleAnimation;
  late Animation<double> _sealOpacityAnimation;
  bool _isSigningProcess = false;
  String _signingStatus = '';

  @override
  void initState() {
    super.initState();
    _sealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sealScaleAnimation = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _sealController, curve: Curves.bounceOut),
    );
    _sealOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sealController, curve: const Interval(0.0, 0.5)),
    );
  }

  @override
  void dispose() {
    _sealController.dispose();
    super.dispose();
  }

  void _handleSignContract(SmartContractNotifier notifier) {
    setState(() {
      _isSigningProcess = true;
      _signingStatus = 'Đang nhận diện FaceID...';
    });

    // Simulate FaceID
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(
          () => _signingStatus = 'Đang ghi vào Blockchain (Mã hóa Hash)...',
        );
        unawaited(HapticFeedback.lightImpact());
      }

      // Simulate Blockchain writing
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          unawaited(notifier.signContract()); // Update state to signed
          unawaited(_sealController.forward());
          unawaited(HapticFeedback.heavyImpact());
          setState(() => _signingStatus = 'Ký kết thành công!');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartContractProvider);
    final notifier = ref.read(smartContractProvider.notifier);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // If already signed before entering, just show the seal without animation
    if (state.isSigned && !_sealController.isCompleted) {
      _sealController.value = 1.0;
    }

    return LiquidGlassScaffold(
      title: 'Hợp Đồng Thông Minh',
      useScrollView: true,
      backgroundColors: AppTheme.kBackgroundLight,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildStatusHeader(state),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                _buildContractDocument(state, formatter),
                if (_isSigningProcess || state.isSigned)
                  Positioned(
                    bottom: 40,
                    right: 40,
                    child: AnimatedBuilder(
                      animation: _sealController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _sealScaleAnimation.value,
                          child: Opacity(
                            opacity: _sealOpacityAnimation.value,
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CupertinoColors.destructiveRed,
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      'ĐÃ KÝ SỐ',
                                      style: TextStyle(
                                        color: CupertinoColors.destructiveRed,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      'BẢO CHỨNG BLOCKCHAIN',
                                      style: TextStyle(
                                        color: CupertinoColors.destructiveRed,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
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
            const SizedBox(height: 32),
            _buildSignAction(state, notifier),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(SmartContractState state) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: state.isSigned
                  ? CupertinoColors.activeGreen
                  : const Color(0xFF298FFF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (state.isSigned
                              ? CupertinoColors.activeGreen
                              : const Color(0xFF298FFF))
                          .withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              state.isSigned
                  ? CupertinoIcons.checkmark_seal_fill
                  : CupertinoIcons.doc_text_search,
              color: CupertinoColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isSigned
                      ? 'Hợp đồng đã có hiệu lực'
                      : 'Đang chờ ký duyệt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bảo chứng chuỗi khối (Blockchain)',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractDocument(
    SmartContractState state,
    NumberFormat formatter,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'MÃ HĐ: ${state.contractId}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Container(height: 1, color: CupertinoColors.systemGrey5),
          ),
          _buildInfoRow('Tài sản thuê:', state.roomName),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Thời hạn:',
            '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Giá thuê:',
            formatter.format(state.monthlyRent),
            isHighlight: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Container(height: 1, color: CupertinoColors.systemGrey5),
          ),
          const Text(
            'Các điều khoản đã được tự động chuẩn hóa theo quy định pháp luật và mã hóa toàn vẹn.',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Hash Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.link,
                  size: 20,
                  color: Color(0xFF5FAEFF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mã Hóa Hash (SHA-256)',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.hashValue,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          color: Color(0xFF5FAEFF),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isHighlight
                ? const Color(0xFF298FFF)
                : CupertinoColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSignAction(
    SmartContractState state,
    SmartContractNotifier notifier,
  ) {
    if (state.isSigned) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: CupertinoColors.activeGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CupertinoColors.activeGreen, width: 2),
        ),
        child: const Center(
          child: Text(
            'Đã Ký Số Thành Công',
            style: TextStyle(
              color: CupertinoColors.activeGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    if (_isSigningProcess) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          children: [
            const CupertinoActivityIndicator(radius: 16),
            const SizedBox(height: 16),
            Text(
              _signingStatus,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF298FFF), Color(0xFF298FFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF298FFF).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 18),
        onPressed: () => _handleSignContract(notifier),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.viewfinder_circle,
              color: CupertinoColors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Ký Hợp Đồng Qua FaceID',
              style: TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
