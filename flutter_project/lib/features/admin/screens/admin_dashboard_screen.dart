import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/locale_service.dart';
import '../../menu/models/product_model.dart';
import '../../menu/repositories/menu_repository.dart';
import '../../order/models/order_model.dart';
import '../../order/repositories/order_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // Local controllers for adding new charcoal skewer products
  final _prodTitleController = TextEditingController();
  final _prodTitleArController = TextEditingController();
  final _prodDescController = TextEditingController();
  final _prodDescArController = TextEditingController();
  final _prodPriceController = TextEditingController();
  final _prodImageController = TextEditingController(text: "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&q=80&w=600");
  
  String _selectedCategory = "grill";
  bool _isPopular = false;
  bool _isHerbal = false;

  void _addNewProduct() async {
    final title = _prodTitleController.text.trim();
    final titleAr = _prodTitleArController.text.trim();
    final desc = _prodDescController.text.trim();
    final descAr = _prodDescArController.text.trim();
    final priceStr = _prodPriceController.text.trim();
    final img = _prodImageController.text.trim();

    if (title.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Base price cannot be empty.")),
      );
      return;
    }

    final double price = double.tryParse(priceStr) ?? 0.0;

    final newProd = ProductModel(
      id: "g-${Random().nextInt(900) + 100}",
      title: title,
      titleAr: titleAr.isEmpty ? title : titleAr,
      description: desc.isEmpty ? "Authentic charcoal grilled item." : desc,
      descriptionAr: descAr.isEmpty ? titleAr : descAr,
      price: price,
      categoryId: _selectedCategory,
      image: img.isEmpty 
          ? "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&q=80&w=600"
          : img,
      isPopular: _isPopular,
      isHerbal: _isHerbal,
      spicyOptions: ["Mild", "Medium", "Hot"],
      sideOptions: [
        ProductSideOption(id: "naan", name: "Butter Naan", nameAr: "نان بالزبدة", price: 0.0, image: ""),
      ],
    );

    // Save product to Repository
    await ref.read(menuRepositoryProvider).addProduct(newProd);
    
    // Refresh the Provider
    ref.invalidate(productsProvider);

    // Reset fields
    _prodTitleController.clear();
    _prodTitleArController.clear();
    _prodDescController.clear();
    _prodDescArController.clear();
    _prodPriceController.clear();

    if (mounted) {
      setState(() {
        _isPopular = false;
        _isHerbal = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tandoor item added directly to active customer catalog!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteProductItem(String id) async {
    await ref.read(menuRepositoryProvider).deleteProduct(id);
    ref.invalidate(productsProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item disabled/removed from customer menu."), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _prodTitleController.dispose();
    _prodTitleArController.dispose();
    _prodDescController.dispose();
    _prodDescArController.dispose();
    _prodPriceController.dispose();
    _prodImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeSvc = ref.watch(localeProvider.notifier);
    final orders = ref.watch(ordersNotifierProvider);
    final productsAsync = ref.watch(productsProvider);

    // Calculate Admin stats metrics
    final double grossRevenue = orders
        .where((o) => o.status != OrderStatus.canceled)
        .fold(0.0, (sum, order) => sum + order.total);
    final int activeOrdersCount = orders
        .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.canceled)
        .length;

    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      appBar: AppBar(
        title: const Text(
          "TANDOOR GRILL RESTAURANT PORTAL (WEB ADMIN)",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
        ),
        backgroundColor: ArtisanalColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: "Customer Menu view",
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar Panels - Metrics & Menu Manager
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Cards Section
                  Text(
                    "REALTIME METRICS",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: ArtisanalColors.outline),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: "Gross Revenue (JOD)",
                          value: "${grossRevenue.toStringAsFixed(2)} JOD",
                          color: Colors.green,
                          icon: Icons.monetization_on_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: "Active Orders",
                          value: activeOrdersCount.toString(),
                          color: ArtisanalColors.secondary,
                          icon: Icons.delivery_dining_rounded,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // Menu item insert builder
                  Text(
                    "ADD NEW SKEWER / GRILL DISH",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: ArtisanalColors.outline),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: ArtisanalColors.primaryContainer.withOpacity(0.03),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _prodTitleController,
                            decoration: const InputDecoration(labelText: "English Title (e.g., Tikka Kebab)"),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _prodTitleArController,
                            decoration: const InputDecoration(labelText: "Arabic Title (العنوان بالعربية)"),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _prodPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: "Base Price (JOD)"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(labelText: "Category"),
                                  items: const [
                                    DropdownMenuItem(value: "grill", child: Text("Grill (مشاوي)")),
                                    DropdownMenuItem(value: "sides", child: Text("Sides (مقبلات)")),
                                    DropdownMenuItem(value: "drinks", child: Text("Drinks (مشروبات)")),
                                    DropdownMenuItem(value: "salads", child: Text("Salads (سلطات)")),
                                    DropdownMenuItem(value: "desserts", child: Text("Desserts (حلويات)")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedCategory = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _prodDescController,
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: "English Description"),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _prodDescArController,
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: "Arabic Description (تفاصيل بالعربية)"),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Popular Badge Accent", style: TextStyle(fontSize: 12)),
                            value: _isPopular,
                            onChanged: (v) => setState(() => _isPopular = v ?? false),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Organic Herbal", style: TextStyle(fontSize: 12)),
                            value: _isHerbal,
                            onChanged: (v) => setState(() => _isHerbal = v ?? false),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addNewProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ArtisanalColors.primary,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text("Add to Menu Catalog"),
                          )
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 40),

                  // Existing menu deletion list
                  Text(
                    "EXISTING CATALOG",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: ArtisanalColors.outline),
                  ),
                  const SizedBox(height: 12),
                  productsAsync.maybeWhen(
                    data: (catalog) => Column(
                      children: catalog.map((p) {
                        return ListTile(
                          leading: Image.network(p.image, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.image)),
                          title: Text(p.title),
                          subtitle: Text("${p.price.toStringAsFixed(2)} JOD"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteProductItem(p.id),
                          ),
                        );
                      }).toList(),
                    ),
                    orElse: () => const LinearProgressIndicator(),
                  )
                ],
              ),
            ),
          ),

          // Vertical separator lines
          const VerticalDivider(width: 1),

          // Right Split Layout panels - Live Active Order Tickets
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "LIVE ORDER CONSOLE",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: ArtisanalColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: ArtisanalColors.primary),
                        onPressed: () => ref.read(ordersNotifierProvider.notifier).refreshOrders(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  orders.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 64, color: ArtisanalColors.outline),
                                SizedBox(height: 16),
                                Text(
                                  "No live tickets in stream. Submit sandbox orders from the application frontend.",
                                  style: TextStyle(color: ArtisanalColors.outline),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: _getBorderColorByStatus(order.status), width: 2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Ticket #${order.orderNumber}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                          // Status Chip helper
                                          Chip(
                                            backgroundColor: _getStatusColor(order.status).withOpacity(0.12),
                                            side: BorderSide.none,
                                            label: Text(
                                              order.status.name.toUpperCase(),
                                              style: TextStyle(
                                                color: _getStatusColor(order.status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      const SizedBox(height: 8),

                                      // Customer Info
                                      Text(
                                        "Customer: ${order.customerName} (${order.customerPhone})",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      if (order.address != null)
                                        Text(
                                          "Address: ${order.address!.street}, ${order.address!.buildingName}, ${order.address!.floor}, ${order.address!.apartment}",
                                          style: const TextStyle(fontSize: 12, color: ArtisanalColors.onSurfaceVariant),
                                        ),
                                      const SizedBox(height: 12),

                                      // Items list
                                      const Text("Items Placed:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ...order.items.map((item) {
                                        return Text(
                                          "• ${item.quantity}x ${item.title} (Spiciness: ${item.selectedSpiciness}, Side: ${item.selectedSide.toUpperCase()})",
                                          style: const TextStyle(fontSize: 13),
                                        );
                                      }).toList(),

                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Fulfillment: ${order.fulfillmentType.name.toUpperCase()}"),
                                          Text(
                                            "Total Collect: ${order.total.toStringAsFixed(2)} JOD",
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: ArtisanalColors.secondary),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),

                                      // Admin reactive Status controllers
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (order.status == OrderStatus.pending) ...[
                                            ElevatedButton(
                                              onPressed: () {
                                                ref.read(ordersNotifierProvider.notifier).updateStatus(order.id, OrderStatus.accepted);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                              child: const Text("Accept Order"),
                                            ),
                                          ] else if (order.status == OrderStatus.accepted) ...[
                                            ElevatedButton(
                                              onPressed: () {
                                                ref.read(ordersNotifierProvider.notifier).updateStatus(order.id, OrderStatus.preparing);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                              child: const Text("Start Skewer Grill"),
                                            ),
                                          ] else if (order.status == OrderStatus.preparing) ...[
                                            ElevatedButton(
                                              onPressed: () {
                                                ref.read(ordersNotifierProvider.notifier).updateStatus(order.id, OrderStatus.ready);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                              child: const Text("Mark as Ready"),
                                            ),
                                          ] else if (order.status == OrderStatus.ready) ...[
                                            ElevatedButton(
                                              onPressed: () {
                                                ref.read(ordersNotifierProvider.notifier).updateStatus(order.id, OrderStatus.out_for_delivery);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                              child: const Text("Handover to Rider"),
                                            ),
                                          ] else if (order.status == OrderStatus.out_for_delivery) ...[
                                            ElevatedButton(
                                              onPressed: () {
                                                ref.read(ordersNotifierProvider.notifier).updateStatus(order.id, OrderStatus.delivered);
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                              child: const Text("Mark as Delivered"),
                                            ),
                                          ],
                                          const SizedBox(width: 8),
                                          if (order.status != OrderStatus.delivered && order.status != OrderStatus.canceled)
                                            OutlinedButton(
                                              onPressed: () {
                                                ref.read(ordersNotifierProvider.notifier).updateStatus(order.id, OrderStatus.canceled);
                                              },
                                              style: OutlinedButton.styleFrom(foregroundColor: ArtisanalColors.error),
                                              child: const Text("Cancel Ticket"),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: ArtisanalColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "JetBrains Mono"),
                  ),
                ],
              ),
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

  Color _getBorderColorByStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted: return Colors.teal.withOpacity(0.4);
      case OrderStatus.preparing: return Colors.orange.withOpacity(0.4);
      case OrderStatus.ready: return Colors.amber.withOpacity(0.4);
      case OrderStatus.out_for_delivery: return Colors.blue.withOpacity(0.4);
      case OrderStatus.delivered: return Colors.green.withOpacity(0.4);
      case OrderStatus.canceled: return ArtisanalColors.error.withOpacity(0.4);
      default: return ArtisanalColors.outlineVariant;
    }
  }
}
