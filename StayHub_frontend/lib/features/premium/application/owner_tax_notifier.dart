import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class TaxPeriod {
  final String id;
  final String periodName; // e.g. "Quý 2/2026"
  final double totalRevenue;
  final double deductibleExpenses;
  final double taxableIncome;
  final double estimatedTax;
  final String status; // 'Chưa nộp', 'Đã nộp'
  final DateTime deadline;

  const TaxPeriod({
    required this.id,
    required this.periodName,
    required this.totalRevenue,
    required this.deductibleExpenses,
    required this.taxableIncome,
    required this.estimatedTax,
    this.status = 'Chưa nộp',
    required this.deadline,
  });

  TaxPeriod copyWith({String? status}) {
    return TaxPeriod(
      id: id,
      periodName: periodName,
      totalRevenue: totalRevenue,
      deductibleExpenses: deductibleExpenses,
      taxableIncome: taxableIncome,
      estimatedTax: estimatedTax,
      status: status ?? this.status,
      deadline: deadline,
    );
  }
}

class TaxState {
  final bool isLoading;
  final bool isGenerating;
  final List<TaxPeriod> taxPeriods;

  const TaxState({
    this.isLoading = false,
    this.isGenerating = false,
    this.taxPeriods = const [],
  });

  TaxState copyWith({
    bool? isLoading,
    bool? isGenerating,
    List<TaxPeriod>? taxPeriods,
  }) {
    return TaxState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      taxPeriods: taxPeriods ?? this.taxPeriods,
    );
  }
}

class TaxNotifier extends Notifier<TaxState> {
  @override
  build() {
    unawaited(Future.microtask(_loadTaxes));
    return const TaxState();
  }

  Future<void> _loadTaxes() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final mockTaxes = [
      TaxPeriod(
        id: 't1',
        periodName: 'Quý 2/2026',
        totalRevenue: 450000000,
        deductibleExpenses: 50000000,
        taxableIncome: 400000000,
        estimatedTax: 40000000, // 10% tax for example
        deadline: DateTime(2026, 7, 30),
      ),
      TaxPeriod(
        id: 't2',
        periodName: 'Quý 1/2026',
        totalRevenue: 420000000,
        deductibleExpenses: 45000000,
        taxableIncome: 375000000,
        estimatedTax: 37500000,
        deadline: DateTime(2026, 4, 30),
        status: 'Đã nộp',
      ),
    ];

    // if (!mounted) return;
    state = state.copyWith(isLoading: false, taxPeriods: mockTaxes);
  }

  Future<void> generateTaxReport(String id) async {
    state = state.copyWith(isGenerating: true);

    // Simulate AI tax optimization and PDF generation
    await Future.delayed(const Duration(seconds: 2));

    // Typically we'd return a File or URL to a PDF here
    // if (!mounted) return;
    state = state.copyWith(isGenerating: false);
  }

  void markAsPaid(String id) {
    final idx = state.taxPeriods.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final updatedList = List<TaxPeriod>.from(state.taxPeriods);
    updatedList[idx] = updatedList[idx].copyWith(status: 'Đã nộp');
    state = state.copyWith(taxPeriods: updatedList);
  }
}

final taxProvider = NotifierProvider<TaxNotifier, TaxState>(TaxNotifier.new);
