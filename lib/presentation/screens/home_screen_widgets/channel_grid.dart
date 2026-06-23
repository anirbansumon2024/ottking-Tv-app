import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../../presentation/widgets/tv_focus_card.dart';

class ChannelGrid extends StatefulWidget {
  const ChannelGrid({
    super.key,
    required this.channels,
    required this.chNodes,
    required this.appState,
    required this.categoryName,
  });

  final List channels;
  final List<FocusNode> chNodes;
  final AppState appState;
  final String categoryName;

  @override
  State<ChannelGrid> createState() => _ChannelGridState();
}

class _ChannelGridState extends State<ChannelGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ক্যাটাগরি পরিবর্তনের সময় গ্রিড রিরেন্ডার নিশ্চিত করতে KeyedSubtree
    return KeyedSubtree(
      key: ValueKey(widget.categoryName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8, left: 4),
            child: Row(
              children: [
                Text(
                  '${widget.categoryName} CHANNELS',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.channels.length}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Grid ──────────────────────────────────────────────────────
          Expanded(
            child: widget.channels.isEmpty
                ? const Center(
                    child: Text(
                      'কোনো চ্যানেল পাওয়া যায়নি',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: widget.channels.length,
                    itemBuilder: (context, i) {
                      // ইনডেক্স সেফটি চেক
                      if (i >= widget.chNodes.length) return const SizedBox.shrink();

                      final ch = widget.channels[i];
                      final origIdx = widget.appState.channels.indexOf(ch);
                      final playing = widget.appState.currentChannelIndex == origIdx;

                      return TvFocusCard(
                        focusNode: widget.chNodes[i],
                        selected: playing,
                        padding: EdgeInsets.zero,
                        onFocusChange: (hasFocus) {
                          if (hasFocus) {
                            // ফোকাস আইটেমকে স্ক্রিনের ভিউতে নিয়ে আসা
                            Scrollable.ensureVisible(
                              context,
                              duration: const Duration(milliseconds: 200),
                              alignment: 0.5,
                            );
                          }
                        },
                        onTap: () {
                          widget.appState.selectChannelByIndex(origIdx);
                          Navigator.pushNamed(context, '/player');
                        },
                        child: ChannelCard(
                          channel: ch,
                          isPlaying: playing,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Channel Card ────────────────────────────────────────────────────────────
class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    required this.isPlaying,
  });
  final dynamic channel;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppTheme.card,
            child: channel.logoUrl.trim().isNotEmpty
                ? Image.network(
                    channel.logoUrl.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _logoPlaceholder(),
                  )
                : _logoPlaceholder(),
          ),
          // Gradient Overlay
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Text(
                channel.name,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Badges
          Positioned(
            top: 6, left: 6,
            child: Row(
              children: [
                if (channel.isPremium == 1)
                  const _Badge(label: 'PREMIUM', bg: Color(0xFFEAB308), fg: Colors.black),
                const SizedBox(width: 3),
                _Badge(label: channel.quality.toUpperCase(), bg: Colors.black.withOpacity(0.7), fg: AppTheme.primary),
              ],
            ),
          ),
          // Playing Indicator
          if (isPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(padding: EdgeInsets.all(6), child: _LiveDot()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() => const Center(
        child: Icon(Icons.live_tv_rounded, color: Colors.white24, size: 32),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: Colors.white),
          SizedBox(width: 4),
          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}