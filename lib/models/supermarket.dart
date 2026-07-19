import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/constants/firestore_constants.dart';

/// A supermarket / premise from the PriceCatcher `lookup_premise` dataset.
///
/// Maps 1:1 to a document in the `supermarkets` Firestore collection, keyed
/// by [premiseCode].
class Supermarket extends Equatable {
  const Supermarket({
    required this.premiseCode,
    required this.name,
    required this.address,
    required this.premiseType,
    required this.district,
    required this.state,
  });

  final String premiseCode;
  final String name;
  final String address;
  final String premiseType;
  final String district;
  final String state;

  factory Supermarket.fromMap(String premiseCode, Map<String, dynamic> map) {
    return Supermarket(
      premiseCode: premiseCode,
      name: map[SupermarketFields.name] as String? ?? '',
      address: map[SupermarketFields.address] as String? ?? '',
      premiseType: map[SupermarketFields.premiseType] as String? ?? '',
      district: map[SupermarketFields.district] as String? ?? '',
      state: map[SupermarketFields.state] as String? ?? '',
    );
  }

  factory Supermarket.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Supermarket.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      SupermarketFields.premiseCode: premiseCode,
      SupermarketFields.name: name,
      SupermarketFields.address: address,
      SupermarketFields.premiseType: premiseType,
      SupermarketFields.district: district,
      SupermarketFields.state: state,
    };
  }

  Supermarket copyWith({
    String? name,
    String? address,
    String? premiseType,
    String? district,
    String? state,
  }) {
    return Supermarket(
      premiseCode: premiseCode,
      name: name ?? this.name,
      address: address ?? this.address,
      premiseType: premiseType ?? this.premiseType,
      district: district ?? this.district,
      state: state ?? this.state,
    );
  }

  @override
  List<Object?> get props => [
        premiseCode,
        name,
        address,
        premiseType,
        district,
        state,
      ];
}
