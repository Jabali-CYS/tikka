import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/locale_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../order/repositories/cart_repository.dart';
import '../repositories/menu_repository.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class HomeMenuBrowserScreen extends ConsumerWidget {
  const HomeMenuBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeSvc = ref.watch(localeProvider.notifier);
    final user = ref.watch(authStateProvider);
    final cart = ref.watch(cartProvider);

    final categoriesAsync = ref.watch(categoriesProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final activeCategory = ref.watch(categoryFilterProvider);

    final searchController = TextEditingController(text: ref.read(searchQueryProvider));

    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Professional Layout Header Panel
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(2), // tight border for logo ring
                      decoration: BoxDecoration(
                        color: ArtisanalColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ArtisanalColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localeSvc.translate("Ahlan & Welcome!", "أهلاً وسهلاً بك!"),
                          style: const TextStyle(fontSize: 12, color: ArtisanalColors.onSurfaceVariant),
                        ),
                        Text(
                          user?.name ?? localeSvc.translate("Loyalist Guest", "ضيف كريم"),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  // Points Badge Indicator
                  if (user != null)
                    TextButton.icon(
                      onPressed: () => context.push('/profile'),
                      style: TextButton.styleFrom(
                        backgroundColor: ArtisanalColors.primaryFixed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      icon: const Icon(Icons.stars, color: ArtisanalColors.primary, size: 18),
                      label: Text(
                        "${user.points} pts",
                        style: const TextStyle(
                          color: ArtisanalColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Language Toggle button
                  IconButton(
                    icon: const Icon(Icons.translate, color: ArtisanalColors.primary, size: 20),
                    onPressed: () => ref.read(localeProvider.notifier).toggleLanguage(),
                  ),
                ],
              ),
            ),

            // Search Bar Component
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: searchController,
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: localeSvc.translate("Search kebabs, tikka...", "ابحث عن شيش طاووق، كباب..."),
                  prefixIcon: const Icon(Icons.search, color: ArtisanalColors.outline),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = "";
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: ArtisanalColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Categories horizontal slider layout
            SizedBox(
              height: 52,
              child: categoriesAsync.maybeWhen(
                data: (cats) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: cats.length,
                  itemBuilder: (context, idx) {
                    final cat = cats[idx];
                    final isSel = cat.id == activeCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSel,
                        backgroundColor: ArtisanalColors.surfaceContainerLow,
                        selectedColor: ArtisanalColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : ArtisanalColors.onSurface,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        iconTheme: IconThemeData(
                          color: isSel ? Colors.white : ArtisanalColors.primary,
                        ),
                        avatar: Icon(
                          cat.icon == "Flame" 
                              ? Icons.local_fire_department 
                              : cat.icon == "Utensils" 
                                  ? Icons.restaurant 
                                  : cat.icon == "CupSoda"
                                      ? Icons.local_drink
                                      : cat.icon == "Leaf"
                                          ? Icons.eco
                                          : Icons.cake,
                          size: 16,
                        ),
                        label: Text(localeSvc.translate(cat.name, cat.nameAr)),
                        onSelected: (val) {
                          ref.read(categoryFilterProvider.notifier).state = cat.id;
                        },
                      ),
                    );
                  },
                ),
                orElse: () => const Center(child: LinearProgressIndicator()),
              ),
            ),

            // Products Grid/List
            Expanded(
              child: productsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TandoorShimmer.rectangular(width: 120, height: 120),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              SizedBox(height: 8),
                              TandoorShimmer.rectangular(width: 140, height: 16),
                              SizedBox(height: 12),
                              TandoorShimmer.rectangular(width: 180, height: 12),
                              SizedBox(height: 8),
                              TandoorShimmer.rectangular(width: 120, height: 12),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TandoorShimmer.rectangular(width: 60, height: 16),
                                  TandoorShimmer.circular(width: 24, height: 24),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (err, stack) => Center(child: Text("Error loading catalog: $err")),
                data: (products) {
                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu, size: 48, color: ArtisanalColors.outline),
                          const SizedBox(height: 12),
                          Text(
                            localeSvc.translate("No items match filters.", "لا توجد وجبات تطابق البحث العلمي."),
                            style: const TextStyle(color: ArtisanalColors.outline),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            context.push('/product/${product.id}');
                          },
                          child: Row(
                            children: [
                              // Left Image container with cache handling
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => Container(
                                    color: ArtisanalColors.outlineVariant,
                                    child: const Icon(Icons.image, color: Colors.white),
                                  ),
                                ),
                              ),
                              // Text details on right
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              localeSvc.translate(product.title, product.titleAr),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          if (product.isHerbal)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(Icons.eco, color: Colors.green, size: 12),
                                            ),
                                          if (product.isPopular) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: ArtisanalColors.secondary.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                "🔥 POPULAR",
                                                style: TextStyle(
                                                  color: ArtisanalColors.secondary,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        localeSvc.translate(product.description, product.descriptionAr),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: ArtisanalColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${product.price.toStringAsFixed(2)} JOD",
                                            style: const TextStyle(
                                              color: ArtisanalColors.secondary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.orange, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                product.rating.toString(),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: ArtisanalColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.add, color: Colors.white, size: 16),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Sticky floating navigation checkout panel for direct access
      floatingActionButton: cart.items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/checkout'),
              backgroundColor: ArtisanalColors.secondary,
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
              label: Text(
                localeSvc.translate(
                  "Order (${cart.items.length}) • ${cart.totalAmount.toStringAsFixed(2)} JOD",
                  "اطلب (${cart.items.length}) • ${cart.totalAmount.toStringAsFixed(2)} دينار",
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
    );
  }
}

class TandoorShimmer extends StatefulWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const TandoorShimmer.rectangular({
    super.key,
    required this.width,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));

  const TandoorShimmer.circular({
    super.key,
    required this.width,
    required this.height,
  }) : shapeBorder = const CircleBorder();

  @override
  State<TandoorShimmer> createState() => _TandoorShimmerState();
}

class _TandoorShimmerState extends State<TandoorShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFEAE5D9),
                Color(0xFFF4EFE6),
                Color(0xFFEAE5D9),
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlideGradientTransform(value: _controller.value),
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: ShapeDecoration(
              color: Colors.grey[400],
              shape: widget.shapeBorder,
            ),
          ),
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double value;
  const _SlideGradientTransform({required this.value});


  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double w = bounds.width;
    return Matrix4.translationValues(-w + (w * 2 * value), 0.0, 0.0);
  }
}
