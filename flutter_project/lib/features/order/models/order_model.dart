import '../../menu/models/product_model.dart';

enum OrderStatus { pending, accepted, preparing, ready, out_for_delivery, delivered, canceled }
enum FulfillmentType { delivery, pickup }
enum PaymentMethod { card, cash, points }

class OrderAddress {
  final String street;
  final String buildingName;
  final String floor;
  final String apartment;
  final String? instructions;
  final String label; // e.g. "Home", "Office", "Other"
  final Map<String, double> coordinates;

  OrderAddress({
    required this.street,
    required this.buildingName,
    required this.floor,
    required this.apartment,
    this.instructions,
    this.label = "Home",
    required this.coordinates,
  });

  factory OrderAddress.fromMap(Map<String, dynamic> map) {
    return OrderAddress(
      street: map['street'] ?? '',
      buildingName: map['buildingName'] ?? '',
      floor: map['floor'] ?? '',
      apartment: map['apartment'] ?? '',
      instructions: map['instructions'],
      label: map['label'] ?? 'Home',
      coordinates: Map<String, double>.from(
        (map['coordinates'] as Map? ?? {}).map(
          (key, val) => MapEntry(key.toString(), (val as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'buildingName': buildingName,
      'floor': floor,
      'apartment': apartment,
      'instructions': instructions,
      'label': label,
      'coordinates': coordinates,
    };
  }
}

class OrderItem {
  final String productId;
  final String title;
  final String titleAr;
  final int quantity;
  final String selectedSpiciness;
  final String selectedSide; // side ID
  final double sidePrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.title,
    required this.titleAr,
    required this.quantity,
    required this.selectedSpiciness,
    required this.selectedSide,
    required this.sidePrice,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      titleAr: map['titleAr'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      selectedSpiciness: map['selectedSpiciness'] ?? 'Medium',
      selectedSide: map['selectedSide'] ?? '',
      sidePrice: (map['sidePrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'titleAr': titleAr,
      'quantity': quantity,
      'selectedSpiciness': selectedSpiciness,
      'selectedSide': selectedSide,
      'sidePrice': sidePrice,
      'totalPrice': totalPrice,
    };
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerUid;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double taxes;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final FulfillmentType fulfillmentType;
  final OrderAddress? address;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerUid,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxes,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.fulfillmentType,
    this.address,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    OrderStatus status = OrderStatus.pending;
    if (map['status'] != null) {
      switch (map['status'].toString().toLowerCase()) {
        case 'accepted': status = OrderStatus.accepted; break;
        case 'preparing': status = OrderStatus.preparing; break;
        case 'ready': status = OrderStatus.ready; break;
        case 'out_for_delivery': status = OrderStatus.out_for_delivery; break;
        case 'delivered': status = OrderStatus.delivered; break;
        case 'canceled': status = OrderStatus.canceled; break;
        default: status = OrderStatus.pending;
      }
    }

    FulfillmentType fType = FulfillmentType.pickup;
    if (map['fulfillmentType']?.toString().toLowerCase() == 'delivery') {
      fType = FulfillmentType.delivery;
    }

    PaymentMethod pMethod = PaymentMethod.cash;
    if (map['paymentMethod'] != null) {
      switch (map['paymentMethod'].toString().toLowerCase()) {
        case 'card': pMethod = PaymentMethod.card; break;
        case 'points': pMethod = PaymentMethod.points; break;
        default: pMethod = PaymentMethod.cash;
      }
    }

    return OrderModel(
      id: docId,
      orderNumber: map['orderNumber'] ?? '',
      customerUid: map['customerUid'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      taxes: (map['taxes'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: pMethod,
      status: status,
      fulfillmentType: fType,
      address: map['address'] != null 
          ? OrderAddress.fromMap(Map<String, dynamic>.from(map['address'])) 
          : null,
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      driverRating: (map['driverRating'] as num?)?.toDouble(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerUid': customerUid,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'taxes': taxes,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'fulfillmentType': fulfillmentType.name,
      'address': address?.toMap(),
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverRating': driverRating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}
