import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/product_state.dart';
import '../widgets/product_spec_selector.dart';
import '../widgets/product_info_section.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/product_detail_bottom_bar.dart';
import '../../../models/product.dart';
import '../../../models/cart.dart';
import '../../../repositories/cart_repository.dart';
import 'cart_page.dart';

/// 商品详情页
class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({Key? key, required this.productId}) : super(key: key);

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  final PageController _imagePageController = PageController();
  Map<String, String> _selectedSpecs = {};
  ProductSku? _selectedSku;
  int _quantity = 1;
  OverlayEntry? _cartFlyOverlay;

  @override
  void dispose() {
    _cartFlyOverlay?.remove();
    _imagePageController.dispose();
    super.dispose();
  }

  void _onSpecSelected(String specKey, String specValue) {
    setState(() {
      _selectedSpecs[specKey] = specValue;
      _updateSelectedSku();
    });
  }

  void _updateSelectedSku() {
    final productAsync = ref.read(productProvider(widget.productId));
    final product = productAsync.value;
    if (product == null) return;

    _selectedSku = product.skus.firstWhere(
      (sku) {
        if (sku.specs.length != _selectedSpecs.length) return false;
        return sku.specs.entries.every(
          (entry) => _selectedSpecs[entry.key] == entry.value,
        );
      },
      orElse: () => product.skus.first,
    );
  }

  Future<void> _addToCart() async {
    final productAsync = ref.read(productProvider(widget.productId));
    final product = productAsync.value;
    if (product == null) return;

    if (_selectedSku == null) {
      _updateSelectedSku();
    }

    final cartRepo = CartRepository();
    await cartRepo.init();

    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      productName: product.name,
      productImage: product.imageUrl,
      skuId: _selectedSku!.id,
      selectedSpecs: _selectedSpecs,
      price: _selectedSku!.price,
      quantity: _quantity,
      tenantId: product.tenantId,
    );

    await cartRepo.addToCart(cartItem);

    if (!mounted) return;

    // 刷新购物车状态，使角标数量立即更新
    ref.read(cartProvider.notifier).loadCart();

    _showAddToCartAnimation();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已添加到购物车')),
    );
  }

  /// 显示加入购物车的小车飞行动画
  void _showAddToCartAnimation() {
    final overlayState = Overlay.of(context);
    _cartFlyOverlay?.remove();

    final size = MediaQuery.of(context).size;
    final start = Offset(size.width / 2, size.height - 80);
    final end = Offset(size.width - 40, kToolbarHeight + 40);

    _cartFlyOverlay = OverlayEntry(
      builder: (context) {
        return _CartFlyAnimation(
          start: start,
          end: end,
        );
      },
    );

    overlayState.insert(_cartFlyOverlay!);

    Future.delayed(const Duration(milliseconds: 700), () {
      _cartFlyOverlay?.remove();
      _cartFlyOverlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('商品不存在'));
          }

          if (_selectedSku == null) {
            _updateSelectedSku();
          }

          return CustomScrollView(
            slivers: [
              // AppBar with images
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: PageView.builder(
                    controller: _imagePageController,
                    itemCount: product.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        product.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CartPage(),
                            ),
                          );
                        },
                      ),
                      // 购物车角标：显示商品种类数量
                      if (cartState.items.isNotEmpty)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              cartState.items.length > 99 ? '99+' : '${cartState.items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Product info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductInfoSection(
                        product: product,
                        currentPrice: _selectedSku?.price,
                      ),
                      const Divider(height: 32),
                      // 规格选择
                      if (product.specs != null && product.specs!.isNotEmpty) ...[
                        const Text(
                          '选择规格',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...product.specs!.entries.map((entry) {
                          return ProductSpecSelector(
                            specKey: entry.key,
                            specValue: entry.value,
                            selectedValue: _selectedSpecs[entry.key],
                            onSelected: (value) => _onSpecSelected(entry.key, value),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                      // 数量选择
                      QuantitySelector(
                        quantity: _quantity,
                        onChanged: (newQuantity) {
                          setState(() => _quantity = newQuantity);
                        },
                      ),
                      const Divider(height: 32),
                      // 商品描述
                      const Text(
                        '商品详情',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 100), // 为底部按钮留空间
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('加载失败: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(productProvider(widget.productId));
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: ProductDetailBottomBar(
        onAddToCart: _addToCart,
        onBuyNow: () {
          // TODO(prod): 调用支付 SDK
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已调用支付 SDK（Mock）')),
          );
        },
      ),
    );
  }
}

/// 加入购物车飞行动画小部件
class _CartFlyAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;

  const _CartFlyAnimation({
    Key? key,
    required this.start,
    required this.end,
  }) : super(key: key);

  @override
  State<_CartFlyAnimation> createState() => _CartFlyAnimationState();
}

class _CartFlyAnimationState extends State<_CartFlyAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final t = _animation.value;
          // 简单二次贝塞尔曲线：从底部飞向右上角，路径稍微弯曲
          final controlPoint = Offset(
            (widget.start.dx + widget.end.dx) / 2,
            widget.start.dy - 120,
          );

          final position = Offset(
            _quadraticBezier(widget.start.dx, controlPoint.dx, widget.end.dx, t),
            _quadraticBezier(widget.start.dy, controlPoint.dy, widget.end.dy, t),
          );

          final size = 24.0 * (1.0 - t * 0.3); // 飞行过程中稍微缩小一点

          return Stack(
            children: [
              Positioned(
                left: position.dx,
                top: position.dy,
                child: Transform.scale(
                  scale: size / 24.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.shopping_cart,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _quadraticBezier(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }
}

