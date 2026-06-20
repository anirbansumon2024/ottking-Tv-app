// lib/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'settings_screen_widgets/settings_nav_sidebar.dart';
import 'settings_screen_widgets/settings_account_section.dart';
import 'settings_screen_widgets/settings_tv_section.dart';
import 'settings_screen_widgets/settings_system_section.dart';
import 'settings_screen_widgets/settings_status_footer.dart';

enum _Section { account, tvSettings, system }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // KeyboardListener এর FocusNode — autofocus: false রাখতে হবে
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'settings-root');

  // ৩টি নেভ আইটেমের FocusNode — সাইডবারে দেওয়া হবে, এখানে owner থাকায়
  // কনটেন্ট থেকে ← চাপলে সঠিক নেভ আইটেমে ফোকাস ফেরানো সহজ হয়
  final List<FocusNode> _navNodes = [
    FocusNode(debugLabel: 'settings-nav-0'),
    FocusNode(debugLabel: 'settings-nav-1'),
    FocusNode(debugLabel: 'settings-nav-2'),
  ];

  // প্রতিটি সেকশনের প্রথম ফোকাসেবল উইজেটের জন্য আলাদা নোড — → চাপলে
  // সাইডবার থেকে সরাসরি এখানে ফোকাস পাঠানো হবে
  final FocusNode _accountEntryNode = FocusNode(debugLabel: 'settings-account-entry');
  final FocusNode _tvEntryNode = FocusNode(debugLabel: 'settings-tv-entry');
  final FocusNode _systemEntryNode = FocusNode(debugLabel: 'settings-system-entry');

  _Section _activeSection = _Section.account;

  FocusNode get _activeContentEntryNode {
    switch (_activeSection) {
      case _Section.account:
        return _accountEntryNode;
      case _Section.tvSettings:
        return _tvEntryNode;
      case _Section.system:
        return _systemEntryNode;
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // স্ক্রিন লোড হলে সাইডবারের প্রথম আইটেমে ফোকাস
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _navNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    for (final n in _navNodes) n.dispose();
    _accountEntryNode.dispose();
    _tvEntryNode.dispose();
    _systemEntryNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      _safelyPop();
    }
  }

  void _safelyPop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return PopScope(
      canPop: true,
      child: KeyboardListener(
        focusNode: _rootFocusNode,
        // autofocus: false — সাইডবারের ফোকাস নোডে সঠিকভাবে ফোকাস যাবে
        autofocus: false,
        onKeyEvent: _handleKey,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0F19),
          body: Row(
            children: [
              // ── Left Sidebar ──────────────────────────────────────────
              // FocusTraversalGroup দিয়ে সাইডবার ও কনটেন্ট আলাদা করা হলো
              FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: SettingsNavSidebar(
                  activeSection: _activeSection.index,
                  navNodes: _navNodes,
                  onSelect: (i) {
                    setState(() => _activeSection = _Section.values[i]);
                  },
                  onBack: _safelyPop,
                  onMoveRight: () => _activeContentEntryNode.requestFocus(),
                ),
              ),

              Container(
                width: 1,
                color: Colors.white.withOpacity(0.05),
              ),

              // ── Right Content Area ────────────────────────────────────
              Expanded(
                child: SafeArea(
                  child: Focus(
                    skipTraversal: true,
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      // বাগ ফিক্স সম্পূরক: কনটেন্ট এরিয়া থেকে ← চাপলে আগে কিছুই
                      // হতো না (কোনো হ্যান্ডলার ছিল না), এখন সক্রিয় নেভ
                      // আইটেমে ফোকাস ফিরিয়ে দেওয়া হচ্ছে — যাতে যাওয়া-আসা
                      // দুই দিকেই কাজ করে।
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        _navNodes[_activeSection.index].requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: FocusTraversalGroup(
                      policy: WidgetOrderTraversalPolicy(),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _buildActiveSection(appState),
                            ),
                            const SizedBox(height: 40),
                            Divider(color: Colors.white.withOpacity(0.05)),
                            const SizedBox(height: 16),
                            SettingsStatusFooter(appState: appState),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection(AppState appState) {
    switch (_activeSection) {
      case _Section.account:
        return SettingsAccountSection(
          key: const ValueKey('account'),
          appState: appState,
          firstFocusNode: _accountEntryNode,
        );
      case _Section.tvSettings:
        return SettingsTvSection(
          key: const ValueKey('tv'),
          appState: appState,
          firstFocusNode: _tvEntryNode,
        );
      case _Section.system:
        return SettingsSystemSection(
          key: const ValueKey('system'),
          appState: appState,
          firstFocusNode: _systemEntryNode,
        );
    }
  }
}
