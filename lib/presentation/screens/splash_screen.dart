import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_app/data/models/user_model.dart';
import 'package:flutter_app/data/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _checkAuthState();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) async {
        if (user == null) {
          _navigateTo('/login');
        } else {
          await _checkUserRole(user.uid);
        }
      },
      loading: () {
        final subscription = ref.listenManual<AsyncValue<auth.User?>>(
          authStateProvider,
          (_, next) {
            next.when(
              data: (user) {
                if (user == null) {
                  _navigateTo('/login');
                } else {
                  _checkUserRole(user.uid);
                }
              },
              loading: () {}, // Do nothing on loading
              error: (error, _) {
                _navigateTo('/login');
              },
            );
          },
        );

        // Set a timeout to prevent getting stuck
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            subscription.close();
            _navigateTo('/login');
          }
        });
      },
      error: (error, _) {
        _navigateTo('/login');
      },
    );
  }

  Future<void> _checkUserRole(String userId) async {
    try {
      final userData = await ref.read(currentUserDataProvider.future);
      if (!mounted) return;

      if (userData == null) {
        _navigateTo('/login');
      } else if (userData.role == UserRole.admin) {
        _navigateTo('/admin/dashboard');
      } else {
        _navigateTo('/home');
      }
    } catch (e) {
      _navigateTo('/login');
    }
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    // Add a small delay to ensure smooth transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A7CF6),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_parking,
                  size: 60,
                  color: Color(0xFF2A7CF6),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Smart Parking',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Park Smart, Park Easy',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
