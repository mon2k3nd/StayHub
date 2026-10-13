import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class BackgroundCheckRequest {
  final String id;
  final String tenantName;
  final String identityNumber;
  final String status; // 'Chờ duyệt', 'Đang kiểm tra', 'Hoàn tất', 'Từ chối'
  final int trustScore; // 0-100
  final List<String> issues; // Danh sách cảnh báo (nếu có)
  final String requestDate;

  const BackgroundCheckRequest({
    required this.id,
    required this.tenantName,
    required this.identityNumber,
    this.status = 'Chờ duyệt',
    this.trustScore = 0,
    this.issues = const [],
    required this.requestDate,
  });

  BackgroundCheckRequest copyWith({
    String? status,
    int? trustScore,
    List<String>? issues,
  }) {
    return BackgroundCheckRequest(
      id: id,
      tenantName: tenantName,
      identityNumber: identityNumber,
      status: status ?? this.status,
      trustScore: trustScore ?? this.trustScore,
      issues: issues ?? this.issues,
      requestDate: requestDate,
    );
  }
}

class TenantBgCheckState {
  final bool isLoading;
  final List<BackgroundCheckRequest> requests;
  final String? error;

  const TenantBgCheckState({
    this.isLoading = false,
    this.requests = const [],
    this.error,
  });

  TenantBgCheckState copyWith({
    bool? isLoading,
    List<BackgroundCheckRequest>? requests,
    String? error,
  }) {
    return TenantBgCheckState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      error: error,
    );
  }
}

class TenantBgCheckNotifier extends Notifier<TenantBgCheckState> {
  @override
  build() {
    unawaited(Future.microtask(_loadRequests));
    return const TenantBgCheckState();
  }

  Future<void> _loadRequests() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final mockData = [
      const BackgroundCheckRequest(
        id: 'req_1',
        tenantName: 'Nguyễn Văn A',
        identityNumber: '079092...314',
        requestDate: '30/06/2026',
        status: 'Hoàn tất',
        trustScore: 95,
      ),
      const BackgroundCheckRequest(
        id: 'req_2',
        tenantName: 'Trần Thị B',
        identityNumber: '023184...552',
        requestDate: '29/06/2026',
        status: 'Hoàn tất',
        trustScore: 45,
        issues: ['Lịch sử nợ xấu tín dụng', 'Chậm tiền nhà 3 lần năm ngoái'],
      ),
      const BackgroundCheckRequest(
        id: 'req_3',
        tenantName: 'Lê Văn C',
        identityNumber: '045091...771',
        requestDate: 'Hôm nay',
        status: 'Chờ duyệt',
      ),
    ];

    // if (!mounted) return;
    state = state.copyWith(isLoading: false, requests: mockData);
  }

  Future<void> startCheck(String id) async {
    final idx = state.requests.indexWhere((r) => r.id == id);
    if (idx == -1) return;

    if (state.requests[idx].status != 'Chờ duyệt') return;

    // Set to processing
    final processingList = List<BackgroundCheckRequest>.from(state.requests);
    processingList[idx] = processingList[idx].copyWith(status: 'Đang kiểm tra');
    state = state.copyWith(requests: processingList);

    // Simulate AI Background check via CIC/Police DB
    await Future.delayed(const Duration(seconds: 3));

    // if (!mounted) return;
    final finishedList = List<BackgroundCheckRequest>.from(state.requests);
    finishedList[idx] = finishedList[idx].copyWith(
      status: 'Hoàn tất',
      trustScore: 88,
      issues: [],
    );
    state = state.copyWith(requests: finishedList);
  }
}

final tenantBgCheckProvider =
    NotifierProvider<TenantBgCheckNotifier, TenantBgCheckState>(
      TenantBgCheckNotifier.new,
    );
