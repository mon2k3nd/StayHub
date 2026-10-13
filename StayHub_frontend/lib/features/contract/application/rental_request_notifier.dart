import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/rental_draft_repository.dart';
import '../../../core/providers/core_providers.dart';

part 'rental_request_notifier.g.dart';

class RentalRequestState {
  final int currentStep;
  final Map<String, dynamic> formData;
  final bool isLoading;
  final String? error;
  final DateTime? lastSavedAt;

  RentalRequestState({
    this.currentStep = 0,
    this.formData = const {},
    this.isLoading = false,
    this.error,
    this.lastSavedAt,
  });

  RentalRequestState copyWith({
    int? currentStep,
    Map<String, dynamic>? formData,
    bool? isLoading,
    String? error,
    DateTime? lastSavedAt,
  }) {
    return RentalRequestState(
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }
}

@riverpod
class RentalRequestNotifier extends _$RentalRequestNotifier {
  Timer? _debounce;
  late final RentalDraftRepository _draftRepository;
  String? _roomId;

  @override
  RentalRequestState build() {
    _draftRepository = RentalDraftRepository();
    return RentalRequestState();
  }

  Future<void> initDraft(String roomId) async {
    _roomId = roomId;
    final draft = await _draftRepository.getDraft(roomId);
    if (draft != null) {
      state = state.copyWith(formData: draft, lastSavedAt: DateTime.now());
    }
  }

  void updateFormData(String key, dynamic value) {
    final updatedData = Map<String, dynamic>.from(state.formData)
      ..[key] = value;
    state = state.copyWith(formData: updatedData);
    _autoSave();
  }

  void _autoSave() {
    if (_roomId == null) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _draftRepository.saveDraft(_roomId!, state.formData);
      state = state.copyWith(lastSavedAt: DateTime.now());
    });
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> submitRequest({
    required int roomId,
    required int? branchId,
    required String moveInDate,
    required String note,
    required String sessionToken,
  }) async {
    if (_roomId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/v1/rental-requests',
        data: {
          'sessionToken': sessionToken,
          'roomId': roomId,
          'branchId': branchId,
          'moveInDate': moveInDate,
          'note': note,
          'formData': state.formData,
        },
      );

      // Clear draft on success
      await _draftRepository.clearDraft(_roomId!);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // Re-throw to be handled by UI
    }
  }

  void dispose() {
    _debounce?.cancel();
  }
}
