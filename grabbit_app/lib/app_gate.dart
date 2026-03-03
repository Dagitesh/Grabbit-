import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:grabbit_app/features/auth/presentation/screens/login_screen.dart';
import 'package:grabbit_app/features/customer/shell/customer_shell_screen.dart';
import 'package:grabbit_app/features/vendor/shell/vendor_shell_screen.dart';

/// Routes to Login, Vendor shell, or Customer shell based on auth status and user role.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureUserLoaded());
  }

  Future<void> _ensureUserLoaded() async {
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.authenticated && (auth.user == null || auth.user!.role.isEmpty)) {
      await auth.fetchUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final status = auth.status;
    final user = auth.user;

    if (status == AuthStatus.initial) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }

    final effectiveRole = (auth.viewAsRole ?? user?.role ?? '').toUpperCase();
    if (effectiveRole == 'VENDOR') {
      return const VendorShellScreen();
    }

    return const CustomerShellScreen();
  }
}
