import 'package:dio/dio.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  final Dio _dio;

  TicketRepository(this._dio);

  Future<List<TicketModel>> getTicketsByTenant(int tenantId) async {
    final response = await _dio.get('/v1/tickets/tenant/$tenantId');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => TicketModel.fromJson(json)).toList();
  }

  Future<List<TicketModel>> getTicketsByOwner(int ownerId) async {
    final response = await _dio.get('/v1/tickets/owner/$ownerId');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => TicketModel.fromJson(json)).toList();
  }

  Future<TicketModel> createTicket(
    Map<String, dynamic> data,
    String? imagePath,
  ) async {
    final formData = FormData.fromMap({
      'roomId': data['roomId'].toString(),
      'category': data['category'],
      'description': data['description'],
      if (data['severity'] != null) 'severity': data['severity'],
      if (data['tenantDesire'] != null) 'tenantDesire': data['tenantDesire'],
      if (data['sharedFacilityId'] != null)
        'sharedFacilityId': data['sharedFacilityId'].toString(),
    });

    if (imagePath != null) {
      formData.files.add(
        MapEntry('image', await MultipartFile.fromFile(imagePath)),
      );
    }

    final response = await _dio.post(
      '/v1/tickets/create',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return TicketModel.fromJson(response.data['data']);
  }

  Future<TicketModel> assignTicket(int ticketId, int assignedStaffId) async {
    final response = await _dio.put(
      '/v1/tickets/assign',
      data: {'ticketId': ticketId, 'assignedStaffId': assignedStaffId},
    );
    return TicketModel.fromJson(response.data['data']);
  }

  Future<void> approveTicket(int ticketId, double staffBonus) async {
    await _dio.post(
      '/v1/tickets/owner-approve',
      data: {'ticketId': ticketId, 'staffBonus': staffBonus},
    );
  }

  Future<TicketModel> completeTicket(
    int ticketId,
    double materialCost,
    bool isSuccessful,
    String repairDetails,
    String? imagePath,
  ) async {
    final formData = FormData.fromMap({
      'ticketId': ticketId.toString(),
      'materialCost': materialCost.toString(),
      'isSuccessful': isSuccessful.toString(),
      'repairDetails': repairDetails,
    });

    if (imagePath != null) {
      formData.files.add(
        MapEntry('image', await MultipartFile.fromFile(imagePath)),
      );
    }

    final response = await _dio.put(
      '/v1/tickets/staff-complete',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return TicketModel.fromJson(response.data['data']);
  }

  Future<TicketModel> ownerCompleteTicket(
    int ticketId,
    double materialCost,
    bool isSuccessful,
    String repairDetails,
    String? imagePath,
  ) async {
    final formData = FormData.fromMap({
      'ticketId': ticketId.toString(),
      'materialCost': materialCost.toString(),
      'isSuccessful': isSuccessful.toString(),
      'repairDetails': repairDetails,
    });

    if (imagePath != null) {
      formData.files.add(
        MapEntry('image', await MultipartFile.fromFile(imagePath)),
      );
    }

    final response = await _dio.put(
      '/v1/tickets/owner-complete',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return TicketModel.fromJson(response.data['data']);
  }

  Future<void> cancelTicket(int ticketId, String reason) async {
    await _dio.post(
      '/v1/tickets/owner-cancel',
      data: {'ticketId': ticketId, 'reason': reason},
    );
  }

  Future<void> rejectTicket(int ticketId, String reason) async {
    await _dio.post(
      '/v1/tickets/owner-reject',
      data: {'ticketId': ticketId, 'reason': reason},
    );
  }
}
