import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/constants/firestore_constants.dart';

/// A grocery product from the PriceCatcher `lookup_item` dataset.
///
/// Maps 1:1 to a document in the `products` Firestore collection, keyed by
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

  factory Product.fromMap(String itemCode, Map<String, dynamic> map) {
    return Product(
      itemCode: itemCode,
      name: map[ProductFields.name] as String? ?? '',
      unit: map[ProductFields.unit] as String? ?? '',
      itemGroup: map[ProductFields.itemGroup] as String? ?? '',
      itemCategory: map[ProductFields.itemCategory] as String? ?? '',
    );
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Product.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      ProductFields.itemCode: itemCode,
      ProductFields.name: name,
      ProductFields.nameLower: name.toLowerCase(),
      ProductFields.unit: unit,
      ProductFields.itemGroup: itemGroup,
      ProductFields.itemCategory: itemCategory,
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
