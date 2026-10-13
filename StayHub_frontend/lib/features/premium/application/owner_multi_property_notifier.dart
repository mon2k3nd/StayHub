import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class PropertyBuilding {
  final String id;
  final String name;
  final String address;
  final int totalRooms;
  final int occupiedRooms;
  final double monthlyRevenue;
  final String status;

  const PropertyBuilding({
    required this.id,
    required this.name,
    required this.address,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.monthlyRevenue,
    this.status = 'Hoạt động',
  });
}

class MultiPropertyState {
  final bool isLoading;
  final List<PropertyBuilding> buildings;
  final double totalPortfolioRevenue;

  const MultiPropertyState({
    this.isLoading = false,
    this.buildings = const [],
    this.totalPortfolioRevenue = 0.0,
  });

  MultiPropertyState copyWith({
    bool? isLoading,
    List<PropertyBuilding>? buildings,
    double? totalPortfolioRevenue,
  }) {
    return MultiPropertyState(
      isLoading: isLoading ?? this.isLoading,
      buildings: buildings ?? this.buildings,
      totalPortfolioRevenue:
          totalPortfolioRevenue ?? this.totalPortfolioRevenue,
    );
  }
}

class MultiPropertyNotifier extends Notifier<MultiPropertyState> {
  @override
  build() {
    unawaited(Future.microtask(_loadBuildings));
    return const MultiPropertyState();
  }

  Future<void> _loadBuildings() async {
    state = state.copyWith(isLoading: true);

    // Simulate backend fetch
    await Future.delayed(const Duration(milliseconds: 1200));

    final mockBuildings = [
      const PropertyBuilding(
        id: 'b1',
        name: 'StayHub Central',
        address: '123 Nguyễn Văn Linh, Q.7',
        totalRooms: 45,
        occupiedRooms: 42,
        monthlyRevenue: 185000000,
      ),
      const PropertyBuilding(
        id: 'b2',
        name: 'StayHub Riverside',
        address: '45 Tôn Thất Thuyết, Q.4',
        totalRooms: 30,
        occupiedRooms: 30,
        monthlyRevenue: 120000000,
        status: 'Kín phòng',
      ),
      const PropertyBuilding(
        id: 'b3',
        name: 'StayHub Campus',
        address: 'Khu Làng Đại Học, Thủ Đức',
        totalRooms: 60,
        occupiedRooms: 48,
        monthlyRevenue: 150000000,
      ),
    ];

    double totalRevenue = mockBuildings.fold(
      0,
      (sum, b) => sum + b.monthlyRevenue,
    );

    // if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      buildings: mockBuildings,
      totalPortfolioRevenue: totalRevenue,
    );
  }
}

final multiPropertyProvider =
    NotifierProvider<MultiPropertyNotifier, MultiPropertyState>(
      MultiPropertyNotifier.new,
    );
