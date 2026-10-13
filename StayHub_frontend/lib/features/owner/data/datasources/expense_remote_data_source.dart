import 'package:dio/dio.dart';

class ExpenseRemoteDataSource {
  final Dio dio;

  ExpenseRemoteDataSource(this.dio);

  Future<List<dynamic>> getExpenses({int? month, int? year}) async {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    if (year != null) query['year'] = year;

    final response = await dio.get('/v1/expenses', queryParameters: query);
    // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
    // null/không phải List.
    final raw = response.data is Map ? response.data['data'] : null;
    return raw is List ? raw : const <dynamic>[];
  }

  Future<dynamic> createExpense(Map<String, dynamic> expenseData) async {
    final response = await dio.post('/v1/expenses', data: expenseData);
    return response.data['data'];
  }

  Future<dynamic> updateExpense(
    int id,
    Map<String, dynamic> expenseData,
  ) async {
    final response = await dio.put('/v1/expenses/$id', data: expenseData);
    return response.data['data'];
  }

  Future<void> deleteExpense(int id) async {
    await dio.delete('/v1/expenses/$id');
  }
}
