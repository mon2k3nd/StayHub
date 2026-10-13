import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/violation_report_model.dart';
import '../../../core/providers/core_providers.dart';

part 'violation_report_provider.g.dart';

@riverpod
class ViolationReportNotifier extends _$ViolationReportNotifier {
  @override
  FutureOr<List<ViolationReport>> build(int branchId) async {
    return _fetchReports(branchId);
  }

  Future<List<ViolationReport>> _fetchReports(int branchId) async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/v1/violation-reports/branch/$branchId');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((e) => ViolationReport.fromJson(e)).toList();
    } else {
      throw Exception('L?i t?i phi?u vi ph?m');
    }
  }

  Future<void> addReport(ViolationReport report) async {
    final dio = ref.read(dioProvider);
    final response = await dio.post(
      '/v1/violation-reports',
      data: report.toJson(),
    );
    if (response.statusCode == 200) {
      final newReport = ViolationReport.fromJson(response.data);
      final previousState = await future;
      state = AsyncData([...previousState, newReport]);
    }
  }

  Future<void> updateReport(ViolationReport report) async {
    final dio = ref.read(dioProvider);
    final response = await dio.put(
      '/v1/violation-reports/${report.id}',
      data: report.toJson(),
    );
    if (response.statusCode == 200) {
      final updatedReport = ViolationReport.fromJson(response.data);
      final previousState = await future;
      state = AsyncData(
        previousState
            .map((e) => e.id == updatedReport.id ? updatedReport : e)
            .toList(),
      );
    }
  }

  Future<void> deleteReport(int id) async {
    final dio = ref.read(dioProvider);
    final response = await dio.delete('/v1/violation-reports/$id');
    if (response.statusCode == 200) {
      final previousState = await future;
      state = AsyncData(previousState.where((e) => e.id != id).toList());
    }
  }
}
