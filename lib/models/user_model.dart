/// A single customer record.
class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.createdAt,
  });

  /// Parses a Supabase row into a [UserModel].
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      name: (map['name'] as String?) ?? '',
      phoneNumber: (map['phone_number'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  /// Fields sent to Supabase on insert. `id` and `created_at` are
  /// generated server-side.
  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'phone_number': phoneNumber,
      };

  /// Two-character initials for the avatar chip.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  UserModel copyWith({String? id, String? name, String? phoneNumber}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
    );
  }
}
