import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:async' show unawaited;

class ContractViewerScreen extends StatefulWidget {
  final String contractId;
  const ContractViewerScreen({super.key, required this.contractId});

  @override
  State<ContractViewerScreen> createState() => _ContractViewerScreenState();
}

class _ContractViewerScreenState extends State<ContractViewerScreen> {
  List<Offset?> _points = [];
  bool _isSigned = false;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenProtector.preventScreenshotOn());
    unawaited(
      ScreenProtector.protectDataLeakageOn(),
    ); // Protect from screen recording
  }

  @override
  void dispose() {
    unawaited(ScreenProtector.preventScreenshotOff());
    unawaited(ScreenProtector.protectDataLeakageWithColorOff());
    super.dispose();
  }

  void _showSignaturePad() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          List<Offset?> currentPoints = [];
          return StatefulBuilder(
            builder: (context, setStateModal) {
              return Container(
                height: 400,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                ),
                              ),
                            ),
                            const Text(
                              'Ký Tên Điện Tử',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (currentPoints.isNotEmpty) {
                                  setState(() {
                                    _points = currentPoints;
                                    _isSigned = true;
                                  });
                                }
                                Navigator.pop(ctx);
                              },
                              child: const Text(
                                'Xác nhận',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.trash,
                                  size: 16,
                                  color: CupertinoColors.systemRed,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Xóa chữ ký',
                                  style: TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () {
                              setStateModal(() => currentPoints.clear());
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: CupertinoColors.systemGrey4,
                            ),
                          ),
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setStateModal(() {
                                RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                currentPoints.add(
                                  renderBox.globalToLocal(
                                        details.globalPosition,
                                      ) -
                                      const Offset(16, 120),
                                ); // Adjust offset for container padding
                              });
                            },
                            onPanEnd: (details) {
                              setStateModal(() {
                                currentPoints.add(null);
                              });
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CustomPaint(
                                painter: SignaturePainter(currentPoints),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    return LiquidGlassScaffold(
      title: 'Hợp Đồng ${widget.contractId}',
      backgroundColors: AppTheme.kBackgroundLight,
      child: Column(
        children: [
          // Contract Document
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8), // Paper sharp corners
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\nĐộc lập - Tự do - Hạnh phúc',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.5,
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'HỢP ĐỒNG THUÊ PHÒNG TRỌ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildContractSection(
                  'Điều 1: Thông tin các bên',
                  'Bên A (Bên cho thuê): Công ty StayHub\nBên B (Bên thuê): Nguyễn Văn A\nCùng thỏa thuận ký kết hợp đồng thuê phòng với các điều khoản sau.',
                ),
                _buildContractSection(
                  'Điều 2: Đối tượng hợp đồng',
                  'Bên A đồng ý cho Bên B thuê phòng P.101, Chi nhánh Quận 1. Mục đích sử dụng: Để ở.',
                ),
                _buildContractSection(
                  'Điều 3: Giá thuê và phương thức thanh toán',
                  'Giá thuê: 5,000,000 VNĐ/tháng.\nTiền cọc: 5,000,000 VNĐ.\nThanh toán vào ngày 01 đến 05 hàng tháng.',
                ),
                const SizedBox(height: 40),
                // Signature area
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'ĐẠI DIỆN BÊN A',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/4/41/Signature_of_John_Hancock.svg',
                            height: 60,
                            color: CupertinoColors.systemRed,
                          ),
                          const Text(
                            'StayHub Manager',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'ĐẠI DIỆN BÊN B',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isSigned)
                            Container(
                              height: 80,
                              width: double.infinity,
                              color: Colors.transparent,
                              child: CustomPaint(
                                painter: SignaturePainter(_points),
                              ),
                            )
                          else
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: AppTheme.kAccentColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              onPressed: _showSignaturePad,
                              child: const Text(
                                'Bấm để ký tên',
                                style: TextStyle(
                                  color: AppTheme.kAccentColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nguyễn Văn A',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Actions
          if (_isSigned)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoButton(
                color: CupertinoColors.systemGreen,
                borderRadius: BorderRadius.circular(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: CupertinoColors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Hoàn tất Hợp Đồng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  context.pop();
                  // Show success
                },
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContractSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = CupertinoColors.systemBlue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
