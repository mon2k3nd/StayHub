class StaffTaskModel {
  final int id;
  final int branchId;
  final int? assignedStaffId;
  final String? assignedStaffName;
  final int createdById;
  final String? createdByName;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? dueDate;
  final String createdAt;

  StaffTaskModel({
    required this.id,
    required this.branchId,
    this.assignedStaffId,
    this.assignedStaffName,
    required this.createdById,
    this.createdByName,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
  });

  factory StaffTaskModel.fromJson(Map<String, dynamic> json) {
    return StaffTaskModel(
      id: json['id'],
      branchId: json['branchId'],
      assignedStaffId: json['assignedStaffId'],
      assignedStaffName: json['assignedStaffName'],
      createdById: json['createdById'],
      createdByName: json['createdByName'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      dueDate: json['dueDate'],
      createdAt: json['createdAt'],
    );
  }

  StaffTaskModel copyWith({String? status}) {
    return StaffTaskModel(
      id: id,
      branchId: branchId,
      assignedStaffId: assignedStaffId,
      assignedStaffName: assignedStaffName,
      createdById: createdById,
      createdByName: createdByName,
      title: title,
      description: description,
      priority: priority,
      status: status ?? this.status,
      dueDate: dueDate,
      createdAt: createdAt,
    );
  }
}
