import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/locale_service.dart';
import '../../order/repositories/cart_repository.dart';
import '../repositories/menu_repository.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _selectedSpiciness;
  ProductSideOption? _selectedSide;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final localeSvc = ref.watch(localeProvider.notifier);
    final productsSvc = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      body: productsSvc.maybeWhen(
        data: (list) {
          final prodIdx = list.indexWhere((p) => p.id == widget.productId);
          if (prodIdx == -1) {
            return const Scaffold(body: Center(child: Text("Product not found.")));
          }
          final ProductModel product = list[prodIdx];

          // Set default selected spiciness on load if null
          if (_selectedSpiciness == null && product.spicyOptions.isNotEmpty) {
            _selectedSpiciness = product.spicyOptions.first;
          }

          final sidePrice = _selectedSide?.price ?? 0.0;
          final double singlePrice = product.price + sidePrice;
          final double itemTotal = singlePrice * _quantity;

          return CustomScrollView(
            slivers: [
              // Beautiful Sliver App Bar with Product Hero Image
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: ArtisanalColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(color: ArtisanalColors.outlineVariant),
                      ),
                      // Ambient overlay to ensure legibility of headers
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scrollable Details Body Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Popular Tag option
                      Row(
                        children: [
                          if (product.isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ArtisanalColors.secondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "🔥 HOT CHOICE",
                                style: TextStyle(
                                  color: ArtisanalColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                product.rating.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        localeSvc.translate(product.title, product.titleAr),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ArtisanalColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Base Price badge
                      Text(
                        "${product.price.toStringAsFixed(2)} JOD",
                        style: const TextStyle(
                          fontSize: 22,
                          color: ArtisanalColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        localeSvc.translate(product.description, product.descriptionAr),
                        style: const TextStyle(
                          height: 1.5,
                          color: ArtisanalColors.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 40),

                      // Spicy Options Choice Chips
                      if (product.spicyOptions.isNotEmpty) ...[
                        Text(
                          localeSvc.translate("Adjust Spiciness Level", "درجة حرارة التتبيلة"),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: product.spicyOptions.map((opt) {
                            final isSel = _selectedSpiciness == opt;
                            return ChoiceChip(
                              label: Text(localeSvc.translate(opt, _translateSpicinessAr(opt))),
                              selected: isSel,
                              selectedColor: ArtisanalColors.primary,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : ArtisanalColors.onSurface,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedSpiciness = opt);
                              },
                            );
                          }).toList(),
                        ),
                        const Divider(height: 40),
                      ],

                      // Side Options List
                      if (product.sideOptions.isNotEmpty) ...[
                        Text(
                          localeSvc.translate("Select a Free or Premium Side", "اختر طبقاً جانبياً مميزاً"),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localeSvc.translate("One serving included with your order", "وجبة واحدة مشمولة مجاناً مع الطبق الرئيسي"),
                          style: const TextStyle(fontSize: 12, color: ArtisanalColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: product.sideOptions.map((side) {
                            final isSel = _selectedSide?.id == side.id;
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderSide: BorderSide(
                                  color: isSel ? ArtisanalColors.secondary : ArtisanalColors.outlineVariant,
                                  width: isSel ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    side.image,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => Container(color: Colors.grey),
                                  ),
                                ),
                                title: Text(localeSvc.translate(side.name, side.nameAr)),
                                trailing: Text(
                                  side.price == 0.0 ? localeSvc.translate("Free", "مشمول مجاناً") : "+${side.price.toStringAsFixed(2)} JOD",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: side.price == 0.0 ? Colors.green : ArtisanalColors.secondary,
                                  ),
                                ),
                                selected: isSel,
                                onTap: () {
                                  setState(() {
                                    _selectedSide = isSel ? null : side;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 40),
                      ],

                      // Quantity Incrementor Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localeSvc.translate("Quantity", "الكمية المطلوبة"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: ArtisanalColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    _quantity.toString(),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: () => setState(() => _quantity++),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Sticky Add To Basket Button
                      ElevatedButton(
                        onPressed: () {
                          // Action add item to Cart state notifier
                          ref.read(cartProvider.notifier).addItem(
                            product: product,
                            quantity: _quantity,
                            spiciness: _selectedSpiciness ?? "Medium",
                            selectedSide: _selectedSide,
                          );

                          // Interactive Success feedback snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localeSvc.translate("Added to your charcoal tray!", "تمت إضافة الوجبة بنجاح لحافظة الطعام الخاصة بك!")
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          // Go back
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined),
                            const SizedBox(width: 12),
                            Text(
                              localeSvc.translate(
                                "Add to Basket • ${itemTotal.toStringAsFixed(2)} JOD",
                                "إضافة للسلة • ${itemTotal.toStringAsFixed(2)} دينار",
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              )
            ],
          );
        },
        orElse: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
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
