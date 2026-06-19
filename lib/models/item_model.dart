/// A single line item belonging to a [UserModel].
class ItemModel {
  final String id;
  final String userId;
  final String itemName;
  final String? quality;
  final double quantity;
  final double price;
  final double discount;
  final double remaining;
  final double balance;
  final DateTime? createdAt;

  const ItemModel({
    required this.id,
    required this.userId,
    required this.itemName,
    this.quality,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.remaining,
    required this.balance,
    this.createdAt,
  });

  /// Gross total before discount.
  double get totalPrice => quantity * price;

  /// Safe-parses numeric values from Supabase (they come back as num or String).
  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      itemName: (map['item_name'] as String?) ?? '',
      quality: map['quality'] as String?,
      quantity: _toDouble(map['quantity']),
      price: _toDouble(map['price']),
      discount: _toDouble(map['discount']),
      remaining: _toDouble(map['remaining']),
      balance: _toDouble(map['balance']),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'user_id': userId,
        'item_name': itemName,
        'quality': quality,
        'quantity': quantity,
        'price': price,
        'discount': discount,
        'remaining': remaining,
        'balance': balance,
      };

  /// Returns a copy with the given fields replaced.
  /// Useful for building an updated row before persisting.
  ItemModel copyWith({
    String? id,
    String? userId,
    String? itemName,
    String? quality,
    double? quantity,
    double? price,
    double? discount,
    double? remaining,
    double? balance,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemName: itemName ?? this.itemName,
      quality: quality ?? this.quality,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      remaining: remaining ?? this.remaining,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
