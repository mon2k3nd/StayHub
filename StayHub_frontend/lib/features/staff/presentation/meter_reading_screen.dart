import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/providers/core_providers.dart';
import 'widgets/ai_ocr_scanner_modal.dart';
import 'dart:async' show unawaited;

class MeterReadingScreen extends ConsumerStatefulWidget {
  final int roomId;

  const MeterReadingScreen({super.key, required this.roomId});

  @override
  ConsumerState<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends ConsumerState<MeterReadingScreen> {
  final _electricController = TextEditingController();
  final _waterController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _electricController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _submitReading() async {
    final eVal = double.tryParse(_electricController.text.trim());
    final wVal = double.tryParse(_waterController.text.trim());

    if (eVal == null || wVal == null) {
      _showDialog('Lỗi', 'Vui lòng nhập số hợp lệ.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);

      await client.put(
        '/v1/bills/room/${widget.roomId}/utilities',
        data: {'electricCurrent': eVal, 'waterCurrent': wVal},
      );

      if (mounted) {
        _showDialog(
          'Thành công',
          'Đã chốt số điện nước tháng này!',
          popOnOk: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showDialog('Lỗi', 'Không thể chốt số: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDialog(String title, String content, {bool popOnOk = false}) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.pop(ctx);
                if (popOnOk) {
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Ghi Điện Nước P.${widget.roomId}',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.clear_circled_solid,
          color: CupertinoColors.black,
          size: 28,
        ),
        onPressed: () => context.pop(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(
              title: 'SỐ ĐIỆN MỚI (kWh)',
              controller: _electricController,
              icon: CupertinoIcons.bolt_fill,
              imagePath: 'assets/images/features/ocr_meter.png',
              color: CupertinoColors.systemYellow,
              placeholder: 'Ví dụ: 1450',
            ),
            const SizedBox(height: 24),
            _buildInputSection(
              title: 'SỐ NƯỚC MỚI (m³)',
              controller: _waterController,
              icon: CupertinoIcons.drop_fill,
              imagePath: 'assets/images/features/utilities_dashboard.png',
              color: CupertinoColors.systemTeal,
              placeholder: 'Ví dụ: 120',
            ),
            const SizedBox(height: 32),

            // Upload Image
            const Text(
              'ẢNH CHỤP ĐỒNG HỒ',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      color: LiquidGlassColors.staffAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đính kèm ảnh',
                          style: TextStyle(
                            color: CupertinoColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Minh chứng chốt số',
                          style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            _isLoading
                ? const Center(child: CupertinoActivityIndicator(radius: 16))
                : GlassButton(
                    text: 'Chốt Số Tháng Này',
                    icon: CupertinoIcons.check_mark_circled_solid,
                    color: LiquidGlassColors.staffAccent,
                    onPressed: _submitReading,
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    String? imagePath,
    required Color color,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (imagePath != null)
                  Image.asset(
                    imagePath,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, color: color, size: 18),
                  )
                else
                  Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                final value = await AiOcrScannerModal.show(
                  context,
                  title: 'Quét $title',
                );
                if (value != null && mounted) {
                  controller.text = value.toStringAsFixed(0);
                }
              },
              minimumSize: const Size(0, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      CupertinoIcons.camera_viewfinder,
                      color: AppTheme.kAccentColor,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Quét AI',
                      style: TextStyle(
                        color: AppTheme.kAccentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CupertinoTextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          placeholder: placeholder,
          placeholderStyle: const TextStyle(color: Color(0xFF4B5563)),
          style: const TextStyle(
            color: CupertinoColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
        ),
      ],
    );
  }
}
