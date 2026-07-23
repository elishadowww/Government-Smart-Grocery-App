import 'package:equatable/equatable.dart';

import '../core/constants/database_constants.dart';

/// A grocery product from the PriceCatcher `lookup_item` dataset.
///
/// Maps 1:1 to a row in the local SQLite `products` table, keyed by
/// [itemCode].
class Product extends Equatable {
  const Product({
    required this.itemCode,
    required this.name,
    required this.unit,
    required this.itemGroup,
    required this.itemCategory,
  });

  final String itemCode;
  final String name;
  final String unit;
  final String itemGroup;
  final String itemCategory;

  factory Product.fromMap(Map<String, Object?> row) {
    return Product(
      itemCode: row[ProductColumns.itemCode] as String? ?? '',
      name: row[ProductColumns.name] as String? ?? '',
      unit: row[ProductColumns.unit] as String? ?? '',
      itemGroup: row[ProductColumns.itemGroup] as String? ?? '',
      itemCategory: row[ProductColumns.itemCategory] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      ProductColumns.itemCode: itemCode,
      ProductColumns.name: name,
      ProductColumns.nameLower: name.toLowerCase(),
      ProductColumns.unit: unit,
      ProductColumns.itemGroup: itemGroup,
      ProductColumns.itemCategory: itemCategory,
    };
  }

  Product copyWith({
    String? name,
    String? unit,
    String? itemGroup,
    String? itemCategory,
  }) {
    return Product(
      itemCode: itemCode,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      itemGroup: itemGroup ?? this.itemGroup,
      itemCategory: itemCategory ?? this.itemCategory,
    );
  }

  @override
  List<Object?> get props => [itemCode, name, unit, itemGroup, itemCategory];
}
