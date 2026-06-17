import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/locale_service.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeSvc = ref.watch(localeProvider.notifier);
    final orders = ref.watch(ordersNotifierProvider);

    if (orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(localeSvc.translate("Order Tracker", "تتبع الطلبات القائمة"))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delivery_dining_rounded, size: 72, color: ArtisanalColors.outline),
                const SizedBox(height: 16),
                Text(
                  localeSvc.translate(
                    "You do not have any pending orders.",
                    "لا توجد طلبات جاري نقلها أو إعدادها حالياً.",
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ArtisanalColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text(localeSvc.translate("Back to Charcoal Grill", "الرجوع للفرن الرئيسي")),
                )
              ],
            ),
          ),
        ),
      );
    }

    // Get latest active order
    final OrderModel latestOrder = orders.first;

    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      appBar: AppBar(
        title: Text(
          "${localeSvc.translate("Tracking Order", "تتبع الطلب")} #${latestOrder.orderNumber}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: ArtisanalColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localeSvc.translate("Estimated Arrival", "وقت الوصول المتوقع"),
                              style: const TextStyle(fontSize: 12, color: ArtisanalColors.onSurfaceVariant),
                            ),
                            const Text(
                              "25 - 35 mins",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: ArtisanalColors.secondary),
                            ),
                          ],
                        ),
                        // Status badge text
                        Chip(
                          backgroundColor: _getStatusColor(latestOrder.status).withOpacity(0.15),
                          side: BorderSide.none,
                          label: Text(
                            localeSvc.translate(
                              latestOrder.status.name.toUpperCase(),
                              _translateStatusAr(latestOrder.status),
                            ),
                            style: TextStyle(
                              color: _getStatusColor(latestOrder.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localeSvc.translate("Status Summary:", "حالة الطلب الحالية:"),
                          style: const TextStyle(fontSize: 12, color: ArtisanalColors.onSurfaceVariant),
                        ),
                        Text(
                          _getDisplayStatusHelp(latestOrder.status, localeSvc),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stepped tracking animation nodes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localeSvc.translate("Delivery Steps", "خطوات التحضير والتوصيل"),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ArtisanalColors.primary),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTrackingStep(
                      context: context,
                      title: localeSvc.translate("Order Received", "تم استلام الطلب"),
                      subtitle: localeSvc.translate("Sent to Charcoal Kitchen", "تم تمريره لفرن التندور للبدء"),
                      isActive: latestOrder.status == OrderStatus.pending,
                      isCompleted: latestOrder.status.index >= OrderStatus.pending.index,
                    ),
                    _buildTrackingStep(
                      context: context,
                      title: localeSvc.translate("Accepted", "تم قبول الطلب"),
                      subtitle: localeSvc.translate("Restaurant has approved the checkout", "تم مراجعة الطلب واعتماده بالكامل"),
                      isActive: latestOrder.status == OrderStatus.accepted,
                      isCompleted: latestOrder.status.index >= OrderStatus.accepted.index,
                    ),
                    _buildTrackingStep(
                      context: context,
                      title: localeSvc.translate("Preparing Meal", "جاري إعداد وتحضير شواء الدجاج"),
                      subtitle: localeSvc.translate("Cooked over natural coal embers", "يتم تسويته على جمر فحم السنديان الطبيعي"),
                      isActive: latestOrder.status == OrderStatus.preparing,
                      isCompleted: latestOrder.status.index >= OrderStatus.preparing.index,
                    ),
                    _buildTrackingStep(
                      context: context,
                      title: localeSvc.translate("Ready", "الطلب جاهز"),
                      subtitle: localeSvc.translate("Fully packaged and insulated", "الشواء جاهز ومنسق في الحافظات الحرارية"),
                      isActive: latestOrder.status == OrderStatus.ready,
                      isCompleted: latestOrder.status.index >= OrderStatus.ready.index,
                    ),
                    _buildTrackingStep(
                      context: context,
                      title: localeSvc.translate("Out For Delivery", "طلبك مع سائق التوصيل"),
                      subtitle: localeSvc.translate("Fresh thermal bag packaging", "تم تسليم الطلب للسائق للعنوان المطلوب"),
                      isActive: latestOrder.status == OrderStatus.out_for_delivery,
                      isCompleted: latestOrder.status.index >= OrderStatus.out_for_delivery.index,
                    ),
                    _buildTrackingStep(
                      context: context,
                      title: localeSvc.translate("Delivered Safe", "تم تسليم الشواء بنجاح"),
                      subtitle: localeSvc.translate("Sahtain & Health!", "بالهناء والشفاء! صحتين وعافية"),
                      isActive: latestOrder.status == OrderStatus.delivered,
                      isCompleted: latestOrder.status.index >= OrderStatus.delivered.index,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Map Simulator Visual
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFE2EBF1),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;

                        final startLat = 31.9530;
                        final startLng = 35.8570;
                        
                        double ratio = 0.0;
                        if (latestOrder.driverLocation != null) {
                          final destLat = latestOrder.address?.coordinates['lat'] ?? 31.9539;
                          final destLng = latestOrder.address?.coordinates['lng'] ?? 35.8576;
                          final currentLat = latestOrder.driverLocation!['lat'] ?? startLat;
                          final currentLng = latestOrder.driverLocation!['lng'] ?? startLng;

                          final totalDist = (destLat - startLat).abs() + (destLng - startLng).abs();
                          if (totalDist > 0) {
                            final currentDist = (currentLat - startLat).abs() + (currentLng - startLng).abs();
                            ratio = (currentDist / totalDist).clamp(0.0, 1.0);
                          }
                        } else if (latestOrder.status == OrderStatus.delivered) {
                          ratio = 1.0;
                        }

                        // Driver marker positioned offset coordinates along dashed path
                        final startOffset = Offset(w * 0.15, h * 0.15);
                        final endOffset = Offset(w * 0.75, h * 0.75);
                        final markerOffset = Offset(
                          startOffset.dx + (endOffset.dx - startOffset.dx) * ratio,
                          startOffset.dy + (endOffset.dy - startOffset.dy) * ratio,
                        );

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _RoadMapPainter(),
                              ),
                            ),
                            Positioned(
                              left: markerOffset.dx - 20,
                              top: markerOffset.dy - 25,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: ArtisanalColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                    ),
                                    child: Text(
                                      latestOrder.status == OrderStatus.delivered
                                          ? localeSvc.translate("Arrived Safe", "وصل بسلام")
                                          : latestOrder.status == OrderStatus.out_for_delivery
                                              ? "${(ratio * 100).toStringAsFixed(0)}% ${localeSvc.translate("Dispatched", "في الطريق")}"
                                              : localeSvc.translate("Preparing", "تحت التجهيز"),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: ArtisanalColors.primary,
                      child: Icon(Icons.sports_motorsports, color: Colors.white),
                    ),
                    title: Text(latestOrder.driverName ?? "Kamil Al-Dajani"),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          (latestOrder.driverRating ?? 4.8).toString(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          latestOrder.driverPhone ?? "079-1234567",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cancel Order button (Available in Pending status only)
            if (latestOrder.status == OrderStatus.pending || latestOrder.status == OrderStatus.preparing)
              OutlinedButton(
                onPressed: () {
                  ref.read(ordersNotifierProvider.notifier).updateStatus(latestOrder.id, OrderStatus.canceled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        localeSvc.translate("Order canceled successfully.", "تم إلغاء الطلب وسحب الشواء بنجاح."),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArtisanalColors.error,
                  side: const BorderSide(color: ArtisanalColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  localeSvc.translate("Cancel Order Request", "إلغاء هذا الطلب"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

            // Post-Delivery Review Card (Visible only when Arrived/Delivered)
            if (latestOrder.status == OrderStatus.delivered) ...[
              _OrderReviewWidget(order: latestOrder, localeSvc: localeSvc),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted: return Colors.teal;
      case OrderStatus.preparing: return Colors.orange;
      case OrderStatus.ready: return Colors.amber;
      case OrderStatus.out_for_delivery: return Colors.blue;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.canceled: return ArtisanalColors.error;
      default: return ArtisanalColors.outline;
    }
  }

  String _translateStatusAr(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'تم الاستلام';
      case OrderStatus.accepted: return 'مقبول وبانتظار التحضير';
      case OrderStatus.preparing: return 'تحت الشواء والتحضير';
      case OrderStatus.ready: return 'الطلب جاهز للتسليم';
      case OrderStatus.out_for_delivery: return 'مع السائق على الطريق';
      case OrderStatus.delivered: return 'تم التوصيل بأمان';
      case OrderStatus.canceled: return 'تم الإلغاء';
    }
  }

  String _getDisplayStatusHelp(OrderStatus status, localeSvc) {
    switch (status) {
      case OrderStatus.pending:
        return localeSvc.translate("Awaiting restaurant approval", "بانتظار تأكيد الاستلام من الإدارة");
      case OrderStatus.accepted:
        return localeSvc.translate("Restaurant approved order", "تم قبول الطلب وجاري توجيهه للمطابخ");
      case OrderStatus.preparing:
        return localeSvc.translate("Chef slowly grilling raw skewers", "يقوم الطاهي بمراقبة شواء الأسياخ على الفحم");
      case OrderStatus.ready:
        return localeSvc.translate("Order is ready", "الطلب جاهز ولذيذ وبانتظار السائق");
      case OrderStatus.out_for_delivery:
        return localeSvc.translate("Sailing through traffic in insulated bag", "الطلب غادر الفرن في حافظة السائق الحرارية");
      case OrderStatus.delivered:
        return localeSvc.translate("Delivered with love", "تم توصيله لعنوان السكن بنجاح وصحتين وعافية");
      case OrderStatus.canceled:
        return localeSvc.translate("Order canceled", "تم إلغاء الطلب بنجاح");
    }
  }

  Widget _buildTrackingStep({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepped Line connector Column
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? ArtisanalColors.secondary : Colors.grey[300],
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: ArtisanalColors.primary, width: 3)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 48,
                color: isCompleted ? ArtisanalColors.secondary : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content descriptions
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                    color: isCompleted ? ArtisanalColors.primary : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted ? ArtisanalColors.onSurfaceVariant : Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoadMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.4)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Draw main highways
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.6, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.7), paint);

    // Draw secondary roads
    paint.strokeWidth = 8;
    paint.color = Colors.white.withOpacity(0.9);
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.2), Offset(size.width * 0.9, size.height * 0.9), paint);

    // Draw dashed vehicle routing track
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.35), Offset(size.width * 0.5, size.height * 0.5), dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderReviewWidget extends StatefulWidget {
  final OrderModel order;
  final LocaleService localeSvc;

  const _OrderReviewWidget({
    required this.order,
    required this.localeSvc,
  });

  @override
  State<_OrderReviewWidget> createState() => _OrderReviewWidgetState();
}

