import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';

/// 商品列表状态
class ProductListState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String searchKeyword;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;

  // 用于区分 copyWith 中「不修改」和「显式设为 null」
  static const Object _noChange = Object();

  ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.searchKeyword = '',
    this.minPrice,
    this.maxPrice,
    this.sortBy,
  });

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? searchKeyword,
    Object? minPrice = _noChange,
    Object? maxPrice = _noChange,
    Object? sortBy = _noChange,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      minPrice:
          identical(minPrice, _noChange) ? this.minPrice : minPrice as double?,
      maxPrice:
          identical(maxPrice, _noChange) ? this.maxPrice : maxPrice as double?,
      sortBy: identical(sortBy, _noChange) ? this.sortBy : sortBy as String?,
    );
  }
}

/// 商品列表状态管理
class ProductListNotifier extends StateNotifier<ProductListState> {
  final ProductRepository _repository = ProductRepository();

  ProductListNotifier() : super(ProductListState()) {
    loadProducts();
  }

  /// 加载商品列表
  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: page,
    );

    try {
      final products = await _repository.loadProductsPaginated(
        page: page,
        pageSize: 20,
        keyword: state.searchKeyword.isEmpty ? null : state.searchKeyword,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        products: refresh ? products : [...state.products, ...products],
        isLoading: false,
        hasMore: products.length >= 20,
        currentPage: page + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 搜索商品
  Future<void> search(String keyword) async {
    state = state.copyWith(searchKeyword: keyword);
    await loadProducts(refresh: true);
  }

  /// 筛选商品
  Future<void> filter({
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
    );
    await loadProducts(refresh: true);
  }

  /// 重置搜索与筛选条件，恢复为“全部商品”
  Future<void> resetFiltersAndSearch() async {
    state = state.copyWith(
      searchKeyword: '',
      minPrice: null,
      maxPrice: null,
      sortBy: null,
    );
    await loadProducts(refresh: true);
  }

  /// 刷新
  Future<void> refresh() async {
    await loadProducts(refresh: true);
  }
}

/// Provider
final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier();
});

/// 单个商品 Provider
final productProvider =
    FutureProvider.family<Product?, String>((ref, id) async {
  final repository = ProductRepository();
  return await repository.getProductById(id);
});
