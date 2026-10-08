import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;
    final currentUser = context.watch<AuthProvider>().currentUser;

    String providerLabel = 'Email & Password';
    if (currentUser?.isGuest == true || currentUser?.provider == 'anonymous') {
      providerLabel = 'Guest Account';
    } else if (currentUser?.provider == 'google') {
      providerLabel = 'Google OAuth';
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personal Information', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoCard(
              title: 'Full Name',
              value: currentUser?.name.isNotEmpty == true ? currentUser!.name : 'Retro Listener',
              icon: Icons.person_outline,
            ),
            _buildInfoCard(
              title: 'Email Address',
              value: currentUser?.email.isNotEmpty == true ? currentUser!.email : 'Not set',
              icon: Icons.email_outlined,
            ),
            _buildInfoCard(
              title: 'Account Type',
              value: providerLabel,
              icon: Icons.badge_outlined,
            ),
            _buildInfoCard(
              title: 'Account Role',
              value: currentUser?.role.toUpperCase() ?? 'USER',
              icon: Icons.security_outlined,
            ),
            _buildInfoCard(
              title: 'Account Created',
              value: _formatDate(currentUser?.createdAt),
              icon: Icons.calendar_today_outlined,
            ),
            _buildInfoCard(
              title: 'Last Active Session',
              value: _formatDate(currentUser?.lastLoginAt),
              icon: Icons.access_time_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.white38, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: AppTheme.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
