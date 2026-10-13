import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'checkout_provider.dart';

part 'owner_checkout_notifier.g.dart';

class OwnerCheckoutState {
  final bool isLoading;
  final String? error;
  final String? aiSuggestion;
  final bool isAiLoading;

  OwnerCheckoutState({
    this.isLoading = false,
    this.error,
    this.aiSuggestion,
    this.isAiLoading = false,
  });

  OwnerCheckoutState copyWith({
    bool? isLoading,
    String? error,
    String? aiSuggestion,
    bool? isAiLoading,
  }) {
    return OwnerCheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      isAiLoading: isAiLoading ?? this.isAiLoading,
    );
  }
}

@riverpod
class OwnerCheckoutNotifier extends _$OwnerCheckoutNotifier {
  @override
  OwnerCheckoutState build() {
    return OwnerCheckoutState();
  }

  Future<void> analyzeImagesWithAI(int checkoutId) async {
    state = state.copyWith(isAiLoading: true, aiSuggestion: null, error: null);
    try {
      final suggestion = await ref
          .read(checkoutRepositoryProvider)
          .analyzeImagesWithAI(checkoutId);
      state = state.copyWith(isAiLoading: false, aiSuggestion: suggestion);
    } catch (e) {
      state = state.copyWith(isAiLoading: false, error: e.toString());
    }
  }

  Future<bool> rejectRequest(int id, String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(checkoutRepositoryProvider).rejectRequest(id, reason);
      ref.invalidate(ownerCheckoutRequestsProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> approveAndCreateBill(
    int id,
    Map<String, dynamic> billData,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref
          .read(checkoutRepositoryProvider)
          .approveAndCreateBill(id, billData);
      ref.invalidate(ownerCheckoutRequestsProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
