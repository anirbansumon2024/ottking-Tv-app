// lib/presentation/screens/player_widgets/app_info_dialog.dart (বা আপনার সেটিংস ফাইল)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';

class PlayerSettingsDialog extends StatefulWidget {
  const PlayerSettingsDialog({
    super.key,
    required this.state,
    required this.onAppInfo,
    required this.onNavigateSettings,
    required this.onClose,
  });

  final AppState state;
  final VoidCallback onAppInfo;
  final VoidCallback onNavigateSettings;
  final VoidCallback onClose;

  @override
  State<PlayerSettingsDialog> createState() => _PlayerSettingsDialogState();
}

class _PlayerSettingsDialogState extends State<PlayerSettingsDialog> {
  // এখানে আইটেম সংখ্যা ডায়নামিকালি ক্যালকুলেট হবে
  late List<FocusNode> _focusNodes;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    // ৪টি আইটেম: Boot Switch, User Info(optional), App Info, Settings Action
    final itemCount = widget.state.isAuthenticated ? 4 : 3;
    _focusNodes = List.generate(itemCount, (i) => FocusNode(debugLabel: 'settings-item-$i'));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _focusNodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.settings, color: AppTheme.primary),
          SizedBox(width: 10),
          Text('প্লেয়ার সেটিংস', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ১. Boot Switch
            _SettingsTile(
              focusNode: _focusNodes[0],
              icon: Icons.power_settings_new_rounded,
              title: 'Boot Player (অটো প্লেয়ার)',
              subtitle: 'অ্যাপ চালু হলে সরাসরি লাইভ টিভি ওপেন হবে',
              trailing: Switch(
                value: widget.state.isPlayerBootEnabled,
                onChanged: (_) => widget.state.togglePlayerBoot(),
                activeColor: AppTheme.primary,
              ),
              onTap: () => widget.state.togglePlayerBoot(),
            ),

            // ২. User Info (যদি থাকে)
            if (widget.state.isAuthenticated)
              _SettingsTile(
                focusNode: _focusNodes[1],
                icon: Icons.stars_rounded,
                title: widget.state.userProfile?.email ?? 'User',
                subtitle: 'প্যাকেজ: ${widget.state.userProfile?.plan ?? 'N/A'}',
                onTap: () {},
              ),

            // ৩. App Info
            _SettingsTile(
              focusNode: _focusNodes[widget.state.isAuthenticated ? 2 : 1],
              icon: Icons.info_outline_rounded,
              title: 'অ্যাপ তথ্য (App Info)',
              subtitle: 'ভার্সন ও ডেভেলপার তথ্য',
              onTap: widget.onAppInfo,
            ),
          ],
        ),
      ),
      actions: [
        // ৪. Settings Action Button
        Focus(
          focusNode: _focusNodes.last,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select)) {
              widget.onNavigateSettings();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextButton(
            onPressed: widget.onNavigateSettings,
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: const Text('সিস্টেম সেটিংস'),
          ),
        ),
        TextButton(
          onPressed: widget.onClose,
          child: const Text('বন্ধ', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}

// একটি ক্লিন এবং ফোকাসযোগ্য কাস্টম টাইল
class _SettingsTile extends StatelessWidget {
  final FocusNode focusNode;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.focusNode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.select)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (context) {
        final focused = focusNode.hasFocus;
        return InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: focused ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(icon, color: focused ? Colors.white : AppTheme.primary),
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              trailing: trailing,
            ),
          ),
        );
      }),
    );
  }
}