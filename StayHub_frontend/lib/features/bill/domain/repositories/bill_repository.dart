import '../../data/models/bill_model.dart';
import '../../data/models/meter_reading_model.dart';

abstract class BillRepository {
  Future<List<BillModel>> loadBillsByTenant(int tenantId);
  Future<List<BillModel>> loadBillsByOwner(int ownerId);
  Future<List<BillModel>> loadBillsByStaff(int staffId);
  Future<void> payBill(int billId, {required bool cash, int? staffId});
  Future<void> payBillOnline(int billId);
  Future<void> confirmCashPayment(int billId, int ownerId);
  Future<void> updateUtilities(
    int billId,
    double? electricCurrent,
    double? waterCurrent, {
    String? electricImage,
    String? waterImage,
  });
  Future<void> sendBill(int billId);
  Future<List<MeterReadingModel>> getMeterReadings(
    int branchId,
    int month,
    int year,
  );
  Future<List<BillModel>> generateBills(int branchId, int month, int year);
  Future<void> updateUtilitiesByRoom(
    int roomId,
    double? electricCurrent,
    double? waterCurrent, {
    String? electricImage,
    String? waterImage,
  });
}
