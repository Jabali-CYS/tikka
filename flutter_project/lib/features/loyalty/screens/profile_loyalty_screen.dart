import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/locale_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/models/user_model.dart';
import '../../order/repositories/order_repository.dart';

class ProfileLoyaltyScreen extends ConsumerWidget {
  const ProfileLoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeSvc = ref.watch(localeProvider.notifier);
    final user = ref.watch(authStateProvider);
    final orders = ref.watch(ordersNotifierProvider);

    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      appBar: AppBar(
        title: Text(
          localeSvc.translate("Loyalty Rewards Club", "نادي الولاء والجوائز"),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: ArtisanalColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Loyalty Member Status Rank Card
            _buildClubCard(context, user, localeSvc),
            const SizedBox(height: 24),

            // Tier Progress section
            if (user != null) ...[
              _buildProgressIndicator(context, user, localeSvc),
              const SizedBox(height: 24),
            ],

            // History Header
            Text(
              localeSvc.translate("Order History Logs", "تاريخ وقائمة الطلبات السابقة"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ArtisanalColors.primary),
            ),
            const SizedBox(height: 12),

            // Historic Orders logs
            orders.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: ArtisanalColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history, size: 40, color: ArtisanalColors.outline),
                          const SizedBox(height: 8),
                          Text(
                            localeSvc.translate("No orders found.", "لا توجد أي سجلات مسبقة."),
                            style: const TextStyle(color: ArtisanalColors.outline),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: const CircleAvatar(
                            backgroundColor: ArtisanalColors.primaryFixed,
                            child: Icon(Icons.local_fire_department, color: ArtisanalColors.primary),
                          ),
                          title: Text(
                            "${localeSvc.translate("Order", "طلب")} #${order.orderNumber}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${order.total.toStringAsFixed(2)} JOD • ${order.createdAt.toLocal().toString().split(' ')[0]}"),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              localeSvc.translate(order.status.name.toUpperCase(), _translateStatusAr(order.status)),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...order.items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("${item.quantity}x ${localeSvc.translate(item.title, item.titleAr)}"),
                                          Text("${item.totalPrice.toStringAsFixed(2)} JOD"),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(localeSvc.translate("Subtotal", "مجموع الوجبات")),
                                      Text("${order.subtotal.toStringAsFixed(2)} JOD"),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(localeSvc.translate("Delivery Fee", "أجور السائق")),
                                      Text("${order.deliveryFee.toStringAsFixed(2)} JOD"),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(localeSvc.translate("Sales Tax (16%)", "ضريبة المبيعات")),
                                      Text("${order.taxes.toStringAsFixed(2)} JOD"),
                                    ],
                                  ),
                                  if (order.discount > 0.0)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(localeSvc.translate("Discount", "الخصم المطبق"), style: const TextStyle(color: Colors.green)),
                                        Text("-${order.discount.toStringAsFixed(2)} JOD", style: const TextStyle(color: Colors.green)),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(localeSvc.translate("Grand Total", "الصافي المستلم"), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text("${order.total.toStringAsFixed(2)} JOD", style: const TextStyle(fontWeight: FontWeight.bold, color: ArtisanalColors.secondary)),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 32),

            // Logout row button
            OutlinedButton.icon(
              onPressed: () {
                ref.read(authStateProvider.notifier).logOut();
                context.go('/language');
              },
              icon: const Icon(Icons.logout_rounded),
              style: OutlinedButton.styleFrom(
                foregroundColor: ArtisanalColors.error,
                side: const BorderSide(color: ArtisanalColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: Text(localeSvc.translate("Log Out of App", "تسجيل خروج بالكامل")),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildClubCard(BuildContext context, UserModel? user, LocaleService localeSvc) {
    final status = user?.memberStatus ?? MemberStatus.bronze;
    Color gradientStart = const Color(0xFFCD7F32); // Bronze metallic
    Color gradientEnd = const Color(0xFF8B4513);
    String statusLabel = localeSvc.translate("Bronze Member", "العضوية البرونزية الكلاسيكية");

    if (status == MemberStatus.gold) {
      gradientStart = const Color(0xFFFFD700); // Gold metallic
      gradientEnd = const Color(0xFFD4AF37);
      statusLabel = localeSvc.translate("Gold Club Elite", "النخبة الذهبية للتندور");
    } else if (status == MemberStatus.silver) {
      gradientStart = const Color(0xFFC0C0C0); // Silver metallic
      gradientEnd = const Color(0xFF808080);
      statusLabel = localeSvc.translate("Silver Club Elite", "النادي الفضي المميز");
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientEnd.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background abstract patterns
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.stars,
              size: 160,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        fontFamily: "Space Grotesk",
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Icon(Icons.local_fire_department, color: Colors.white),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localeSvc.translate("CURRENT POINTS BUDGET", "ميزانية نقاط الولاء المتوفرة"),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user != null ? "${user.points} pts" : "0 pts",
                      style: const TextStyle(
                        fontFamily: "JetBrains Mono",
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user?.name ?? localeSvc.translate("Guest User", "مستكشف تندور كريم"),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user != null ? "ID: ${user.uid.substring(0, 8)}" : "ID: Guest",
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, UserModel user, LocaleService localeSvc) {
    // Current tier calculations (Bronze max 10000, Silver max 30000, Gold is maxed out)
    double progressValue = 1.0;
    String nextTier = localeSvc.translate("Max Elite Rank achieved!", "لقد وصلت لأعلى مرتبة تندورية!");
    int pointsToNext = 0;

    if (user.memberStatus == MemberStatus.bronze) {
      progressValue = user.points / 10000.0;
      nextTier = localeSvc.translate("Silver Club Elite", "المرتبة الفضية الممتازة");
      pointsToNext = 10000 - user.points;
    } else if (user.memberStatus == MemberStatus.silver) {
      progressValue = user.points / 30000.0;
      nextTier = localeSvc.translate("Gold Club Elite", "المرتبة الذهبية المطلقة");
      pointsToNext = 30000 - user.points;
    }

    if (progressValue > 1.0) progressValue = 1.0;

    return Card(
      elevation: 0,
      color: ArtisanalColors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localeSvc.translate("Next Tier Progress", "التقدم نحو العضوية التالية"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  nextTier,
                  style: const TextStyle(color: ArtisanalColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[350],
              color: ArtisanalColors.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            if (pointsToNext > 0)
              Text(
                "${localeSvc.translate("You are only", "تفصلك فقط")} $pointsToNext ${localeSvc.translate("points away! Spent more to claim extra gifts.", "نقاط فقط! استمر في الشراء لمكافآت مجانية.")}",
                style: const TextStyle(fontSize: 11, color: ArtisanalColors.onSurfaceVariant),
              ),
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
      case OrderStatus.accepted: return 'مقبول للتحضير';
      case OrderStatus.preparing: return 'تحت الشواء';
      case OrderStatus.ready: return 'جاهز للتسليم';
      case OrderStatus.out_for_delivery: return 'مع الدليفري';
      case OrderStatus.delivered: return 'تم التوصيل';
      case OrderStatus.canceled: return 'تم الإلغاء';
    }
  }
}
