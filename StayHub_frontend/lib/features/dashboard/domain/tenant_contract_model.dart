class TenantContractModel {
  final int id;
  final String status;
  final String? tenantName;
  final String? roomName;
  final String? tenantPhone;
  final String? startDate;
  final String? endDate;
  final dynamic depositAmount;
  final dynamic rentAmount;
  final String? ownerName;
  final String? branchName;
  final String? idNumber;

  TenantContractModel({
    required this.id,
    required this.status,
    this.tenantName,
    this.roomName,
    this.tenantPhone,
    this.startDate,
    this.endDate,
    this.depositAmount,
    this.rentAmount,
    this.ownerName,
    this.branchName,
    this.idNumber,
  });

  factory TenantContractModel.fromJson(Map<String, dynamic> json) {
    return TenantContractModel(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'UNKNOWN',
      tenantName:
          json['tenantName'] ??
          json['tenant']?['fullName'] ??
          json['tenant']?['name'],
      roomName: json['roomName'] ?? json['room']?['roomName'],
      tenantPhone: json['tenantPhone'] ?? json['tenant']?['phoneNumber'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      depositAmount: json['depositAmount'],
      rentAmount: json['rentAmount'] ?? json['price'],
      ownerName: json['ownerName'] ?? json['owner']?['fullName'],
      branchName: json['branchName'] ?? json['branch']?['branchName'],
      idNumber: json['cccdNumber'] ?? json['tenant']?['cccdNumber'],
    );
  }
}
