// lib/presentation/screens/settings_screen_widgets/settings_tv_section.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'settings_shared_widgets.dart';

class SettingsTvSection extends StatelessWidget {
  const SettingsTvSection({super.key, required this.appState, this.firstFocusNode});
  final AppState appState;
  final FocusNode? firstFocusNode;

  @override
  Widget build(BuildContext context) {
    final isBootEnabled = appState.isPlayerBootEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // এখানে বানানটি ঠিক করে দিলাম
        const SectionHeader(title: 'TV Settings'), 
        const SizedBox(height: 16),

        SettingsTwoColRow(
          children: [
            SettingCard(
              icon: Icons.rocket_launch_rounded,
              title: 'Boot Player',
              subtitle: isBootEnabled
                  ? 'Switch Player'
                  : 'Switch Home',
              highlight: isBootEnabled,
              focusNode: firstFocusNode,
              trailing: Switch(
                value: isBootEnabled,
                activeColor: AppTheme.primary,
                onChanged: null, // চমৎকার, এটি ফোকাস কনফ্লিক্ট এড়াবে
              ),
              onTap: () => appState.togglePlayerBoot(),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}