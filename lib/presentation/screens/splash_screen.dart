import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/user_model.dart';
import 'package:flutter_app/data/providers/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
    _checkAuthState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check authentication state
    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) async {
        if (user == null) {
          // Not logged in - go to login
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          // Logged in - check user data and navigate accordingly
          final userDataAsync = ref.read(currentUserDataProvider);

          userDataAsync.when(
            data: (userData) {
              if (userData == null) {
                Navigator.pushReplacementNamed(context, '/login');
              } else if (userData.role == UserRole.admin) {
                Navigator.pushReplacementNamed(context, '/admin/dashboard');
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            loading: () {
              // Wait a bit more for user data
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              });
            },
            error: (_, __) {
              Navigator.pushReplacementNamed(context, '/login');
            },
          );
        }
      },
      loading: () {
        // Still loading, wait a bit
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      },
      error: (_, __) {
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
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
              // App Icon/Logo
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
              // App Name
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
              // Loading indicator
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
