import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/responsive_file_image.dart';

class AiOcrScannerModal extends StatefulWidget {
  final String title;

  const AiOcrScannerModal({super.key, required this.title});

  static Future<double?> show(BuildContext context, {required String title}) {
    return showCupertinoModalPopup<double>(
      context: context,
      builder: (ctx) => AiOcrScannerModal(title: title),
    );
  }

  @override
  State<AiOcrScannerModal> createState() => _AiOcrScannerModalState();
}

class _AiOcrScannerModalState extends State<AiOcrScannerModal> {
  String _statusText = 'Chọn phương thức ảnh';
  bool _isProcessing = false;
  XFile? _imageFile;

  Future<void> _pickAndProcessImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _imageFile = image;
        _isProcessing = true;
        _statusText = 'AI đang phân tích chỉ số...';
      });

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      // Tìm số từ 3 đến 6 chữ số
      final regex = RegExp(r'\b\d{3,6}\b');
      final match = regex.firstMatch(recognizedText.text);

      await textRecognizer.close();

      if (match != null) {
        final result = double.tryParse(match.group(0)!);
        if (result != null && mounted) {
          Navigator.pop(context, result);
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Không tìm thấy số, vui lòng thử lại';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Lỗi xử lý ảnh';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: CupertinoColors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Opacity(
                opacity: _imageFile == null ? 0.4 : 1.0,
                child: Container(
                  color: CupertinoColors.darkBackgroundGray,
                  child: _imageFile != null
                      ? ResponsiveFileImage(
                          File(_imageFile!.path),
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            CupertinoIcons.camera_viewfinder,
                            size: 150,
                            color: CupertinoColors.white.withValues(alpha: 0.2),
                          ),
                        ),
                ),
              ),
            ),

            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.black.withValues(alpha: 0.6),
                ),
              ),

            // Info text and buttons
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: CupertinoActivityIndicator(
                            color: AppTheme.kAccentColor,
                          ),
                        ),
                      Text(
                        _statusText,
                        style: TextStyle(
                          color: _isProcessing
                              ? AppTheme.kAccentColor
                              : CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  if (!_isProcessing)
                    Column(
                      children: [
                        CupertinoButton(
                          color: AppTheme.kAccentColor,
                          borderRadius: BorderRadius.circular(12),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.camera,
                                color: CupertinoColors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Chụp ảnh ngay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () =>
                              _pickAndProcessImage(ImageSource.camera),
                        ),
                        const SizedBox(height: 12),
                        CupertinoButton(
                          color: CupertinoColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.photo,
                                color: CupertinoColors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Chọn từ thư viện',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () =>
                              _pickAndProcessImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Close Button
            Positioned(
              top: 20,
              right: 20,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
