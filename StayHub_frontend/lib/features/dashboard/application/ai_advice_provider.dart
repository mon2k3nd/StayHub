import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/core_providers.dart';

final aiAdviceProvider = FutureProvider.autoDispose<String>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return '## ⚠️ Lỗi\nNgười dùng chưa đăng nhập.';

  try {
    final api = ref.watch(apiClientProvider);
    final now = DateTime.now();
    final res = await api.get(
      '/v1/ai/financial-advice/${user.id}?month=${now.month}&year=${now.year}',
    );
    if (res['success'] == true) {
      // BUGFIX (data): `data` có thể null/không phải String → tránh TypeError.
      return res['data']?.toString() ?? '';
    }
    return '## ⚠️ Lỗi\nKhông có dữ liệu phản hồi từ AI.';
  } catch (e) {
    return '## ⚠️ Lỗi\nKhông thể tải phân tích. Vui lòng thử lại sau.';
  }
});
