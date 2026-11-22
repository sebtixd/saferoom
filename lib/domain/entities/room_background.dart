import 'package:equatable/equatable.dart';

/// A purchasable room background theme.
class RoomBackground extends Equatable {
  final String id;
  final String name;
  final String description;
  final String assetPath;
  final int price;
  final bool owned;
  final bool equipped;

  const RoomBackground({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.price,
    required this.owned,
    required this.equipped,
  });

  RoomBackground copyWith({
    String? id,
    String? name,
    String? description,
    String? assetPath,
    int? price,
    bool? owned,
    bool? equipped,
  }) {
    return RoomBackground(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      assetPath: assetPath ?? this.assetPath,
      price: price ?? this.price,
      owned: owned ?? this.owned,
      equipped: equipped ?? this.equipped,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        assetPath,
        price,
        owned,
        equipped,
      ];
}
