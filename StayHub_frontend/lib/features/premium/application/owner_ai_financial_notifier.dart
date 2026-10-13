import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

class AiFinancialState {
  final bool isAnalyzing;
  final List<double> revenueData;
  final List<double> projectedRevenueData;
  final List<String> aiInsights;
  final double currentMonthRevenue;
  final double projectedGrowth;
  final String? error;

  const AiFinancialState({
    this.isAnalyzing = true,
    this.revenueData = const [],
    this.projectedRevenueData = const [],
    this.aiInsights = const [],
    this.currentMonthRevenue = 0.0,
    this.projectedGrowth = 0.0,
    this.error,
  });

  AiFinancialState copyWith({
    bool? isAnalyzing,
    List<double>? revenueData,
    List<double>? projectedRevenueData,
    List<String>? aiInsights,
    double? currentMonthRevenue,
    double? projectedGrowth,
    String? error,
  }) {
    return AiFinancialState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      revenueData: revenueData ?? this.revenueData,
      projectedRevenueData: projectedRevenueData ?? this.projectedRevenueData,
      aiInsights: aiInsights ?? this.aiInsights,
      currentMonthRevenue: currentMonthRevenue ?? this.currentMonthRevenue,
      projectedGrowth: projectedGrowth ?? this.projectedGrowth,
      error: error ?? this.error,
    );
  }
}

class AiFinancialNotifier extends Notifier<AiFinancialState> {
  @override
  build() {
    unawaited(_startAnalysis());
    return const AiFinancialState();
  }

  Future<void> _startAnalysis() async {
    state = state.copyWith(isAnalyzing: true);

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        '/api/v1/ai/financial-advice/1',
      ); // mock ownerId = 1

      final body = res.data;
      if (res.statusCode == 200 && body is Map && body['success'] == true) {
        // BUGFIX (data): `data` có thể null/không phải String → tránh TypeError.
        final advice = body['data']?.toString() ?? '';

        // Simulated AI Backend Data for Chart
        final pastRevenue = [120.0, 135.0, 130.0, 150.0, 160.0, 158.0];
        final projectedRevenue = [158.0, 165.0, 172.0, 180.0];

        // Combine API response with mock graph data
        final insights = [
          advice,
          "Tối ưu chi phí: Chi phí điện năng tháng qua tăng 20% do nắng nóng.",
        ];

        state = state.copyWith(
          isAnalyzing: false,
          revenueData: pastRevenue,
          projectedRevenueData: projectedRevenue,
          aiInsights: insights,
          currentMonthRevenue: 158000000.0,
          projectedGrowth: 12.5,
          error: null,
        );
      } else {
        throw Exception("Lỗi API");
      }
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: e.toString());
    }
  }

  void refreshAnalysis() {
    state = state.copyWith(isAnalyzing: true);
    unawaited(_startAnalysis());
  }
}

final aiFinancialProvider =
    NotifierProvider<AiFinancialNotifier, AiFinancialState>(
      AiFinancialNotifier.new,
    );
