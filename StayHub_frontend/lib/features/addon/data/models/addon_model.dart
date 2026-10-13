class AddonModel {
  final int id;
  final int ownerId;
  final String name;
  final double price;
  final String? description;
  final String? iconUrl;
  final bool isActive;
  final DateTime? createdAt;

  const AddonModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.price,
    this.description,
    this.iconUrl,
    this.isActive = true,
    this.createdAt,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    // BUGFIX (data): coerce an toàn — tránh `as int`/`as String`/`as num`
    // ném TypeError khi JSON trả id dạng String hoặc name/price null.
    final rawId = json['id'];
    final rawOwnerId = json['ownerId'];
    final rawPrice = json['price'];
    return AddonModel(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      ownerId: rawOwnerId is num
          ? rawOwnerId.toInt()
          : int.tryParse('$rawOwnerId') ?? 0,
      name: (json['name'] ?? '').toString(),
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse('$rawPrice') ?? 0.0,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'price': price,
      'description': description,
      'iconUrl': iconUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
