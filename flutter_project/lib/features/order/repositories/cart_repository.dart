import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../../menu/models/product_model.dart';
import '../../loyalty/models/coupon_model.dart';

class CartState {
  final List<OrderItem> items;
  final double deliveryFee;
  final CouponModel? appliedCoupon;
  final int redeemedPoints;
  final bool taxEnabled;

  CartState({
    required this.items,
    this.deliveryFee = 0.0,
    this.appliedCoupon,
    this.redeemedPoints = 0,
    this.taxEnabled = false,
  });

  CartState copyWith({
    List<OrderItem>? items,
    double? deliveryFee,
    CouponModel? appliedCoupon,
    int? redeemedPoints,
    bool? taxEnabled,
  }) {
    return CartState(
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      redeemedPoints: redeemedPoints ?? this.redeemedPoints,
      taxEnabled: taxEnabled ?? this.taxEnabled,
    );
  }

  double get subtotal {
    double total = 0.0;
    for (var item in items) {
      total += item.totalPrice;
    }
    return total;
  }

  double get taxes {
    return taxEnabled ? (subtotal * 0.16) : 0.0; // 16% Jordan General Sales Tax
  }

  double get discount {
    double value = 0.0;
    if (appliedCoupon != null) {
      if (appliedCoupon!.discountType == DiscountType.percentage) {
        value += (subtotal * (appliedCoupon!.value / 100));
      } else {
        value += appliedCoupon!.value;
      }
    }
    if (redeemedPoints > 0) {
      // 100 points = 1.0 JOD discount
      value += (redeemedPoints / 100.0);
    }
    return value > (subtotal + taxes) ? (subtotal + taxes) : value;
  }

  double get totalAmount {
    final amt = (subtotal + deliveryFee + taxes - discount);
    return amt < 0.0 ? 0.0 : amt;
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(items: []));

  void addItem({
    required ProductModel product,
    required int quantity,
    required String spiciness,
    required ProductSideOption? selectedSide,
  }) {
    final sidePrice = selectedSide?.price ?? 0.0;
    final singlePrice = product.price + sidePrice;
    final totalPrice = singlePrice * quantity;

    final existingIndex = state.items.indexWhere((item) =>
        item.productId == product.id &&
        item.selectedSpiciness == spiciness &&
        item.selectedSide == (selectedSide?.id ?? ''));

    if (existingIndex != -1) {
      // Update existing item
      final List<OrderItem> updatedItems = List.from(state.items);
      final currentItem = updatedItems[existingIndex];
      final newQuantity = currentItem.quantity + quantity;
      
      updatedItems[existingIndex] = OrderItem(
        productId: product.id,
        title: product.title,
        titleAr: product.titleAr,
        quantity: newQuantity,
        selectedSpiciness: spiciness,
        selectedSide: selectedSide?.id ?? '',
        sidePrice: sidePrice,
        totalPrice: singlePrice * newQuantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = OrderItem(
        productId: product.id,
        title: product.title,
        titleAr: product.titleAr,
        quantity: quantity,
        selectedSpiciness: spiciness,
        selectedSide: selectedSide?.id ?? '',
        sidePrice: sidePrice,
        totalPrice: totalPrice,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void removeItem(OrderItem targetItem) {
    state = state.copyWith(
      items: state.items.where((item) => item != targetItem).toList(),
    );
  }

  void updateQuantity(OrderItem targetItem, int delta) {
    final idx = state.items.indexOf(targetItem);
    if (idx != -1) {
      final newQty = state.items[idx].quantity + delta;
      if (newQty <= 0) {
        removeItem(targetItem);
      } else {
        final List<OrderItem> updatedItems = List.from(state.items);
        final itemPrice = (targetItem.totalPrice / targetItem.quantity);
        updatedItems[idx] = OrderItem(
          productId: targetItem.productId,
          title: targetItem.title,
          titleAr: targetItem.titleAr,
          quantity: newQty,
          selectedSpiciness: targetItem.selectedSpiciness,
          selectedSide: targetItem.selectedSide,
          sidePrice: targetItem.sidePrice,
          totalPrice: itemPrice * newQty,
        );
        state = state.copyWith(items: updatedItems);
      }
    }
  }

  void setDeliveryFee(double fee) {
    state = state.copyWith(deliveryFee: fee);
  }

  void applyCoupon(CouponModel? coupon) {
    state = state.copyWith(appliedCoupon: coupon);
  }

  void setRedeemedPoints(int points) {
    state = state.copyWith(redeemedPoints: points);
  }

  void toggleTax(bool enabled) {
    state = state.copyWith(taxEnabled: enabled);
  }

  void clear() {
    state = CartState(items: [], deliveryFee: 0.0);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
