// lib/presentation/screens/player_widgets/app_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class AppInfoDialog extends StatefulWidget {
  const AppInfoDialog({super.key});

  @override
  State<AppInfoDialog> createState() => _AppInfoDialogState();
}

class _AppInfoDialogState extends State<AppInfoDialog> {
  final FocusNode _closeFocusNode = FocusNode(debugLabel: 'dialog-close-btn');
  bool _isCloseFocused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _closeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _closeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ব্যাক বাটন হ্যান্ডলিংয়ের জন্য Focus-এর বাইরে একটি মেইন কন্টেইনার
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.goBack): () => Navigator.pop(context),
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context),
      },
      child: AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_rounded, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('অ্যাপ তথ্য', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoCard(
                title: 'Live TV Player',
                subtitle: 'Version 1.0.0',
              ),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Ltv digital Limited',
                subtitle: 'কোম্পানি',
                isHighlighted: true,
              ),
            ],
          ),
        ),
        actions: [
          Focus(
            focusNode: _closeFocusNode,
            onFocusChange: (v) => setState(() => _isCloseFocused = v),
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select)) {
                Navigator.pop(context);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: _isCloseFocused ? AppTheme.primary : Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'বন্ধ',
                style: TextStyle(
                  color: _isCloseFocused ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// কোড রিইউজেবিলিটির জন্য ছোট হেল্পার উইজেট
class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isHighlighted;

  const _InfoCard({required this.title, required this.subtitle, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }
}