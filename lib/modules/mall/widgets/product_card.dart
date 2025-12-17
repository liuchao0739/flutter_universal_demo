import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../models/cart.dart';
import '../../../repositories/cart_repository.dart';
import '../pages/product_detail_page.dart';
import '../pages/cart_page.dart';

/// 商品卡片组件
class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  Future<void> _handleAddToCart(BuildContext context, WidgetRef ref) async {
    // 默认使用第一个 SKU，数量为 1
    if (product.skus.isEmpty) return;
    final sku = product.skus.first;

    final cartRepo = CartRepository();
    await cartRepo.init();

    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      productName: product.name,
      productImage: product.imageUrl,
      skuId: sku.id,
      selectedSpecs: sku.specs,
      price: sku.price,
      quantity: 1,
      tenantId: product.tenantId,
    );

    await cartRepo.addToCart(cartItem);

    // 刷新购物车状态，使角标数量立即更新
    ref.read(cartProvider.notifier).loadCart();

    // 播放加入购物车飞行动画
    _showAddToCartAnimation(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已添加到购物车')),
    );
  }

  void _showAddToCartAnimation(BuildContext context) {
    final overlayState = Overlay.of(context);

    final size = MediaQuery.of(context).size;
    final start = Offset(size.width / 2, size.height - 80);
    final end = Offset(size.width - 40, kToolbarHeight + 40);

    final overlayEntry = OverlayEntry(
      builder: (context) {
        return _CartFlyAnimation(
          start: start,
          end: end,
        );
      },
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 700), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品图片
            Expanded(
              child: Stack(
                children: [
                  Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // TODO(prod): 生产环境可接入图片加载监控与重试机制
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  // 仅当存在且确实有折扣时才展示角标
                  if (product.originalPrice != null &&
                      product.originalPrice! > product.price)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${((1 - product.price / product.originalPrice!) * 100).toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 商品信息
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        '¥${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (product.originalPrice != null)
                        Text(
                          '¥${product.originalPrice!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '已售${product.salesCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _handleAddToCart(context, ref),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.add_shopping_cart,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 加入购物车飞行动画（与详情页保持一致的视觉效果，稍作复用）
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
          final controlPoint = Offset(
            (widget.start.dx + widget.end.dx) / 2,
            widget.start.dy - 120,
          );

          final position = Offset(
            _quadraticBezier(
                widget.start.dx, controlPoint.dx, widget.end.dx, t),
            _quadraticBezier(
                widget.start.dy, controlPoint.dy, widget.end.dy, t),
          );

          final size = 24.0 * (1.0 - t * 0.3);

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
