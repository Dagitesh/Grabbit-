import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/admin/settings/presentation/screens/admin_settings_screen.dart';
import 'package:grabbit_app/features/auth/presentation/providers/auth_provider.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final u = auth.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Icon(Icons.admin_panel_settings, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              if (u != null) ...[
                Text(
                  u.fullName.isNotEmpty ? u.fullName : 'Admin',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(u.email, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                if (u.phone != null && u.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(u.phone!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                ],
                const SizedBox(height: 8),
                Chip(
                  label: Text(u.role),
                  avatar: const Icon(Icons.verified_user_outlined, size: 18),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tune),
                      title: const Text('App settings'),
                      subtitle: const Text('Intro image and app configuration'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AdminSettingsScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red.shade700),
                      title: Text('Log out', style: TextStyle(color: Colors.red.shade700)),
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log out'),
                            content: const Text('Sign out of the admin account?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await context.read<AuthProvider>().logout();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
