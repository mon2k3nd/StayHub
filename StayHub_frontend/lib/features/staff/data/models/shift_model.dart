class ShiftModel {
  final int id;
  final int branchId;
  final int staffId;
  final String title;
  final String startTime;
  final String endTime;
  final String status;

  ShiftModel({
    required this.id,
    required this.branchId,
    required this.staffId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] ?? 0,
      branchId: json['branchId'] ?? 0,
      staffId: json['staffId'] ?? 0,
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      status: json['status'] ?? 'SCHEDULED',
    );
  }
}
