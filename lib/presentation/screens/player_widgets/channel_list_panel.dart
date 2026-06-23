// lib/presentation/screens/player_widgets/channel_list_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class ChannelListPanel extends StatefulWidget {
  const ChannelListPanel({
    super.key,
    required this.channels,
    required this.currentIndex,
    required this.onSelect,
    required this.onClose,
    required this.onSettings, // নতুন প্রপার্টি
  });

  final List channels;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  final VoidCallback onSettings; // সেটিংস কলব্যাক

  @override
  State<ChannelListPanel> createState() => _ChannelListPanelState();
}

class _ChannelListPanelState extends State<ChannelListPanel> {
  final ScrollController _scrollController = ScrollController();
  late final List<FocusNode> _itemNodes;
  final FocusNode _closeBtnNode = FocusNode(debugLabel: 'ch-list-close');
  final FocusNode _settingsBtnNode = FocusNode(debugLabel: 'ch-list-settings');

  @override
  void initState() {
    super.initState();
    _itemNodes = List.generate(
      widget.channels.length,
      (i) => FocusNode(debugLabel: 'ch-list-item-$i'),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final idx = widget.currentIndex.clamp(0, _itemNodes.length - 1);
      _itemNodes[idx].requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _closeBtnNode.dispose();
    _settingsBtnNode.dispose();
    for (final n in _itemNodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0, top: 0, bottom: 0,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          border: Border(left: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 2)),
        ),
        child: Column(
          children: [
            // ── Header (Settings + Close) ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  const Text('চ্যানেল লিস্ট', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Settings Icon
                  _IconButtonFocus(
                    focusNode: _settingsBtnNode,
                    icon: Icons.settings_rounded,
                    onTap: widget.onSettings,
                  ),
                  const SizedBox(width: 8),
                  // Close Icon
                  _IconButtonFocus(
                    focusNode: _closeBtnNode,
                    icon: Icons.close,
                    onTap: widget.onClose,
                  ),
                ],
              ),
            ),
            // ── List ─────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.channels.length,
                itemBuilder: (ctx, i) => _ChannelListItem(
                  focusNode: _itemNodes[i],
                  index: i,
                  channelName: widget.channels[i].name,
                  isActive: i == widget.currentIndex,
                  onSelect: () => widget.onSelect(i),
                  onClose: widget.onClose,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── IconButton (Settings & Close Helper) ─────────────────────
class _IconButtonFocus extends StatefulWidget {
  final FocusNode focusNode;
  final IconData icon;
  final VoidCallback onTap;
  const _IconButtonFocus({required this.focusNode, required this.icon, required this.onTap});

  @override
  State<_IconButtonFocus> createState() => _IconButtonFocusState();
}

class _IconButtonFocusState extends State<_IconButtonFocus> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _focused ? AppTheme.primary : Colors.white12, borderRadius: BorderRadius.circular(8)),
        child: Icon(widget.icon, size: 20, color: _focused ? Colors.black : Colors.white),
      ),
    );
  }
}

// ── Channel Item (Same as before) ─────────────────────
class _ChannelListItem extends StatelessWidget {
  final FocusNode focusNode;
  final int index;
  final String channelName;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  const _ChannelListItem({required this.focusNode, required this.index, required this.channelName, required this.isActive, required this.onSelect, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (_, event) {
         if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select)) {
          onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (context) {
        final focused = Focus.of(context).hasFocus;
        return InkWell(
          onTap: onSelect,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: focused ? AppTheme.primary.withOpacity(0.3) : (isActive ? Colors.white.withOpacity(0.05) : Colors.transparent)),
            child: Row(
              children: [
                Text('${index + 1}', style: TextStyle(color: focused ? Colors.white : Colors.white38)),
                const SizedBox(width: 15),
                Expanded(child: Text(channelName, style: TextStyle(color: focused ? Colors.white : Colors.white70))),
              ],
            ),
          ),
        );
      }),
    );
  }
}