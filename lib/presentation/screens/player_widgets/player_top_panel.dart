// lib/presentation/screens/player_widgets/player_top_panel.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// বাগ ফিক্স: এই প্যানেল থেকে সেটিংস বাটন সরিয়ে ফেলা হয়েছে (ইউজারের রিকোয়েস্ট
// অনুযায়ী)। সেটিংস আইকন এখন চ্যানেল লিস্ট প্যানেলের উপরে থাকবে।
class PlayerTopPanel extends StatelessWidget {
  const PlayerTopPanel({
    super.key,
    required this.channel,
    required this.currentIndex,
    required this.totalChannels,
    this.typedNumber = '',
    this.isPlaying = false,
  });

  final dynamic channel;
  final int currentIndex;
  final int totalChannels;
  final String typedNumber; // নম্বর টাইপ হচ্ছে কিনা ট্র্যাক করার জন্য
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final bool isTyping = typedNumber.isNotEmpty;

    return Stack(
      children: [
        // ========== TOP-LEFT: ইন্টিগ্রেটেড একক চ্যানেল প্যানেল (নম্বর + নাম একসঙ্গে) ==========
        Positioned(
          top: 20,
          left: 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.80),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTyping
                    ? Colors.yellow.withOpacity(0.8)
                    : AppTheme.primary.withOpacity(0.6),
                width: isTyping ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 'CH ' প্রিফিক্স লেবেল
                Text(
                  'CH ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                // চ্যানেল নম্বর (টাইপ করার সময় ডায়নামিকালি হলুদ কালার হবে)
                Text(
                  isTyping ? typedNumber : '${currentIndex + 1}',
                  style: TextStyle(
                    color: isTyping ? Colors.yellow : AppTheme.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                // টাইপিং না চলাকালীন সময়ে নম্বরের পাশে একটি সুন্দর ডিভাইডার এবং নাম দেখাবে
                if (!isTyping) ...[
                  Container(
                    height: 18,
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  // টেক্সট ওভারফ্লো সেফটি সহ চ্যানেল নাম (টিভি স্ক্রিনের জন্য অপ্টিমাইজড)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 280), // নামের জন্য সর্বোচ্চ উইডথ ফিক্সড
                    child: Text(
                      channel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ========== TOP-RIGHT: চ্যানেল নম্বর / মোট চ্যানেল ইনফো ব্যাজ ==========
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.live_tv_rounded, color: AppTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${currentIndex + 1} / $totalChannels',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
