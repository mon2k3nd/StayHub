import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class LeaseRenewal {
  final String id;
  final String tenantName;
  final String roomName;
  final DateTime expireDate;
  final double currentRent;
  final double proposedRent;
  final String status; // 'Sắp hết hạn', 'Đang chờ ký', 'Đã gia hạn'

  const LeaseRenewal({
    required this.id,
    required this.tenantName,
    required this.roomName,
    required this.expireDate,
    required this.currentRent,
    required this.proposedRent,
    this.status = 'Sắp hết hạn',
  });

  LeaseRenewal copyWith({double? proposedRent, String? status}) {
    return LeaseRenewal(
      id: id,
      tenantName: tenantName,
      roomName: roomName,
      expireDate: expireDate,
      currentRent: currentRent,
      proposedRent: proposedRent ?? this.proposedRent,
      status: status ?? this.status,
    );
  }
}

class LeaseRenewalState {
  final bool isLoading;
  final List<LeaseRenewal> leases;

  const LeaseRenewalState({this.isLoading = false, this.leases = const []});

  LeaseRenewalState copyWith({bool? isLoading, List<LeaseRenewal>? leases}) {
    return LeaseRenewalState(
      isLoading: isLoading ?? this.isLoading,
      leases: leases ?? this.leases,
    );
  }
}

class LeaseRenewalNotifier extends Notifier<LeaseRenewalState> {
  @override
  build() {
    unawaited(Future.microtask(_loadLeases));
    return const LeaseRenewalState();
  }

  Future<void> _loadLeases() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final mockLeases = [
      LeaseRenewal(
        id: 'l1',
        tenantName: 'Nguyễn Văn A',
        roomName: 'P101',
        expireDate: DateTime.now().add(const Duration(days: 15)),
        currentRent: 4000000,
        proposedRent: 4200000,
      ),
      LeaseRenewal(
        id: 'l2',
        tenantName: 'Trần Thị B',
        roomName: 'P205',
        expireDate: DateTime.now().add(const Duration(days: 5)),
        currentRent: 3500000,
        proposedRent: 3500000,
        status: 'Đang chờ ký',
      ),
      LeaseRenewal(
        id: 'l3',
        tenantName: 'Lê Văn C',
        roomName: 'P302',
        expireDate: DateTime.now().add(const Duration(days: 30)),
        currentRent: 4500000,
        proposedRent: 4800000,
      ),
    ];

    // if (!mounted) return;
    state = state.copyWith(isLoading: false, leases: mockLeases);
  }

  void updateProposedRent(String id, double newRent) {
    final idx = state.leases.indexWhere((l) => l.id == id);
    if (idx == -1) return;

    final updatedList = List<LeaseRenewal>.from(state.leases);
    updatedList[idx] = updatedList[idx].copyWith(proposedRent: newRent);
    state = state.copyWith(leases: updatedList);
  }

  Future<void> sendRenewalOffer(String id) async {
    final idx = state.leases.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    if (state.leases[idx].status != 'Sắp hết hạn') return;

    // Simulate sending offer to tenant
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final updatedList = List<LeaseRenewal>.from(state.leases);
    updatedList[idx] = updatedList[idx].copyWith(status: 'Đang chờ ký');

    // if (!mounted) return;
    state = state.copyWith(isLoading: false, leases: updatedList);
  }
}

final leaseRenewalProvider =
    NotifierProvider<LeaseRenewalNotifier, LeaseRenewalState>(
      LeaseRenewalNotifier.new,
    );
