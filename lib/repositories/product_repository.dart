import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/product.dart';

/// 商品数据仓库
/// TODO(prod): 替换为真实 API 调用
class ProductRepository {
  static List<Product>? _cachedProducts;

  /// 加载 Mock 数据
  Future<List<Product>> loadProducts() async {
    if (_cachedProducts != null) {
      return _cachedProducts!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/mock/products.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedProducts = jsonList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedProducts!;
    } catch (e) {
      // 如果文件不存在，返回空列表
      return [];
    }
  }

  /// 搜索商品
  Future<List<Product>> searchProducts(String keyword) async {
    final products = await loadProducts();
    if (keyword.isEmpty) {
      return products;
    }
    return products
        .where((p) =>
            p.name.toLowerCase().contains(keyword.toLowerCase()) ||
            p.description.toLowerCase().contains(keyword.toLowerCase()) ||
            p.tags.any((tag) => tag.toLowerCase().contains(keyword.toLowerCase())))
        .toList();
  }

  /// 筛选商品
  Future<List<Product>> filterProducts({
    double? minPrice,
    double? maxPrice,
    String? sortBy, // price_asc, price_desc, sales_desc, rating_desc
    List<String>? tags,
  }) async {
    var products = await loadProducts();

    // 标签筛选
    if (tags != null && tags.isNotEmpty) {
      products = products
          .where((p) => p.tags.any((tag) => tags.contains(tag)))
          .toList();
    }

    // 价格筛选
    if (minPrice != null) {
      products = products.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      products = products.where((p) => p.price <= maxPrice).toList();
    }

    // 排序
    if (sortBy != null) {
      switch (sortBy) {
        case 'price_asc':
          products.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          products.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'sales_desc':
          products.sort((a, b) => b.salesCount.compareTo(a.salesCount));
          break;
        case 'rating_desc':
          products.sort((a, b) => b.rating.compareTo(a.rating));
          break;
      }
    }

    return products;
  }

  /// 根据 ID 获取商品
  Future<Product?> getProductById(String id) async {
    final products = await loadProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 分页加载
  Future<List<Product>> loadProductsPaginated({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    // 先拿到全部商品，然后依次叠加“搜索 + 筛选 + 排序”
    var products = await loadProducts();

    // 关键词搜索（名称 / 描述 / 标签）
    if (keyword != null && keyword.isNotEmpty) {
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(keyword.toLowerCase()) ||
              p.description.toLowerCase().contains(keyword.toLowerCase()) ||
              p.tags.any(
                (tag) => tag.toLowerCase().contains(keyword.toLowerCase()),
              ))
          .toList();
    }

    // 价格筛选
    if (minPrice != null) {
      products = products.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      products = products.where((p) => p.price <= maxPrice).toList();
    }

    // 排序
    if (sortBy != null) {
      switch (sortBy) {
        case 'price_asc':
          products.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          products.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'sales_desc':
          products.sort((a, b) => b.salesCount.compareTo(a.salesCount));
          break;
        case 'rating_desc':
          products.sort((a, b) => b.rating.compareTo(a.rating));
          break;
      }
    }

    final start = (page - 1) * pageSize;
    final end = start + pageSize;
    if (start >= products.length) {
      return [];
    }
    return products.sublist(
        start, end > products.length ? products.length : end);
  }
}

