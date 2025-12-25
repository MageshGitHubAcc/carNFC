import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_app/presentation/screens/admin/write_nfc.dart';
import 'package:flutter_app/presentation/screens/profile/profile_screen.dart';
import 'package:flutter_app/presentation/screens/splash_screen.dart';
import 'package:flutter_app/presentation/screens/user/home_screen.dart';
import 'package:flutter_app/presentation/screens/admin/active_bookings_screen.dart';
import 'package:flutter_app/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:flutter_app/presentation/screens/admin/alert_screen.dart';
import 'package:flutter_app/presentation/screens/admin/booking_history_screen.dart';
import 'package:flutter_app/presentation/screens/admin/create_check_out_screen.dart';
import 'package:flutter_app/presentation/screens/admin/create_mall_screen.dart';
import 'package:flutter_app/presentation/screens/admin/data_management_screen.dart';
import 'package:flutter_app/presentation/screens/admin/manage_slot_screen.dart';
import 'package:flutter_app/presentation/screens/admin/report_screen.dart';
import 'package:flutter_app/presentation/screens/admin/settings_screen.dart';
import 'package:flutter_app/presentation/screens/admin/manual_booking_nfc_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/presentation/screens/auth/login_screen.dart';
import 'package:flutter_app/presentation/screens/auth/sign_up_screen.dart';
import 'package:flutter_app/presentation/screens/user/slot_selection_screen.dart';
import 'package:flutter_app/presentation/screens/user/vehicle_details_screen.dart';
import 'package:flutter_app/presentation/screens/user/booking_confirmation_screen.dart';
import 'package:flutter_app/data/models/mall_model.dart';

// ANDROID FIREBASE CONFIG
const FirebaseOptions androidOptions = FirebaseOptions(
  apiKey: 'AIzaSyD2iJWG87p8q03Rz4kqx2gKJP9wNq2PvvE',
  appId: '1:943129513200:android:886174443bce0c70de0635',
  messagingSenderId: '943129513200',
  projectId: 'car-parking-nfc',
  storageBucket: 'car-parking-nfc.firebasestorage.app',
);

// IOS FIREBASE CONFIG
const FirebaseOptions iosOptions = FirebaseOptions(
  apiKey: 'AIzaSyD2iJWG87p8q03Rz4kqx2gKJP9wNq2PvvE',
  appId: '1:943129513200:ios:81fc7a8bbd42bc02de0635',
  messagingSenderId: '943129513200',
  projectId: 'car-parking-nfc',
  storageBucket: 'car-parking-nfc.firebasestorage.app',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: defaultTargetPlatform == TargetPlatform.android
        ? androidOptions
        : iosOptions,
  );

  // Firebase Auth on mobile platforms already has built-in persistence
  // No need to set persistence manually - it's enabled by default

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2A7CF6),
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      // Start with splash screen
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        SlotSelectionScreen.routeName: (context) {
          final mall = ModalRoute.of(context)?.settings.arguments as MallModel?;
          if (mall == null) {
            return const Scaffold(
              body: Center(child: Text('No mall selected')),
            );
          }
          return SlotSelectionScreen(mall: mall);
        },
        VehicleDetailsScreen.routeName: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as VehicleDetailsArgs?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('No slot selected')),
            );
          }
          return VehicleDetailsScreen(mall: args.mall, slot: args.slot);
        },
        BookingConfirmationScreen.routeName: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as BookingConfirmationArgs?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('Missing booking details')),
            );
          }
          return BookingConfirmationScreen(args: args);
        },
        '/home': (context) => const HomeScreen(),
        'admin/nfc/write': (context) => const WriteNfcScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        'profile_screen': (context) => const ProfileScreen(),
        ManageSlotsScreen.routeName: (context) {
          final mallId = ModalRoute.of(context)?.settings.arguments as String?;
          return ManageSlotsScreen(initialMallId: mallId);
        },
        ReportsScreen.routeName: (context) {
          final mallId = ModalRoute.of(context)?.settings.arguments as String?;
          return ReportsScreen(initialMallId: mallId);
        },
        BookingHistoryScreen.routeName: (context) {
          final mallId = ModalRoute.of(context)?.settings.arguments as String?;
          return BookingHistoryScreen(initialMallId: mallId);
        },
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        AlertsScreen.routeName: (context) => const AlertsScreen(),
        ActiveBookingsScreen.routeName: (context) =>
            const ActiveBookingsScreen(),
        CreateCheckOutScreen.routeName: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as CreateCheckOutArgs?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('Missing checkout booking data')),
            );
          }
          return CreateCheckOutScreen(booking: args.booking);
        },
        ManualBookingNfcScreen.routeName: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as ManualBookingNfcArgs?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('Missing NFC data')),
            );
          }
          return ManualBookingNfcScreen(nfcData: args.nfcData);
        },
        '/admin/create-mall': (context) => const CreateMallScreen(),
        DataManagementScreen.routeName: (context) =>
            const DataManagementScreen(),
      },
    );
  }
}
