import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/datasources/room_remote_data_source.dart';
import '../data/models/room_model.dart';
import '../data/models/roommate_model.dart';
import '../data/repositories/room_repository_impl.dart';
import '../domain/repositories/room_repository.dart';

part 'room_notifier.g.dart';

@riverpod
RoomRemoteDataSource roomRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RoomRemoteDataSource(apiClient);
}

@Riverpod(keepAlive: true)
RoomRepository roomRepository(Ref ref) {
  final remoteDataSource = ref.watch(roomRemoteDataSourceProvider);
  return RoomRepositoryImpl(remoteDataSource);
}

@Riverpod(keepAlive: true)
class RoomNotifier extends _$RoomNotifier {
  @override
  FutureOr<List<RoomModel>> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user == null) return [];

    final repository = ref.read(roomRepositoryProvider);
    return await repository.loadByOwner(user.id);
  }

  Future<void> loadByBranch(int branchId) async {
    if (!state.hasValue) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(roomRepositoryProvider);
      return repository.loadByBranch(branchId);
    });
  }

  Future<void> loadByOwner(int ownerId, {String? status}) async {
    if (!state.hasValue) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(roomRepositoryProvider);
      return repository.loadByOwner(ownerId, status: status);
    });
  }

  Future<void> createRoom(
    Map<String, dynamic> data, {
    List<String>? imagePaths,
  }) async {
    final repository = ref.read(roomRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repository.createRoom(data, imagePaths: imagePaths);
      final authState = ref.read(authProvider);

      // Làm mới toàn bộ dashboard (stats "Chưa đăng", analytics, danh sách phòng).
      refreshOwnerDashboard(ref);

      state = AsyncValue.data(
        await repository.loadByOwner(authState.value?.id ?? 0),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateRoom(int roomId, Map<String, dynamic> data) async {
    final repository = ref.read(roomRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateRoom(roomId, data);
      final authState = ref.read(authProvider);

      refreshOwnerDashboard(ref);

      return repository.loadByOwner(authState.value?.id ?? 0);
    });
  }

  Future<void> deleteRoom(int roomId) async {
    final repository = ref.read(roomRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteRoom(roomId);
      final authState = ref.read(authProvider);

      refreshOwnerDashboard(ref);

      return repository.loadByOwner(authState.value?.id ?? 0);
    });
  }

  Future<void> approveRoom(int roomId, bool approved) async {
    final repository = ref.read(roomRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.approveRoom(roomId, approved);
      final authState = ref.read(authProvider);

      refreshOwnerDashboard(ref);

      return repository.loadByOwner(authState.value?.id ?? 0);
    });
  }
}

@riverpod
Future<List<RoomModel>> allOwnerRooms(Ref ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.value;
  if (user == null) return [];
  final repository = ref.read(roomRepositoryProvider);
  return repository.loadByOwner(user.id);
}

@riverpod
class RoommateNotifier extends _$RoommateNotifier {
  @override
  FutureOr<List<RoommateModel>> build(int contractId) async {
    final repository = ref.read(roomRepositoryProvider);
    return await repository.loadRoommates(contractId);
  }

  Future<void> addRoommate({
    required int contractId,
    required int roomId,
    required String fullName,
    String? phoneNumber,
    String? cccdNumber,
    String? hometown,
  }) async {
    final repository = ref.read(roomRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createRoommate({
        'contractId': contractId,
        'roomId': roomId,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'cccdNumber': cccdNumber,
        'hometown': hometown,
        'checkInDate': DateTime.now().toIso8601String().split('T')[0],
        'isActive': true,
      });
      return repository.loadRoommates(contractId);
    });
  }

  Future<void> checkoutRoommate(int roommateId) async {
    final repository = ref.read(roomRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.checkoutRoommate(roommateId);
      return repository.loadRoommates(contractId);
    });
  }
}
