import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/toast_utils.dart';
import 'package:dio/dio.dart';
import '../../../core/components/responsive_file_image.dart';

class AiReceiptScannerScreen extends ConsumerStatefulWidget {
  final int billId;
  const AiReceiptScannerScreen({super.key, required this.billId});

  @override
  ConsumerState<AiReceiptScannerScreen> createState() =>
      _AiReceiptScannerScreenState();
}

class _AiReceiptScannerScreenState extends ConsumerState<AiReceiptScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanController;

  bool _isScanning = false;
  bool _isSuccess = false;
  XFile? _imageFile;

  String _extractedAmount = '';
  String _extractedContent = '';

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _onUpload() async {
    final ImagePicker picker = ImagePicker();
    final action = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Chọn ảnh biên lai'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Chụp ảnh'),
            onPressed: () {
              Navigator.pop(context, ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Chọn từ thư viện'),
            onPressed: () {
              Navigator.pop(context, ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
      ),
    );

    if (action != null) {
      final XFile? image = await picker.pickImage(source: action);
      if (image != null) {
        setState(() {
          _imageFile = image;
          _isScanning = true;
          _isSuccess = false;
          _extractedAmount = '';
          _extractedContent = '';
        });

        unawaited(_scanController.repeat(reverse: true));

        try {
          final textRecognizer = TextRecognizer();
          final inputImage = InputImage.fromFilePath(image.path);
          final recognizedText = await textRecognizer.processImage(inputImage);

          String foundAmount = '';
          // Tìm các chuỗi giống số tiền, vd 1.000.000 hoặc 1,000,000 hoặc 1000000
          final amountRegex = RegExp(
            r'\b(\d{1,3}(?:[.,]\d{3})+)\b|\b(\d{5,9})\b',
          );

          for (TextBlock block in recognizedText.blocks) {
            final text = block.text;
            final match = amountRegex.firstMatch(text);
            if (match != null) {
              foundAmount = match.group(1) ?? match.group(2) ?? '';
              if (foundAmount.isNotEmpty) break;
            }
          }

          await textRecognizer.close();

          setState(() {
            _extractedAmount = foundAmount.isNotEmpty
                ? '$foundAmount VND'
                : 'Không tìm thấy số tiền';
            _extractedContent = recognizedText.text;
          });
        } catch (e) {
          setState(() {
            _extractedAmount = 'Lỗi phân tích';
          });
        }

        _scanController.stop();
        setState(() {
          _isScanning = false;
          _isSuccess = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0F172A),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF0F172A),
        middle: Text(
          'AI Receipt Scanner',
          style: TextStyle(color: CupertinoColors.white),
        ),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Xác nhận thanh toán tự động',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tải lên ảnh chụp màn hình chuyển khoản. AI sẽ tự động đọc biên lai và gạch nợ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
            ),
            const SizedBox(height: 40),

            // Scanner Area
            Expanded(
              child: Center(
                child: _imageFile != null
                    ? _buildScanningArea()
                    : _buildUploadPlaceholder(),
              ),
            ),

            const SizedBox(height: 30),

            // Status and Button
            if (_imageFile == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: CupertinoButton(
                  color: AppTheme.kAccentColor,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: _onUpload,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Text(
                      'Tải ảnh Biên lai',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            else if (_isSuccess)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: CupertinoColors.systemGreen,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Quét thành công!',
                          style: TextStyle(
                            color: CupertinoColors.systemGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CupertinoButton(
                      color: AppTheme.kAccentColor,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () async {
                        // Call backend to update bill
                        if (widget.billId > 0 && _imageFile != null) {
                          try {
                            final dio = ref.read(dioProvider);
                            final formData = FormData.fromMap({
                              'file': await MultipartFile.fromFile(
                                _imageFile!.path,
                                filename: 'receipt.jpg',
                              ),
                            });
                            await dio.post(
                              '/v1/bills//scan-receipt',
                              data: formData,
                            );
                            if (!context.mounted) return;
                            ToastUtils.show(
                              context,
                              'Thanh toán thành công qua AI!',
                            );
                            context.pop(true);
                          } catch (e) {
                            if (!context.mounted) return;
                            ToastUtils.show(
                              context,
                              'Lỗi cập nhật: ',
                              isError: true,
                            );
                          }
                        } else {
                          context.pop(true);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: const Text(
                          'Xác nhận Thanh toán',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _onUpload,
                      child: const Text(
                        'Tải ảnh khác',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(color: CupertinoColors.white),
                    SizedBox(width: 12),
                    Text(
                      'AI đang bóc tách dữ liệu...',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return GestureDetector(
      onTap: _onUpload,
      child: Container(
        width: 280,
        height: 420,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.2),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              color: CupertinoColors.systemGrey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Chạm để tải ảnh',
              style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningArea() {
    return Container(
      width: 280,
      height: 420,
      decoration: BoxDecoration(
        color: CupertinoColors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _isSuccess
            ? [
                const BoxShadow(
                  color: CupertinoColors.systemGreen,
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_imageFile != null)
            ResponsiveFileImage(File(_imageFile!.path), fit: BoxFit.cover),

          if (_isSuccess)
            Container(color: CupertinoColors.black.withValues(alpha: 0.7)),

          if (_isSuccess)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(
                    child: Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: CupertinoColors.systemGreen,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'KẾT QUẢ ĐỌC',
                      style: TextStyle(
                        color: CupertinoColors.systemGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Số tiền (ước tính)',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _extractedAmount,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nội dung nhận diện',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _extractedContent,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Laser Scanner line
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return Positioned(
                  top: _scanController.value * 400,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        color: const Color(0xFF10B981), // Emerald green
                        width: double.infinity,
                      ),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.4),
                              const Color(0xFF10B981).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Success Overlay flash
          if (_isSuccess)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 0.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, val, child) {
                return Container(color: Colors.white.withValues(alpha: val));
              },
            ),
        ],
      ),
    );
  }
}
