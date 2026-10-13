import 'package:flutter/material.dart';

class WhatsAppAuthService {
  /// Mô phỏng việc xác thực qua WhatsApp (Option 3).
  /// Trong thực tế, bạn sẽ tích hợp SDK như OTPless hoặc gửi request lên Twilio.
  static Future<String> signIn(BuildContext context) async {
    // Giả lập delay mạng
    await Future.delayed(const Duration(seconds: 1));

    if (!context.mounted) {
      throw Exception('Context not mounted');
    }

    // Hiển thị dialog để giả lập người dùng nhập số điện thoại (từ WhatsApp)
    String? mockPhone = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final phoneCtrl = TextEditingController(text: '0987654321');
        return AlertDialog(
          title: const Text('WhatsApp Login (Mock)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhập số điện thoại đăng ký WhatsApp:'),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: 0987654321',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Huỷ', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, phoneCtrl.text.trim());
              },
              child: const Text('Xác thực'),
            ),
          ],
        );
      },
    );

    if (mockPhone == null || mockPhone.isEmpty) {
      throw Exception('Người dùng đã huỷ (canceled)');
    }

    return mockPhone;
  }
}
