import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/repositories/ticket_repository.dart';
import '../data/models/ticket_model.dart';
import '../../../core/constants/role_types.dart';

part 'ticket_provider.g.dart';

@Riverpod(keepAlive: true)
TicketRepository ticketRepository(Ref ref) {
  return TicketRepository(ref.watch(apiClientProvider).dio);
}

@Riverpod(keepAlive: true)
class TicketNotifier extends _$TicketNotifier {
  @override
  FutureOr<List<TicketModel>> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user == null) return [];

    final repo = ref.watch(ticketRepositoryProvider);
    if (Role.isOwner(user.role)) {
      return repo.getTicketsByOwner(user.id);
    } else if (Role.isTenant(user.role)) {
      return repo.getTicketsByTenant(user.id);
    } else if (Role.isStaff(user.role)) {
      try {
        final res = await ref
            .read(apiClientProvider)
            .dio
            .get('/v1/tickets/staff/${user.id}');
        final List<dynamic> data = res.data['data'] ?? [];
        return data.map((json) => TicketModel.fromJson(json)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<void> refresh() async {
    if (!state.hasValue) state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authProvider).value;
      if (user == null) return [];
      final repo = ref.read(ticketRepositoryProvider);
      if (Role.isOwner(user.role)) {
        return repo.getTicketsByOwner(user.id);
      } else if (Role.isTenant(user.role)) {
        return repo.getTicketsByTenant(user.id);
      } else if (Role.isStaff(user.role)) {
        try {
          final res = await ref
              .read(apiClientProvider)
              .dio
              .get('/v1/tickets/staff/${user.id}');
          final List<dynamic> data = res.data['data'] ?? [];
          return data.map((json) => TicketModel.fromJson(json)).toList();
        } catch (e) {
          return [];
        }
      }
      return <TicketModel>[];
    });
  }

  Future<bool> createTicket(
    Map<String, dynamic> data,
    String? imagePath,
  ) async {
    try {
      await ref.read(ticketRepositoryProvider).createTicket(data, imagePath);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignTicket(int ticketId, int assignedStaffId) async {
    try {
      await ref
          .read(ticketRepositoryProvider)
          .assignTicket(ticketId, assignedStaffId);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> approveTicket(int ticketId, double staffBonus) async {
    try {
      await ref
          .read(ticketRepositoryProvider)
          .approveTicket(ticketId, staffBonus);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completeTicket(
    int ticketId,
    double materialCost,
    bool isSuccessful,
    String repairDetails,
    String? imagePath,
  ) async {
    try {
      await ref
          .read(ticketRepositoryProvider)
          .completeTicket(
            ticketId,
            materialCost,
            isSuccessful,
            repairDetails,
            imagePath,
          );
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ownerCompleteTicket(
    int ticketId,
    double materialCost,
    bool isSuccessful,
    String repairDetails,
    String? imagePath,
  ) async {
    try {
      await ref
          .read(ticketRepositoryProvider)
          .ownerCompleteTicket(
            ticketId,
            materialCost,
            isSuccessful,
            repairDetails,
            imagePath,
          );
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelTicket(int ticketId, String reason) async {
    try {
      await ref.read(ticketRepositoryProvider).cancelTicket(ticketId, reason);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectTicket(int ticketId, String reason) async {
    try {
      await ref.read(ticketRepositoryProvider).rejectTicket(ticketId, reason);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}
