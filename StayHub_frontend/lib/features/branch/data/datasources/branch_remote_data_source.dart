import '../../../../core/network/api_client.dart';

class BranchRemoteDataSource {
  final ApiClient _apiClient;

  const BranchRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> loadByOwner(int ownerId) async {
    return _apiClient.get('/v1/branches/owner/$ownerId');
  }

  /// Lấy MỘT chi nhánh theo ID — dùng để nạp lại cấu trúc mới nhất
  /// (`description` chứa sơ đồ tầng/phòng/WC) khi mở lại một bước wizard.
  Future<Map<String, dynamic>> getById(int branchId) async {
    return _apiClient.get('/v1/branches/$branchId');
  }

  /// Lấy RIÊNG ảnh base64 (cover + PCCC) của chi nhánh.
  ///
  /// Vì backend đã `@JsonIgnore` hai cột ảnh nặng để tránh OOM khi trả danh
  /// sách, màn SỬA chi nhánh phải gọi endpoint này mới có ảnh để hiển thị.
  Future<Map<String, dynamic>> getBranchImages(int branchId) async {
    final res = await _apiClient.get('/v1/branches/$branchId/images');
    return (res['data'] as Map<String, dynamic>?) ?? const {};
  }

  Future<List<dynamic>> getDeletedBranches(int ownerId) async {
    final response = await _apiClient.get(
      '/v1/branches/owner/$ownerId/deleted',
    );
    // BUGFIX (data): tránh `as List` ném TypeError khi `data`
    // null/không phải List.
    final raw = response['data'];
    return raw is List ? raw : const <dynamic>[];
  }

  Future<Map<String, dynamic>> loadDraftsByOwner(int ownerId) async {
    return _apiClient.get('/v1/branches/owner/$ownerId/drafts');
  }

  Future<Map<String, dynamic>> createBranch(Map<String, dynamic> data) async {
    return _apiClient.post('/v1/branches', data: data);
  }

  /// Tạo chi nhánh ở trạng thái NHÁP (DRAFT) cho wizard 4 bước.
  /// Backend luôn ép creationStatus = 'DRAFT' và reset cờ 4 bước về false,
  /// nên chi nhánh chưa cấu hình xong sẽ không lên chợ trọ / không vào thống kê.
  Future<Map<String, dynamic>> createWizardDraft(
    Map<String, dynamic> data,
  ) async {
    return _apiClient.post('/v1/branches/wizard-draft', data: data);
  }

  Future<Map<String, dynamic>> completeBranch(int branchId) async {
    return _apiClient.put('/v1/branches/$branchId/complete', data: {});
  }

  /// Lấy TẤT CẢ chi nhánh (mọi trạng thái) cho màn hình "Quản lý chi nhánh".
  Future<Map<String, dynamic>> loadAllForManagement(int ownerId) async {
    return _apiClient.get('/v1/branches/owner/$ownerId/management');
  }

  /// Đánh dấu hoàn tất / bỏ hoàn tất 1 bước trong wizard 4 bước.
  Future<Map<String, dynamic>> markStep(
    int branchId,
    int step,
    bool done,
  ) async {
    return _apiClient.put(
      '/v1/branches/$branchId/steps/$step',
      queryParameters: {'done': done},
    );
  }

  /// Tạm ngừng hoạt động chi nhánh (SUSPENDED).
  Future<Map<String, dynamic>> suspendBranch(int branchId) async {
    return _apiClient.put('/v1/branches/$branchId/suspend', data: {});
  }

  /// Kích hoạt lại chi nhánh đã tạm ngừng.
  Future<Map<String, dynamic>> resumeBranch(int branchId) async {
    return _apiClient.put('/v1/branches/$branchId/resume', data: {});
  }

  Future<Map<String, dynamic>> updateBranch(
    int branchId,
    Map<String, dynamic> data,
  ) async {
    return _apiClient.put('/v1/branches/$branchId', data: data);
  }

  /// Ngừng hoạt động chi nhánh (COMPLETED → SUSPENDED, giữ dữ liệu + _OFF).
  Future<void> deleteBranch(int branchId) async {
    await _apiClient.delete('/v1/branches/$branchId');
  }

  /// HỦY chi nhánh đang khởi tạo (DRAFT) — xóa cứng, giải phóng mã hoàn toàn.
  Future<void> cancelDraftBranch(int branchId) async {
    await _apiClient.delete('/v1/branches/$branchId/cancel-draft');
  }

  Future<Map<String, dynamic>> approveBranch(
    int branchId,
    bool approved,
  ) async {
    return _apiClient.put(
      '/v1/branches/$branchId/approve',
      queryParameters: {'approved': approved},
    );
  }

  /// Kiểm tra trùng mã dãy trọ real-time.
  ///
  /// Backend kiểm tra CẢ các chi nhánh đã xóa mềm (vì cột branch_code có
  /// UNIQUE INDEX ở tầng DB), nên kết quả khớp với lúc INSERT.
  Future<bool> checkBranchCodeTaken(String code, {int? excludeId}) async {
    final data = await checkBranchCodeConflict(code, excludeId: excludeId);
    return data?['taken'] == true;
  }

  /// Trả về CHI TIẾT xung đột mã chi nhánh (nếu có):
  /// { taken, conflictingId, conflictingName, conflictingCode, conflictingStatus }
  Future<Map<String, dynamic>?> checkBranchCodeConflict(
    String code, {
    int? excludeId,
  }) async {
    final params = <String, dynamic>{'code': code};
    if (excludeId != null) params['excludeId'] = excludeId;
    final result = await _apiClient.get(
      '/v1/branches/check-code',
      queryParameters: params,
    );
    return result['data'] as Map<String, dynamic>?;
  }

  /// Lấy danh sách phòng theo chi nhánh (cho màn hình cấu hình chi tiết)
  Future<Map<String, dynamic>> getRoomsByBranch(int branchId) async {
    return _apiClient.get('/v1/branches/$branchId/rooms');
  }

  /// Lấy danh sách WC chung theo chi nhánh
  Future<Map<String, dynamic>> getFacilitiesByBranch(int branchId) async {
    return _apiClient.get('/v1/branches/$branchId/facilities');
  }

  /// Cấu hình chi tiết phòng: chỉ số điện/nước, nội thất
  Future<Map<String, dynamic>> configureRoom(
    int roomId,
    Map<String, dynamic> data, {
    void Function(int, int)? onSendProgress,
  }) async {
    return _apiClient.put(
      '/v1/rooms/$roomId/config',
      data: data,
      onSendProgress: onSendProgress,
    );
  }

  /// Cấu hình chi tiết WC chung: tên, ghi chú
  Future<Map<String, dynamic>> configureFacility(
    int branchId,
    int facilityId,
    Map<String, dynamic> data,
  ) async {
    return _apiClient.put(
      '/v1/branches/$branchId/facilities/$facilityId/config',
      data: data,
    );
  }

  /// Tạo/lấy mã QR cố định cho phòng
  Future<Map<String, dynamic>> generateRoomQr(int roomId) async {
    return _apiClient.post('/v1/rooms/$roomId/generate-qr', data: {});
  }
}
