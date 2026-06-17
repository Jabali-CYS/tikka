import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/locale_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../loyalty/models/coupon_model.dart';
import '../repositories/order_repository.dart';
import '../repositories/cart_repository.dart';
import '../models/order_model.dart';
import '../models/delivery_zone_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  DeliveryZoneModel? _selectedZone;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _couponController = TextEditingController();
  final _streetController = TextEditingController(text: "Al-Madina Al-Munawwarah St");
  final _buildingController = TextEditingController(text: "Building 45");
  final _floorController = TextEditingController(text: "3rd Floor");
  final _apartmentController = TextEditingController(text: "Apt 12");
  final _instructionsController = TextEditingController();

  bool _isPointsApplied = false;
  String _promoFeedback = "";
  bool _isSubmitting = false;

  @override
  void dispose() {
    _couponController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _applyCouponCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    final localeSvc = ref.read(localeProvider.notifier);

    if (cleanCode.isEmpty) {
      ref.read(cartProvider.notifier).applyCoupon(null);
      setState(() => _promoFeedback = "");
      return;
    }

    // Static verify coupon code rules
    if (cleanCode == "COAL15" || cleanCode == "WELCOMETANDOOR") {
      final coupon = CouponModel(
        id: "promo-1",
        code: cleanCode,
        discountType: DiscountType.percentage,
        value: 15.0, // 15% discount
        minOrder: 5.0,
        description: "15% off your first charcoal order!",
        descriptionAr: "خصم كلاسيكي بقيمة 15% على الوجبات الساخنة!",
      );
      ref.read(cartProvider.notifier).applyCoupon(coupon);
      setState(() {
        _promoFeedback = localeSvc.translate("Promo code applied: 15% discount!", "تم تطبيق الكود: خصم بقيمة 15%!");
      });
    } else {
      ref.read(cartProvider.notifier).applyCoupon(null);
      setState(() {
        _promoFeedback = localeSvc.translate("Invalid promo code.", "الرمز المدخل غير فعال.");
      });
    }
  }

  void _submitOrder() async {
    final localeSvc = ref.read(localeProvider.notifier);
    final user = ref.read(authStateProvider);
    final cart = ref.read(cartProvider);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localeSvc.translate("Your basket is empty.", "سلتك فارغة حالياً."))),
      );
      return;
    }

    if (_selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeSvc.translate("Please select a delivery zone.", "يرجى اختيار حي التوصيل لتأكيد الحسبة."),
          ),
          backgroundColor: ArtisanalColors.secondary,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate database post latency
    await Future.delayed(const Duration(milliseconds: 1200));

    final String generatedId = "ord-${Random().nextInt(900000) + 100000}";
    final String generatedNumber = "GCT-${Random().nextInt(9000) + 1000}";

    final newOrder = OrderModel(
      id: generatedId,
      orderNumber: generatedNumber,
      customerUid: user?.uid ?? "uid-sandbox-guest",
      customerName: user?.name ?? "Amman Guest Client",
      customerPhone: user?.phone ?? "0790000000",
      items: cart.items,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      taxes: cart.taxes,
      discount: cart.discount,
      total: cart.totalAmount,
      paymentMethod: _paymentMethod,
      status: OrderStatus.pending,
      fulfillmentType: FulfillmentType.delivery,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      address: OrderAddress(
        street: _streetController.text,
        buildingName: _buildingController.text,
        floor: _floorController.text,
        apartment: _apartmentController.text,
        instructions: _instructionsController.text,
        coordinates: {"lat": 31.9522, "lng": 35.9150}, // Default Amman coordinates
      ),
    );

    // Add order to list notifier
    await ref.read(ordersNotifierProvider.notifier).submitOrder(newOrder);

    // Subtract points if user redeemed and points are available
    if (_isPointsApplied && user != null) {
      ref.read(authStateProvider.notifier).redeemPoints(cart.redeemedPoints);
    } else if (user != null) {
      // Award points for buying (10% of total converted to integer points, e.g. 10 JOD spends = 100 points)
      final int addedPoints = (newOrder.total * 10).toInt();
      ref.read(authStateProvider.notifier).addPoints(addedPoints);
    }

    // Flush active cart tray
    ref.read(cartProvider.notifier).clear();

    if (mounted) {
      setState(() => _isSubmitting = false);
      context.go('/order-tracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeSvc = ref.watch(localeProvider.notifier);
    final user = ref.watch(authStateProvider);
    final cart = ref.watch(cartProvider);
    final zonesAsync = ref.watch(deliveryZonesProvider);

    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      appBar: AppBar(
        title: Text(
          localeSvc.translate("Checkout Basket", "تأكيد واستكمال الطلب"),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: ArtisanalColors.primary,
        foregroundColor: Colors.white,
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 72, color: ArtisanalColors.outline),
                  const SizedBox(height: 16),
                  Text(
                    localeSvc.translate("Your basket is currently empty.", "سلتك لا تحتوي على أي وجبات تندورية حالياً."),
                    style: const TextStyle(fontSize: 16, color: ArtisanalColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: Text(localeSvc.translate("Return to Grill Menu", "العودة لقائمة الطعام")),
                  )
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice Order Items lists
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localeSvc.translate("Selected Delicacies", "الوجبات المختارة"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ArtisanalColors.primary),
                          ),
                          const Divider(),
                          ...cart.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: ArtisanalColors.primaryFixed,
                                    radius: 12,
                                    child: Text(
                                      "${item.quantity}x",
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ArtisanalColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          localeSvc.translate(item.title, item.titleAr),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "${localeSvc.translate("Spicy", "درجة الاستواء")}: ${localeSvc.translate(item.selectedSpiciness, _translateSpicinessAr(item.selectedSpiciness))}",
                                          style: const TextStyle(fontSize: 11, color: ArtisanalColors.onSurfaceVariant),
                                        ),
                                        if (item.selectedSide.isNotEmpty)
                                          Text(
                                            "${localeSvc.translate("Side", "الطبق الجانبي")}: ${item.selectedSide.toUpperCase()}",
                                            style: const TextStyle(fontSize: 11, color: ArtisanalColors.onSurfaceVariant),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${item.totalPrice.toStringAsFixed(2)} JOD",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery Zone Choice
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localeSvc.translate("Delivery Service Zone", "منطقة التوصيل الجغرافي"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ArtisanalColors.primary),
                          ),
                          const SizedBox(height: 12),
                          zonesAsync.maybeWhen(
                            data: (zones) => DropdownButtonFormField<DeliveryZoneModel>(
                              decoration: InputDecoration(
                                labelText: localeSvc.translate("Choose Amman Zone", "اختر من أحياء عمان"),
                                border: const OutlineInputBorder(),
                              ),
                              value: _selectedZone,
                              items: zones.map((z) {
                                return DropdownMenuItem(
                                  value: z,
                                  child: Text(
                                    "${localeSvc.translate(z.name, z.nameAr)} (+${z.fee.toStringAsFixed(2)} JOD)",
                                  ),
                                );
                              }).toList(),
                              onChanged: (zone) {
                                setState(() {
                                  _selectedZone = zone;
                                  if (zone != null) {
                                    ref.read(cartProvider.notifier).setDeliveryFee(zone.fee);
                                  }
                                });
                              },
                            ),
                            orElse: () => const LinearProgressIndicator(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address Input fields
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localeSvc.translate("Delivery Address details", "تفاصيل عنوان السكن"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ArtisanalColors.primary),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _streetController,
                            decoration: InputDecoration(
                              labelText: localeSvc.translate("Street Name", "اسم الشارع"),
                              prefixIcon: const Icon(Icons.streetview),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _buildingController,
                                  decoration: InputDecoration(
                                    labelText: localeSvc.translate("Building No.", "رقم البناية"),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _floorController,
                                  decoration: InputDecoration(
                                    labelText: localeSvc.translate("Floor Number", "الطابق"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _instructionsController,
                            decoration: InputDecoration(
                              labelText: localeSvc.translate("Special instructions (e.g. Ring Bell)", "ملاحظات إرشادية للسائق"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Loyalty Points & Coupons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localeSvc.translate("Promo Coupon / Loyalty Points", "قسيمة خصم أو نقاط المكافأة"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ArtisanalColors.primary),
                          ),
                          const Divider(),
                          // Coupon input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  decoration: InputDecoration(
                                    hintText: localeSvc.translate("Coupon Code (COAL15)", "أدخل كود القسيمة (مثال: COAL15)"),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  _applyCouponCode(_couponController.text);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(80, 56),
                                ),
                                child: Text(localeSvc.translate("Apply", "تطبيق")),
                              ),
                            ],
                          ),
                          if (_promoFeedback.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _promoFeedback,
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Loyalty Points Toggle if authenticated
                          if (user != null && user.points > 100) ...[
                            CheckboxListTile(
                              title: Text(
                                localeSvc.translate("Redeem Reward Club Points", "استبدال نقاط الولاء للنادي الذهبي"),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                localeSvc.translate(
                                  "You have ${user.points} points. Convert 1,000 points to save 10.00 JOD cash discount!",
                                  "لديك ${user.points} نقطة. استبدل 1000 نقطة لتوفير خصم مالي بقيمة 10 دنانير!",
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: _isPointsApplied,
                              onChanged: (val) {
                                if (val == true) {
                                  // Max redeem 1000 points (10 JOD) or user's point total
                                  final convertedPoints = min(user.points, 1000);
                                  ref.read(cartProvider.notifier).setRedeemedPoints(convertedPoints);
                                } else {
                                  ref.read(cartProvider.notifier).setRedeemedPoints(0);
                                }
                                setState(() {
                                  _isPointsApplied = val ?? false;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Invoice Breakdown
                  Card(
                    color: ArtisanalColors.primary.withOpacity(0.04),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInvoiceLabel(localeSvc.translate("Subtotal", "مجموع الوجبات"), "${cart.subtotal.toStringAsFixed(2)} JOD"),
                          _buildInvoiceLabel(localeSvc.translate("Delivery Service Fee", "أجور توصيل السائق"), "${cart.deliveryFee.toStringAsFixed(2)} JOD"),
                          _buildInvoiceLabel(localeSvc.translate("Sales Tax (16%)", "ضريبة المبيعات العامة"), "${cart.taxes.toStringAsFixed(2)} JOD"),
                          if (cart.discount > 0.0)
                            _buildInvoiceLabel(
                              localeSvc.translate("Member Reward Save", "وفورات خصومات النادي"),
                              "-${cart.discount.toStringAsFixed(2)} JOD",
                              textColor: Colors.green,
                              isBold: true,
                            ),
                          const Divider(height: 24),
                          _buildInvoiceLabel(
                            localeSvc.translate("Grand Total", "الصافي المطلوب دفعه"),
                            "${cart.totalAmount.toStringAsFixed(2)} JOD",
                            textColor: ArtisanalColors.secondary,
                            isBold: true,
                            fontSize: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Place Order Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtisanalColors.secondary,
                      minimumSize: const Size.fromHeight(60),
                    ),
                    child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          localeSvc.translate("Place Cash On Delivery Order", "إرسال طلب التوصيل الفوري"),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInvoiceLabel(
    String title,
    String value, {
    Color? textColor,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: fontSize, color: isBold ? null : ArtisanalColors.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? ArtisanalColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _translateSpicinessAr(String opt) {
    switch (opt.toLowerCase()) {
      case 'mild': return 'خفيف';
      case 'medium': return 'متوسط';
      case 'hot': return 'حار جداً';
      default: return 'قياسي';
    }
  }
}
