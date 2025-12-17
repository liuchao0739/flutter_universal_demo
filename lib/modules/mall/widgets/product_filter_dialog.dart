import 'package:flutter/material.dart';
import '../state/product_state.dart';

/// 商品筛选对话框
class ProductFilterDialog extends StatefulWidget {
  final ProductListState currentState;
  final Function({
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) onFilter;

  const ProductFilterDialog({
    Key? key,
    required this.currentState,
    required this.onFilter,
  }) : super(key: key);

  @override
  State<ProductFilterDialog> createState() => _ProductFilterDialogState();
}

class _ProductFilterDialogState extends State<ProductFilterDialog> {
  late double? minPrice;
  late double? maxPrice;
  late String? sortBy;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    minPrice = widget.currentState.minPrice;
    maxPrice = widget.currentState.maxPrice;
    sortBy = widget.currentState.sortBy;

    _minPriceController = TextEditingController(
      text: minPrice != null ? minPrice!.toStringAsFixed(0) : '',
    );
    _maxPriceController = TextEditingController(
      text: maxPrice != null ? maxPrice!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部拖拽条 + 标题
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  '筛选',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // 价格筛选
                const Text(
                  '价格范围',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceController,
                        decoration: InputDecoration(
                          labelText: '最低价',
                          hintText: minPrice?.toString() ?? '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          minPrice =
                              value.isEmpty ? null : double.tryParse(value);
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceController,
                        decoration: InputDecoration(
                          labelText: '最高价',
                          hintText: maxPrice?.toString() ?? '不限',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          maxPrice =
                              value.isEmpty ? null : double.tryParse(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 排序
                const Text(
                  '排序方式',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // 使用类似京东样式的标签按钮
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSortChip(label: '默认', value: null, primary: primary),
                    _buildSortChip(
                      label: '价格从低到高',
                      value: 'price_asc',
                      primary: primary,
                    ),
                    _buildSortChip(
                      label: '价格从高到低',
                      value: 'price_desc',
                      primary: primary,
                    ),
                    _buildSortChip(
                      label: '销量最高',
                      value: 'sales_desc',
                      primary: primary,
                    ),
                    _buildSortChip(
                      label: '评分最高',
                      value: 'rating_desc',
                      primary: primary,
                    ),
                  ],
                ),
                const Spacer(),
                // 底部按钮
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // 仅重置当前弹窗内的筛选条件，不直接刷新列表
                        setState(() {
                          minPrice = null;
                          maxPrice = null;
                          sortBy = null;
                          _minPriceController.clear();
                          _maxPriceController.clear();
                        });
                      },
                      child: const Text('重置'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onFilter(
                          minPrice: minPrice,
                          maxPrice: maxPrice,
                          sortBy: sortBy,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required String? value,
    required Color primary,
  }) {
    final bool selected = sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          sortBy = value;
        });
      },
      labelStyle: TextStyle(
        color: selected ? primary : Colors.black87,
        fontSize: 13,
      ),
      backgroundColor: Colors.grey[100],
      selectedColor: primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? primary : Colors.grey[300]!,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
