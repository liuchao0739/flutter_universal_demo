import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart.dart';
import 'dart:convert';

/// 购物车数据仓库
/// 使用 Hive 本地存储
class CartRepository {
  static const String _boxName = 'cart';
  static const String _orderBoxName = 'orders';

  /// 初始化
  Future<void> init() async {
    await Hive.openBox(_boxName);
    await Hive.openBox(_orderBoxName);
  }

  /// 获取购物车所有商品
  Future<List<CartItem>> getCartItems() async {
    final box = await Hive.openBox(_boxName);
    final itemsJson = box.get('items', defaultValue: '[]') as String;
    final List<dynamic> jsonList = json.decode(itemsJson);
    return jsonList
        .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 添加商品到购物车
  Future<void> addToCart(CartItem item) async {
    final items = await getCartItems();
    // 检查是否已存在相同 SKU
    final existingIndex = items.indexWhere(
      (i) => i.productId == item.productId && i.skuId == item.skuId,
    );

    if (existingIndex != -1) {
      // 更新数量
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + item.quantity,
      );
    } else {
      items.add(item);
    }

    await _saveCartItems(items);
  }

  /// 更新购物车项数量
  Future<void> updateQuantity(String itemId, int quantity) async {
    final items = await getCartItems();
    final index = items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: quantity);
      }
      await _saveCartItems(items);
    }
  }

  /// 删除购物车项
  Future<void> removeFromCart(String itemId) async {
    final items = await getCartItems();
    items.removeWhere((i) => i.id == itemId);
    await _saveCartItems(items);
  }

  /// 切换选中状态
  Future<void> toggleSelection(String itemId) async {
    final items = await getCartItems();
    final index = items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      items[index] = items[index].copyWith(
        isSelected: !items[index].isSelected,
      );
      await _saveCartItems(items);
    }
  }

  /// 全选/取消全选
  Future<void> toggleSelectAll(bool select) async {
    final items = await getCartItems();
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(isSelected: select);
    }
    await _saveCartItems(items);
  }

  /// 获取选中商品总价
  Future<double> getSelectedTotal() async {
    final items = await getCartItems();
    double total = 0.0;
    for (final item in items.where((i) => i.isSelected)) {
      total += item.totalPrice;
    }
    return total;
  }

  /// 清空购物车
  Future<void> clearCart() async {
    await _saveCartItems([]);
  }

  /// 删除所有已选中的商品
  Future<void> removeSelectedItems() async {
    final items = await getCartItems();
    items.removeWhere((i) => i.isSelected);
    await _saveCartItems(items);
  }

  Future<void> _saveCartItems(List<CartItem> items) async {
    final box = await Hive.openBox(_boxName);
    final itemsJson = json.encode(items.map((i) => i.toJson()).toList());
    await box.put('items', itemsJson);
  }

  /// 创建订单
  Future<Order> createOrder({
    required List<CartItem> items,
    String? shippingAddress,
    String? receiverName,
    String? receiverPhone,
    double? discountAmount,
  }) async {
    final selectedItems = items.where((i) => i.isSelected).toList();
    final totalAmount =
        selectedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final finalAmount = totalAmount - (discountAmount ?? 0);

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: 'pending_payment',
      items: selectedItems,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      shippingAddress: shippingAddress,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      createTime: DateTime.now(),
      tenantId:
          selectedItems.isNotEmpty ? selectedItems.first.tenantId : 'default',
    );

    await _saveOrder(order);
    return order;
  }

  /// 获取所有订单
  Future<List<Order>> getOrders() async {
    final box = await Hive.openBox(_orderBoxName);
    final ordersJson = box.get('orders', defaultValue: '[]') as String;
    final List<dynamic> jsonList = json.decode(ordersJson);
    return jsonList
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createTime.compareTo(a.createTime));
  }

  /// 根据 ID 获取订单
  Future<Order?> getOrderById(String id) async {
    final orders = await getOrders();
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 更新订单状态
  Future<void> updateOrderStatus(String orderId, String status) async {
    final orders = await getOrders();
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = orders[index];
      DateTime? payTime = order.payTime;
      DateTime? shipTime = order.shipTime;
      DateTime? completeTime = order.completeTime;

      if (status == 'paid' && payTime == null) {
        payTime = DateTime.now();
      } else if (status == 'shipped' && shipTime == null) {
        shipTime = DateTime.now();
      } else if (status == 'completed' && completeTime == null) {
        completeTime = DateTime.now();
      }

      orders[index] = order.copyWith(
        status: status,
        payTime: payTime,
        shipTime: shipTime,
        completeTime: completeTime,
      );
      await _saveOrders(orders);
    }
  }

  Future<void> _saveOrder(Order order) async {
    final orders = await getOrders();
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      orders[index] = order;
    } else {
      orders.add(order);
    }
    await _saveOrders(orders);
  }

  Future<void> _saveOrders(List<Order> orders) async {
    final box = await Hive.openBox(_orderBoxName);
    final ordersJson = json.encode(orders.map((o) => o.toJson()).toList());
    await box.put('orders', ordersJson);
  }
}
