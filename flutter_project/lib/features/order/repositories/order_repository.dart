import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/config.dart';
import '../../../core/services/firebase_service.dart';
import '../models/order_model.dart';
import '../models/delivery_zone_model.dart';
import '../../loyalty/models/coupon_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> placeOrder(OrderModel order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<List<DeliveryZoneModel>> getDeliveryZones();
}

class StaticOrderRepositoryImpl implements OrderRepository {
  final List<OrderModel> _orders = [];
  
  final List<DeliveryZoneModel> _zones = [
    DeliveryZoneModel(id: "z1", name: "Shmeisani & Abdali", nameAr: "الشميساني والعبدلي", fee: 1.50, minOrder: 5.00),
    DeliveryZoneModel(id: "z2", name: "Khalda & Tla' Al-Ali", nameAr: "خلدا وتلاع العلي", fee: 2.00, minOrder: 5.00),
    DeliveryZoneModel(id: "z3", name: "Dabouq & Al-Madinah", nameAr: "دابوق وشارع المدينة", fee: 2.50, minOrder: 7.00),
    DeliveryZoneModel(id: "z4", name: "Amman Outskirts Delivery", nameAr: "ضواحي عمان الشرقية والجنوبية", fee: 3.50, minOrder: 10.00)
  ];

  @override
  Future<List<OrderModel>> getOrders() async {
    return _orders.where((o) => !o.isDeleted).toList();
  }

  @override
  Future<OrderModel> placeOrder(OrderModel order) async {
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = OrderModel(
        id: _orders[idx].id,
        orderNumber: _orders[idx].orderNumber,
        customerUid: _orders[idx].customerUid,
        customerName: _orders[idx].customerName,
        customerPhone: _orders[idx].customerPhone,
        items: _orders[idx].items,
        subtotal: _orders[idx].subtotal,
        deliveryFee: _orders[idx].deliveryFee,
        taxes: _orders[idx].taxes,
        discount: _orders[idx].discount,
        total: _orders[idx].total,
        paymentMethod: _orders[idx].paymentMethod,
        status: status,
        fulfillmentType: _orders[idx].fulfillmentType,
        address: _orders[idx].address,
        driverName: _orders[idx].driverName,
        driverPhone: _orders[idx].driverPhone,
        driverRating: _orders[idx].driverRating,
        createdAt: _orders[idx].createdAt,
        updatedAt: DateTime.now(),
        isDeleted: _orders[idx].isDeleted,
      );
    }
  }

  @override
  Future<List<DeliveryZoneModel>> getDeliveryZones() async {
    return _zones;
  }
}

class FirebaseOrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<List<OrderModel>> getOrders() async {
    final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _firestore
        .collection('orders')
        .where('customerUid', isEqualTo: uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<OrderModel> placeOrder(OrderModel order) async {
    // SECURITY TRANSITION: Client direct Firestore collection writes are disabled (create: if false).
    // All order calculation and creation is delegated to secure validateAndPlaceOrder Cloud Function.
    try {
      final callable = _functions.httpsCallable('validateAndPlaceOrder');

      // Defaults to Zone 1 (Shmeisani & Abdali). Detailed coordinates validated server-side.
      final String zoneId = "z1";

      final response = await callable.call({
        'items': order.items.map((item) => {
          'productId': item.productId,
          'quantity': item.quantity,
          'selectedSide': item.selectedSide,
        }).toList(),
        'zoneId': zoneId,
        'couponCode': null, // Coupons validated independently on checkout form
        'fulfillmentType': order.fulfillmentType.name,
        'address': order.address?.toMap(),
        'paymentMethod': order.paymentMethod.name,
        'customerName': order.customerName,
        'customerPhone': order.customerPhone,
      });

      final resultData = response.data;
      if (resultData == null || resultData['orderId'] == null) {
        throw Exception("Server failed to return an order processing confirmation.");
      }

      final String backendOrderId = resultData['orderId'];
      final String backendOrderNum = resultData['orderNumber'] ?? order.orderNumber;
      final double backendTotal = (resultData['total'] as num?)?.toDouble() ?? order.total;

      // Construct OrderModel reflecting the authoritative backend values
      return OrderModel(
        id: backendOrderId,
        orderNumber: backendOrderNum,
        customerUid: order.customerUid,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        items: order.items,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        taxes: order.taxes,
        discount: order.discount,
        total: backendTotal,
        paymentMethod: order.paymentMethod,
        status: OrderStatus.pending,
        fulfillmentType: order.fulfillmentType,
        address: order.address,
        driverName: order.driverName,
        driverPhone: order.driverPhone,
        driverRating: order.driverRating,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
      );
    } catch (e) {
      throw Exception("Tikka Cloud Checkout Failed: $e");
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<DeliveryZoneModel>> getDeliveryZones() async {
    try {
      final snap = await _firestore.collection('delivery_zones').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((doc) => DeliveryZoneModel.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (_) {
      // Fallback
    }

    return [
      DeliveryZoneModel(id: "z1", name: "Shmeisani & Abdali", nameAr: "الشميساني والعبدلي", fee: 1.50, minOrder: 5.00),
      DeliveryZoneModel(id: "z2", name: "Khalda & Tla' Al-Ali", nameAr: "خلدا وتلاع العلي", fee: 2.00, minOrder: 5.00),
      DeliveryZoneModel(id: "z3", name: "Dabouq & Al-Madinah", nameAr: "دابوق وشارع المدينة", fee: 2.50, minOrder: 7.00),
      DeliveryZoneModel(id: "z4", name: "Amman Outskirts Delivery", nameAr: "ضواحي عمان الشرقية والجنوبية", fee: 3.50, minOrder: 10.00)
    ];
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (AppConfig.isProduction) {
    return FirebaseOrderRepositoryImpl();
  } else {
    return StaticOrderRepositoryImpl();
  }
});

class OrdersListNotifier extends StateNotifier<List<OrderModel>> {
  final OrderRepository _repository;

  OrdersListNotifier(this._repository) : super([]) {
    refreshOrders();
  }

  Future<void> refreshOrders() async {
    state = await _repository.getOrders();
  }

  Future<OrderModel> submitOrder(OrderModel order) async {
    final newOrder = await _repository.placeOrder(order);
    await refreshOrders();
    return newOrder;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _repository.updateOrderStatus(orderId, status);
    await refreshOrders();
  }
}

final ordersNotifierProvider = StateNotifierProvider<OrdersListNotifier, List<OrderModel>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrdersListNotifier(repo);
});

final deliveryZonesProvider = FutureProvider<List<DeliveryZoneModel>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getDeliveryZones();
});
