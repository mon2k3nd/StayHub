import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class Campaign {
  final String id;
  final String name;
  final String target; // e.g. 'Sinh viên Làng ĐH', 'Người đi làm Quận 7'
  final String status; // 'Đang chạy', 'Đã dừng', 'Chờ duyệt'
  final int reachCount;
  final int clickCount;
  final int conversionCount; // số người inbox/đặt phòng
  final double budget;
  final double spent;

  const Campaign({
    required this.id,
    required this.name,
    required this.target,
    this.status = 'Đang chạy',
    required this.reachCount,
    required this.clickCount,
    required this.conversionCount,
    required this.budget,
    required this.spent,
  });

  double get conversionRate =>
      clickCount > 0 ? (conversionCount / clickCount) * 100 : 0;

  Campaign copyWith({String? status}) {
    return Campaign(
      id: id,
      name: name,
      target: target,
      status: status ?? this.status,
      reachCount: reachCount,
      clickCount: clickCount,
      conversionCount: conversionCount,
      budget: budget,
      spent: spent,
    );
  }
}

class MarketingState {
  final bool isLoading;
  final List<Campaign> campaigns;

  const MarketingState({this.isLoading = false, this.campaigns = const []});

  MarketingState copyWith({bool? isLoading, List<Campaign>? campaigns}) {
    return MarketingState(
      isLoading: isLoading ?? this.isLoading,
      campaigns: campaigns ?? this.campaigns,
    );
  }
}

class MarketingNotifier extends Notifier<MarketingState> {
  @override
  build() {
    unawaited(Future.microtask(_loadCampaigns));
    return const MarketingState();
  }

  Future<void> _loadCampaigns() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final mockCampaigns = [
      const Campaign(
        id: 'c1',
        name: 'Giảm giá tháng 7',
        target: 'Sinh viên năm nhất',
        reachCount: 15400,
        clickCount: 1200,
        conversionCount: 45,
        budget: 5000000,
        spent: 3200000,
      ),
      const Campaign(
        id: 'c2',
        name: 'Phòng cao cấp Quận 7',
        target: 'Nhân viên văn phòng',
        reachCount: 8200,
        clickCount: 410,
        conversionCount: 12,
        budget: 10000000,
        spent: 8500000,
        status: 'Đã dừng',
      ),
    ];

    // if (!mounted) return;
    state = state.copyWith(isLoading: false, campaigns: mockCampaigns);
  }

  void toggleCampaignStatus(String id) {
    final idx = state.campaigns.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    final updated = List<Campaign>.from(state.campaigns);
    final current = updated[idx];

    if (current.status == 'Đang chạy') {
      updated[idx] = current.copyWith(status: 'Đã dừng');
    } else if (current.status == 'Đã dừng') {
      updated[idx] = current.copyWith(status: 'Đang chạy');
    }

    state = state.copyWith(campaigns: updated);
  }
}

final marketingProvider = NotifierProvider<MarketingNotifier, MarketingState>(
  MarketingNotifier.new,
);
