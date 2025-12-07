// lib/data/providers/auth_state_provider.dart
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_app/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/data/repositories/auth_repository.dart';

// This provider will be used to access the auth state
final authStateProvider = StreamProvider<auth.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// This provider gives access to the AuthRepository methods
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// This provider gives access to the current user data
final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(authRepositoryProvider).streamUserData(user.uid);
});
