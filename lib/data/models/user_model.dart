import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin }

enum AuthProvider { google, email }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? photoURL;
  final AuthProvider provider;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.photoURL,
    required this.provider,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Builds a [UserModel] from any Firestore snapshot.
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return UserModel.fromMap(doc.data() ?? {}, docId: doc.id);
  }

  /// Builds a [UserModel] from a raw map (useful for caching/testing).
  factory UserModel.fromMap(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    return UserModel(
      uid: docId ?? data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
      role: _roleFromString(data['role']),
      photoURL: data['photoURL'] as String?,
      provider: _providerFromString(data['provider']),
      createdAt: _timestampToDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _timestampToDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.name,
      'photoURL': photoURL,
      'provider': provider.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.name,
      'photoURL': photoURL,
      'provider': provider.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? photoURL,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoURL: photoURL ?? this.photoURL,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

UserRole _roleFromString(dynamic value) {
  if (value is UserRole) return value;
  final stringValue = value?.toString();
  return UserRole.values.firstWhere(
    (role) => role.name == stringValue,
    orElse: () => UserRole.user,
  );
}

AuthProvider _providerFromString(dynamic value) {
  if (value is AuthProvider) return value;
  final stringValue = value?.toString();
  return AuthProvider.values.firstWhere(
    (provider) => provider.name == stringValue,
    orElse: () => AuthProvider.email,
  );
}

DateTime? _timestampToDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
