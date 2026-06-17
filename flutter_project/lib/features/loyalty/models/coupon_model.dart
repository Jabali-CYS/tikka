enum DiscountType { percentage, fixed }

class CouponModel {
  final String id;
  final String code;
  final DiscountType discountType;
  final double value;
  final double minOrder;
  final String description;
  final String descriptionAr;
  final bool isDeleted;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    required this.minOrder,
    required this.description,
    required this.descriptionAr,
    this.isDeleted = false,
  });

  factory CouponModel.fromMap(Map<String, dynamic> map, String docId) {
    DiscountType type = DiscountType.fixed;
    if (map['discountType'] != null) {
      if (map['discountType'].toString().toLowerCase() == 'percentage') {
        type = DiscountType.percentage;
      }
    }

    return CouponModel(
      id: docId,
      code: map['code'] ?? '',
      discountType: type,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      minOrder: (map['minOrder'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      descriptionAr: map['descriptionAr'] ?? '',
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'discountType': discountType.name,
      'value': value,
      'minOrder': minOrder,
      'description': description,
      'descriptionAr': descriptionAr,
      'isDeleted': isDeleted,
    };
  }
}
