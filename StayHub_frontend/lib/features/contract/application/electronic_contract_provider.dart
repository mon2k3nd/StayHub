import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/custom_sse_client.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:async' show unawaited;

part 'electronic_contract_provider.freezed.dart';
part 'electronic_contract_provider.g.dart';

@freezed
abstract class ElectronicContractState with _$ElectronicContractState {
  const factory ElectronicContractState({
    @Default(false) bool isLoading,
    @Default('') String error,
    @Default(false) bool isTenantSigned,
    @Default(false) bool isOwnerSigned,
    @Default(false) bool isSignatureSuccess,
    @Default(60) int countdownSeconds,
  }) = _ElectronicContractState;
}

@riverpod
class ElectronicContractNotifier extends _$ElectronicContractNotifier {
  CustomSseClient? _sseClient;

  @override
  ElectronicContractState build() {
    return const ElectronicContractState();
  }

  void startCountdown() {
    state = state.copyWith(countdownSeconds: 60);
    unawaited(_tick());
  }

  Future<void> _tick() async {
    while (state.countdownSeconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      // In Riverpod 2 Notifier, state update after dispose might throw, we just try catch it.
      try {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      } catch (e, st) {
        debugPrint('Error: $e\n$st');
        break;
      }
    }
  }

  Future<void> signContract(
    int contractId,
    String role,
    String otp, {
    int? voucherId,
  }) async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.post(
        '/v1/electronic-contracts/$contractId/sign',
        data: {
          'role': role,
          'otp': otp,
          if (voucherId != null) 'voucherId': voucherId,
        },
      );

      if (res['success'] == true) {
        if (role == 'TENANT') {
          state = state.copyWith(isTenantSigned: true, isLoading: false);
        } else {
          state = state.copyWith(
            isOwnerSigned: true,
            isSignatureSuccess: true,
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(
          error: res['message'] ?? 'Xác thực OTP thất bại',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> uploadPaperContract(
    int contractId,
    List<String> imageUrls,
  ) async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.post(
        '/v1/electronic-contracts/$contractId/upload-paper',
        data: {'paperContractImages': jsonEncode(imageUrls)},
      );

      if (res['success'] == true) {
        state = state.copyWith(isTenantSigned: true, isLoading: false);
      } else {
        state = state.copyWith(
          error: res['message'] ?? 'Tải lên thất bại',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void listenToContractEvents(int roomId) {
    final client = ref.read(apiClientProvider);
    final url = '${client.dio.options.baseUrl}/v1/disputes/stream/$roomId';
    _sseClient = CustomSseClient();
    _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: url,
          header: {"Accept": "text/event-stream", "Cache-Control": "no-cache"},
        )
        .listen((event) {
          log('SSE Event received: ${event.event} - Data: ${event.data}');
          if (event.event == 'TENANT_SIGNED_SUCCESS') {
            state = state.copyWith(isTenantSigned: true);
          } else if (event.event == 'OWNER_SIGNED_SUCCESS') {
            state = state.copyWith(
              isOwnerSigned: true,
              isSignatureSuccess: true,
            );
          }
        });
  }

  void unsubscribe() {
    _sseClient?.unsubscribeFromSSE();
  }
}
