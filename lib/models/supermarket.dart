import 'package:equatable/equatable.dart';

import '../core/constants/database_constants.dart';

/// A supermarket / premise from the PriceCatcher `lookup_premise` dataset.
///
/// Maps 1:1 to a row in the local SQLite `supermarkets` table, keyed by
/// [premiseCode].
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

  factory Supermarket.fromMap(Map<String, Object?> row) {
    return Supermarket(
      premiseCode: row[SupermarketColumns.premiseCode] as String? ?? '',
      name: row[SupermarketColumns.name] as String? ?? '',
      address: row[SupermarketColumns.address] as String? ?? '',
      premiseType: row[SupermarketColumns.premiseType] as String? ?? '',
      district: row[SupermarketColumns.district] as String? ?? '',
      state: row[SupermarketColumns.state] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      SupermarketColumns.premiseCode: premiseCode,
      SupermarketColumns.name: name,
      SupermarketColumns.address: address,
      SupermarketColumns.premiseType: premiseType,
      SupermarketColumns.district: district,
      SupermarketColumns.state: state,
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
