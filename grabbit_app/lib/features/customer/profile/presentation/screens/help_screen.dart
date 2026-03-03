import 'package:flutter/material.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String phone = '+251970753418';
  static const String email = 'info@grabbit.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.support_agent, size: 64, color: AppColors.primary.withOpacity(0.8)),
            const SizedBox(height: 24),
            Text(
              'Grabbit support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'If you have any inquiries, reports, or need assistance, please contact the Grabbit team:',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _ContactTile(
              icon: Icons.phone,
              label: 'Phone',
              value: phone,
              onTap: () => _launchPhone(context),
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.email,
              label: 'Email',
              value: email,
              onTap: () => _launchEmail(context),
            ),
          ],
        ),
      ),
    );
  }

  void _launchPhone(BuildContext context) {
    // In a real app you'd use url_launcher to open tel:$phone
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call $phone')),
    );
  }

  void _launchEmail(BuildContext context) {
    // In a real app you'd use url_launcher to open mailto:$email
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Email $email')),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
