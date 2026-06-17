class DeliveryZoneModel {
  final String id;
  final String name;
  final String nameAr;
  final double fee;
  final double minOrder;

  DeliveryZoneModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.fee,
    required this.minOrder,
  });

  factory DeliveryZoneModel.fromMap(Map<String, dynamic> map, String docId) {
    return DeliveryZoneModel(
      id: docId,
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      fee: (map['fee'] as num?)?.toDouble() ?? 0.0,
      minOrder: (map['minOrder'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'fee': fee,
      'minOrder': minOrder,
    };
  }
}
