// lib/presentation/screens/home_screen_widgets/category_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class CategorySidebar extends StatelessWidget {
  const CategorySidebar({
    super.key,
    required this.cats,
    required this.catNodes,
    required this.selectedIndex,
    required this.onSelect,
    this.onMoveRight,
  });

  final List<Map<String, String>> cats;
  final List<FocusNode> catNodes;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onMoveRight;

  @override
  Widget build(BuildContext context) {
    // ফোকাস ট্র্যাভার্সাল গ্রুপ ব্যবহার করলে ফোকাস বাউন্ডারি ঠিক থাকে
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12, top: 8),
            child: Text(
              '🔥 CATEGORIES',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cats.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, i) {
                final cat = cats[i];
                return CategoryItem(
                  focusNode: catNodes[i],
                  icon: cat['icon']!,
                  name: cat['name']!,
                  selected: selectedIndex == i,
                  onTap: () => onSelect(i),
                  onFocus: () => onSelect(i),
                  onMoveRight: onMoveRight,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem extends StatefulWidget {
  const CategoryItem({
    super.key,
    required this.focusNode,
    required this.icon,
    required this.name,
    required this.selected,
    required this.onTap,
    required this.onFocus,
    this.onMoveRight,
  });

  final FocusNode focusNode;
  final String icon;
  final String name;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onFocus;
  final VoidCallback? onMoveRight;

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  // FocusNode থেকেই ফোকাস স্টেট সরাসরি জানা যায়, আলাদা bool এর প্রয়োজন নেই
  // তবে অ্যানিমেশন বা ডিজাইনের জন্য এটি রাখা যেতে পারে

  @override
  Widget build(BuildContext context) {
    // সরাসরি ফোকাস নোড থেকে ফোকাস চেক করা বেশি সলিড
    final isFocused = widget.focusNode.hasFocus;
    final active = isFocused || widget.selected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (v) {
          // রেন্ডার আপডেট করার জন্য
          setState(() {});
          if (v) widget.onFocus();
        },
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;

          if (e.logicalKey == LogicalKeyboardKey.enter ||
              e.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }

          if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onMoveRight?.call();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isFocused
                  ? AppTheme.primary
                  : widget.selected
                      ? AppTheme.primary.withOpacity(0.15)
                      : AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppTheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(widget.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: active ? Colors.white70 : Colors.white24,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}