class _OrderReviewWidgetState extends State<_OrderReviewWidget> {
  bool _submitted = false;
  double _rating = 5.0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.localeSvc;

    return Card(
      color: ArtisanalColors.primary.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ArtisanalColors.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _submitted
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    locale.translate("Thank you for your feedback!", "شكراً جزيلاً لتقييمك!"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ArtisanalColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale.translate("Sahtain & Health!", "بالهناء والشفاء! صحتين وعافية على قلبك."),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locale.translate("Rate Your Tikka Order", "تقييم وجبة التندور والتوصيل"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ArtisanalColors.primary),
                  ),
                  Text(
                    locale.translate("Let us know how your charcoal grill tasted!", "شاركنا رأيك في طعم مشاوي التندور اليوم!"),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: locale.translate("Write an optional comment...", "اكتب تعليقاً إضافياً (اختياري)..."),
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final docRef = FirebaseFirestore.instance.collection("reviews").doc();
                        await docRef.set({
                          'id': docRef.id,
                          'orderId': widget.order.id,
                          'rating': _rating,
                          'comment': _commentController.text.trim(),
                          'customerUid': widget.order.customerUid,
                          'customerName': widget.order.customerName,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        setState(() {
                          _submitted = true;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to submit review: $e")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtisanalColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      locale.translate("Submit Review", "إرسال التقييم"),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
