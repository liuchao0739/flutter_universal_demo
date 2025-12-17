import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/cart.dart';
import '../../../repositories/cart_repository.dart';
import '../widgets/cart_item_card.dart';
import 'order_page.dart';

/// 购物车状态
class CartState {
  final List<CartItem> items;
  final bool isLoading;

  CartState({
    this.items = const [],
    this.isLoading = false,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get totalPrice {
    return items
        .where((item) => item.isSelected)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  bool get hasSelectedItems {
    return items.any((item) => item.isSelected);
  }
}

/// 购物车状态管理
class CartNotifier extends StateNotifier<CartState> {
  final CartRepository _repository = CartRepository();

  CartNotifier() : super(CartState()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true);
    await _repository.init();
    final items = await _repository.getCartItems();
    state = state.copyWith(items: items, isLoading: false);
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    await _repository.updateQuantity(itemId, quantity);
    await loadCart();
  }

  Future<void> removeItem(String itemId) async {
    await _repository.removeFromCart(itemId);
    await loadCart();
  }

  Future<void> toggleSelection(String itemId) async {
    await _repository.toggleSelection(itemId);
    await loadCart();
  }

  Future<void> toggleSelectAll(bool select) async {
    await _repository.toggleSelectAll(select);
    await loadCart();
  }

  /// 删除所有已选中的商品
  Future<void> removeSelectedItems() async {
    await _repository.removeSelectedItems();
    await loadCart();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

/// 购物车页面
class CartPage extends ConsumerStatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  CartItem? _deletedItem;

  @override
  void initState() {
    super.initState();
    // 每次进入购物车页时，主动从本地存储刷新一次，避免数据不同步
    Future.microtask(() {
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('购物车'),
        actions: [
          if (state.items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final selectAll = !state.items.every((item) => item.isSelected);
                await notifier.toggleSelectAll(selectAll);
              },
              child: Text(
                state.items.every((item) => item.isSelected) ? '取消全选' : '全选',
              ),
            ),
          if (state.hasSelectedItems)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('删除确认'),
                    content: const Text('确定要删除选中的商品吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await notifier.removeSelectedItems();
                }
              },
              child: const Text('删除选中'),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? const Center(child: Text('购物车是空的'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return CartItemCard(
                            item: item,
                            onQuantityChanged: (quantity) {
                              notifier.updateQuantity(item.id, quantity);
                            },
                            onRemove: () async {
                              // 保存被删除的商品，用于撤销
                              _deletedItem = item;
                              // 删除商品
                              await notifier.removeItem(item.id);
                              // 显示撤销提示
                              if (mounted && _deletedItem != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('商品已删除'),
                                    duration: const Duration(seconds: 3),
                                    action: SnackBarAction(
                                      label: '撤销',
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        // 恢复商品
                                        if (_deletedItem != null) {
                                          final cartRepo = CartRepository();
                                          await cartRepo.init();
                                          await cartRepo.addToCart(_deletedItem!);
                                          await notifier.loadCart();
                                          _deletedItem = null;
                                        }
                                      },
                                    ),
                                  ),
                                );
                                // SnackBar 消失后清除保存的商品
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (mounted) {
                                    _deletedItem = null;
                                  }
                                });
                              }
                            },
                            onToggleSelection: () {
                              notifier.toggleSelection(item.id);
                            },
                          );
                        },
                      ),
                    ),
                    // 底部结算栏
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value:
                                state.items.every((item) => item.isSelected) &&
                                    state.items.isNotEmpty,
                            onChanged: (value) async {
                              await notifier.toggleSelectAll(value ?? false);
                            },
                          ),
                          const Text('全选'),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '合计: ¥${state.totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              Text(
                                '已选 ${state.items.where((i) => i.isSelected).length} 件',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: state.hasSelectedItems
                                ? () async {
                                    final selectedItems = state.items
                                        .where((item) => item.isSelected)
                                        .toList();
                                    if (selectedItems.isEmpty) return;

                                    final cartRepo = CartRepository();
                                    await cartRepo.init();
                                    final order = await cartRepo.createOrder(
                                      items: selectedItems,
                                    );

                                    // 删除已结算的商品
                                    for (final item in selectedItems) {
                                      await cartRepo.removeFromCart(item.id);
                                    }
                                    await notifier.loadCart();

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderPage(orderId: order.id),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('结算'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
