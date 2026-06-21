// lib/presentation/screens/settings_screen_widgets/settings_account_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'settings_shared_widgets.dart';
import 'auth_dialog.dart';
import 'subscription_dialog.dart';

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key, required this.appState, this.firstFocusNode});
  final AppState appState;
  final FocusNode? firstFocusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Accounts'),
        const SizedBox(height: 16),

        // ১. লগইন থাকলে প্রোফাইল কার্ড
        if (appState.isAuthenticated && appState.userProfile != null) ...[
          AccountCard(profile: appState.userProfile!),
          const SizedBox(height: 16),
        ],

        // ২. অ্যাকশন কার্ড জোন
        SettingsTwoColRow(
          children: [
            SettingCard(
              icon: appState.isAuthenticated ? Icons.manage_accounts_rounded : Icons.login_rounded,
              title: appState.isAuthenticated ? 'Manage Account' : 'Login',
              subtitle: appState.isAuthenticated 
                  ? (appState.userProfile?.email ?? 'Logged in')
                  : 'Log in with a subscribed account to watch premium channels.',
              highlight: appState.isAuthenticated,
              focusNode: firstFocusNode,
              onTap: () {
                // লজিক্যাল গার্ড: লগইন থাকলে পপ-আপ আসবে না
                if (appState.isAuthenticated) return; 

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AuthDialog(),
                );
              },
            ),
            SettingCard(
              icon: Icons.card_membership_rounded,
              title: 'Subscription',
              subtitle: appState.isAuthenticated 
                  ? 'Plan: ${appState.userProfile?.plan ?? "–"}' 
                  : 'Packages & Pricing',
              onTap: () => showDialog(
                context: context,
                builder: (_) => SubscriptionDialog(plans: appState.plans),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── ৩. কম্প্যাক্ট অ্যাকাউন্ট প্রোফাইল কার্ড ──
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.profile});
  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>(); 
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.card, const Color(0xFF131B2E).withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withOpacity(0.12),
            child: Text(
              (profile.email != null && profile.email.isNotEmpty) 
                  ? profile.email[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.email ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFEAB308), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Plan: ${profile.plan ?? "N/A"}',
                      style: const TextStyle(color: Color(0xFFEAB308), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.focused)) return Colors.red.withOpacity(0.2);
                return Colors.transparent;
              }),
            ),
            onPressed: () => appState.logout(),
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}