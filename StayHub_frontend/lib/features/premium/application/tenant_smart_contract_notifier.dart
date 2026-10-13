import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class SmartContractState {
  final bool isLoading;
  final bool isSigning;
  final bool isSigned;
  final String contractId;
  final String roomName;
  final String hashValue;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;

  const SmartContractState({
    this.isLoading = false,
    this.isSigning = false,
    this.isSigned = false,
    this.contractId = '',
    this.roomName = '',
    this.hashValue = '',
    required this.startDate,
    required this.endDate,
    this.monthlyRent = 0.0,
  });

  SmartContractState copyWith({
    bool? isLoading,
    bool? isSigning,
    bool? isSigned,
    String? contractId,
    String? roomName,
    String? hashValue,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyRent,
  }) {
    return SmartContractState(
      isLoading: isLoading ?? this.isLoading,
      isSigning: isSigning ?? this.isSigning,
      isSigned: isSigned ?? this.isSigned,
      contractId: contractId ?? this.contractId,
      roomName: roomName ?? this.roomName,
      hashValue: hashValue ?? this.hashValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
    );
  }
}

class SmartContractNotifier extends Notifier<SmartContractState> {
  @override
  SmartContractState build() {
    unawaited(_loadContract());
    return SmartContractState(
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<void> _loadContract() async {
    state = state.copyWith(isLoading: true);

    // Simulate fetching Smart Contract from blockchain/DB
    await Future.delayed(const Duration(milliseconds: 1000));

    // if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      contractId: 'SC-2026-89A4B',
      roomName: 'Phòng P102 - Tòa A',
      hashValue: '0x8f2d5a3...e1b4c',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 365)),
      monthlyRent: 4500000,
    );
  }

  Future<void> signContract() async {
    if (state.isSigning || state.isSigned) return;

    state = state.copyWith(isSigning: true);

    // Simulate cryptographic signing delay
    await Future.delayed(const Duration(seconds: 2));

    // if (!mounted) return;

    // Generate a simulated new hash indicating signature is sealed
    state = state.copyWith(
      isSigning: false,
      isSigned: true,
      hashValue: '0x9a7f3c...signed',
    );
  }
}

final smartContractProvider =
    NotifierProvider<SmartContractNotifier, SmartContractState>(
      SmartContractNotifier.new,
    );
