class ComplaintModel {
  final int id;
  final int tenantId;
  final String tenantName;
  final String tenantPhone;
  final int branchId;
  final int? roomId;
  final String? roomName;
  final String category;
  final String priority;
  final String title;
  final String? description;
  final List<String> images;
  final String status;
  final String? adminNote;
  final String createdAt;

  ComplaintModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
    required this.branchId,
    this.roomId,
    this.roomName,
    required this.category,
    required this.priority,
    required this.title,
    this.description,
    required this.images,
    required this.status,
    this.adminNote,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      tenantId: json['tenantId'],
      tenantName: json['tenantName'] ?? 'Unknown',
      tenantPhone: json['tenantPhone'] ?? 'Unknown',
      branchId: json['branchId'],
      roomId: json['roomId'],
      roomName: json['roomName'],
      category: json['category'],
      priority: json['priority'],
      title: json['title'],
      description: json['description'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      status: json['status'],
      adminNote: json['adminNote'],
      createdAt: json['createdAt'],
    );
  }
}
