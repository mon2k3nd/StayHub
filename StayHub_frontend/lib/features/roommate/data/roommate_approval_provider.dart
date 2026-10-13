import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RoommateApprovalState { none, pending, approved, rejected }

class RoommateApprovalNotifier extends Notifier<RoommateApprovalState> {
  @override
  RoommateApprovalState build() => RoommateApprovalState.none;

  void requestApproval() {
    state = RoommateApprovalState.pending;
  }

  void approveRequest() {
    state = RoommateApprovalState.approved;
  }

  void rejectRequest() {
    state = RoommateApprovalState.rejected;
  }

  void reset() {
    state = RoommateApprovalState.none;
  }
}

final roommateApprovalProvider =
    NotifierProvider<RoommateApprovalNotifier, RoommateApprovalState>(() {
      return RoommateApprovalNotifier();
    });
