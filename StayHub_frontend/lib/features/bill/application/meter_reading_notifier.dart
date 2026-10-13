import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'bill_notifier.dart';
import '../data/models/meter_reading_model.dart';

part 'meter_reading_notifier.g.dart';

@riverpod
class MeterReadingNotifier extends _$MeterReadingNotifier {
  @override
  FutureOr<List<MeterReadingModel>> build(
    int branchId,
    int month,
    int year,
  ) async {
    final repository = ref.watch(billRepositoryProvider);
    return repository.getMeterReadings(branchId, month, year);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(billRepositoryProvider);
      return repository.getMeterReadings(branchId, month, year);
    });
  }

  Future<void> updateUtilitiesByRoom(
    int roomId,
    double? electricCurrent,
    double? waterCurrent, {
    String? electricImage,
    String? waterImage,
  }) async {
    final repository = ref.read(billRepositoryProvider);
    await repository.updateUtilitiesByRoom(
      roomId,
      electricCurrent,
      waterCurrent,
      electricImage: electricImage,
      waterImage: waterImage,
    );
    await refresh(); // Reload list after update
  }

  Future<void> generateBills() async {
    final repository = ref.read(billRepositoryProvider);
    await repository.generateBills(branchId, month, year);
    await refresh();
  }
}
