import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/datasources/expense_remote_data_source.dart';

class ExpenseItem {
  final int id;
  final String title;
  final double amount;
  final String category; // 'Bảo trì', 'Điện nước', 'Lương thưởng', 'Khác'
  final DateTime date;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  // BUGFIX (data): coerce an toàn — tránh TypeError khi backend trả String/null.
  static int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    final rawDate = json['expenseDate'];
    return ExpenseItem(
      id: _toInt(json['id']),
      title: json['description']?.toString() ?? 'Chi phí',
      amount: _toDouble(json['amount']),
      category: json['category']?.toString() ?? 'Khác',
      date: rawDate != null
          ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

final expenseDataSourceProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return ExpenseRemoteDataSource(dio.dio);
});

class ExpenseNotifier extends AsyncNotifier<List<ExpenseItem>> {
  @override
  FutureOr<List<ExpenseItem>> build() async {
    final ds = ref.watch(expenseDataSourceProvider);
    final data = await ds.getExpenses();
    return data.map((e) => ExpenseItem.fromJson(e)).toList();
  }

  Future<void> addExpense(String title, double amount, String category) async {
    final ds = ref.read(expenseDataSourceProvider);

    // Create new expense via API
    await ds.createExpense({
      'description': title,
      'amount': amount,
      'category': category,
      'expenseDate': DateTime.now().toIso8601String().substring(0, 10),
    });

    // Refresh list from server
    ref.invalidateSelf();
  }
}

final expenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<ExpenseItem>>(
      () => ExpenseNotifier(),
    );

final totalExpenseProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  return expenses.fold(0.0, (sum, item) => sum + item.amount);
});
