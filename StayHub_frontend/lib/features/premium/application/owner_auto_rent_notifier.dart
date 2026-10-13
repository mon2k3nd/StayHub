import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

class AutoRentState {
  final bool isLoading;
  final bool isCollecting;
  final double collectionProgress;
  final int totalAmountCollected;
  final List<Map<String, dynamic>> tenantInvoices;
  final String? error;

  const AutoRentState({
    this.isLoading = false,
    this.isCollecting = false,
    this.collectionProgress = 0.0,
    this.totalAmountCollected = 0,
    this.tenantInvoices = const [],
    this.error,
  });

  AutoRentState copyWith({
    bool? isLoading,
    bool? isCollecting,
    double? collectionProgress,
    int? totalAmountCollected,
    List<Map<String, dynamic>>? tenantInvoices,
    String? error,
  }) {
    return AutoRentState(
      isLoading: isLoading ?? this.isLoading,
      isCollecting: isCollecting ?? this.isCollecting,
      collectionProgress: collectionProgress ?? this.collectionProgress,
      totalAmountCollected: totalAmountCollected ?? this.totalAmountCollected,
      tenantInvoices: tenantInvoices ?? this.tenantInvoices,
      error: error,
    );
  }
}

class AutoRentNotifier extends Notifier<AutoRentState> {
  @override
  build() {
    unawaited(_loadInitialData());
    return const AutoRentState();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      // Giả sử API trả về hóa đơn cho auto rent collection
      final res = await dio.get('/api/v1/auto-rent/1'); // mock ownerId = 1
      if (res.statusCode == 200 && res.data['success'] == true) {
        // Parse data
        // Hiện tại chỉ fetch mock danh sách hoá đơn vì server chỉ trả về status AutoRent
        // Trong dự án thực tế, ta sẽ gọi API get danh sách bills
        final mockInvoices = [
          {
            'room': 'P101',
            'tenant': 'Nguyễn Văn A',
            'amount': 4500000,
            'status': 'Chờ thu',
            'selected': true,
          },
          {
            'room': 'P102',
            'tenant': 'Trần Thị B',
            'amount': 3800000,
            'status': 'Chờ thu',
            'selected': true,
          },
          {
            'room': 'P201',
            'tenant': 'Lê Văn C',
            'amount': 5000000,
            'status': 'Đã nộp',
            'selected': false,
          },
        ];
        state = state.copyWith(isLoading: false, tenantInvoices: mockInvoices);
      } else {
        throw Exception("Failed to load");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleSelection(int index) {
    if (state.isCollecting) return;

    final updated = List<Map<String, dynamic>>.from(state.tenantInvoices);
    if (updated[index]['status'] == 'Chờ thu') {
      // BUGFIX (data): tránh `as bool` ném TypeError khi `selected` null/khác.
      final current = updated[index]['selected'];
      updated[index]['selected'] = !(current is bool ? current : false);
      state = state.copyWith(tenantInvoices: updated);
    }
  }

  void selectAll(bool select) {
    if (state.isCollecting) return;
    final updated = state.tenantInvoices.map((inv) {
      if (inv['status'] == 'Chờ thu') {
        return {...inv, 'selected': select};
      }
      return inv;
    }).toList();
    state = state.copyWith(tenantInvoices: updated);
  }

  Future<void> startAutoCollection() async {
    final toCollect = state.tenantInvoices
        .where((inv) => inv['selected'] == true && inv['status'] == 'Chờ thu')
        .toList();
    if (toCollect.isEmpty) return;

    state = state.copyWith(isCollecting: true, collectionProgress: 0.0);

    int totalCollected = state.totalAmountCollected;

    for (int i = 0; i < toCollect.length; i++) {
      // Simulate API call for each collection
      await Future.delayed(const Duration(milliseconds: 600));

      final currentInv = toCollect[i];
      // BUGFIX (data): trước đây ép `as int` — nếu amount là double/String
      // thì ném TypeError giữa vòng lặp thu tiền. Coerce an toàn.
      final rawAmt = currentInv['amount'];
      totalCollected += rawAmt is num
          ? rawAmt.toInt()
          : int.tryParse(rawAmt?.toString() ?? '') ?? 0;

      final updatedList = state.tenantInvoices.map((inv) {
        if (inv['room'] == currentInv['room']) {
          return {...inv, 'status': 'Đã nộp', 'selected': false};
        }
        return inv;
      }).toList();

      state = state.copyWith(
        collectionProgress: (i + 1) / toCollect.length,
        totalAmountCollected: totalCollected,
        tenantInvoices: updatedList,
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isCollecting: false, collectionProgress: 1.0);
  }
}

final autoRentProvider = NotifierProvider<AutoRentNotifier, AutoRentState>(
  AutoRentNotifier.new,
);
