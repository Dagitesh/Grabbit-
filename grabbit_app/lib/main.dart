import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/app_gate.dart';
import 'package:grabbit_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:grabbit_app/features/customer/home/providers/deal_provider.dart';
import 'package:grabbit_app/features/customer/home/providers/favorites_provider.dart';
import 'package:grabbit_app/features/customer/orders/providers/order_provider.dart';
import 'package:grabbit_app/features/customer/shell/customer_nav_provider.dart';
import 'package:grabbit_app/features/vendor/dashboard/providers/vendor_dashboard_provider.dart';
import 'package:grabbit_app/features/vendor/deals/providers/vendor_deal_provider.dart';
import 'package:grabbit_app/features/vendor/orders/providers/vendor_order_provider.dart';
import 'package:grabbit_app/features/vendor/profile/providers/vendor_profile_provider.dart';

void main() {
  runApp(const GrabbitApp());
}

class GrabbitApp extends StatelessWidget {
  const GrabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DealProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => CustomerNavProvider()),
        ChangeNotifierProvider(create: (_) => VendorDashboardProvider()),
        ChangeNotifierProvider(create: (_) => VendorDealProvider()),
        ChangeNotifierProvider(create: (_) => VendorOrderProvider()),
        ChangeNotifierProvider(create: (_) => VendorProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Grabbit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
            primary: AppColors.primary,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.scaffoldBackground,
          cardTheme: CardThemeData(
            color: AppColors.cardBackground,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: const AppGate(),
      ),
    );
  }
}
