import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' as native_vp;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'player_widgets/player_top_panel.dart';
import 'player_widgets/player_bottom_bar.dart';
import 'player_widgets/channel_list_panel.dart';
import 'player_widgets/loading_overlay.dart';
import 'player_widgets/app_info_dialog.dart';
import 'player_widgets/app_exit_settings.dart';

class _SecurePlayerHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => "DIRECT"; 
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => false; 
    return client;
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}



class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  final FocusNode _focus = FocusNode(debugLabel: 'player-root');

  // শুধু নেটিভ কন্ট্রোলার
  native_vp.VideoPlayerController? _nativeCtrl;
  
  String? _activeChannelId;
  bool _showControls = true;
  bool _isLoading = false;
  bool _hasStreamError = false;
  bool _showChannelList = false;

  AppState? _appState;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    // Proxy/Secure stream handling এর জন্য HttpOverrides এখানে থাকবে
    HttpOverrides.global = _SecurePlayerHttpOverrides();
    // ... বাকি ইনিট লজিক
  }

  // প্রক্সি এবং স্ট্রিম সাপোর্ট নিশ্চিত করা
  Future<void> _initController() async {
    if (!mounted || _appState == null) return;
    final channel = _appState!.currentChannel;

    // যদি স্ট্রিম ইউআরএল এ .php থাকে তবে সেটাকে প্রক্সি হিসেবে হ্যান্ডেল করার প্রস্তুতি
    final uri = Uri.parse(channel.streamUrl);
    
    setState(() {
      _isLoading = true;
      _hasStreamError = false;
      _activeChannelId = channel.id;
    });

    await _disposeControllers();

    final newCtrl = native_vp.VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: native_vp.VideoPlayerOptions(allowBackgroundPlayback: false),
      httpHeaders: {
        'User-Agent': 'oTtking-AndroidTV-Secure-Agent',
        'Referer': 'https://ottking.internal/', // PHP প্রক্সি স্ট্রিমের জন্য রেফারার গুরুত্বপূর্ণ
        'X-App-Token': 'backend_generated_secret_handshake_token',
      },
    );

    try {
      await newCtrl.initialize();
      if (!mounted) return;
      await newCtrl.play();
      
      setState(() {
        _nativeCtrl = newCtrl;
        _isLoading = false;
      });
    } catch (e) {
      _handleLoadError();
    }
  }

  // মূল কি-হ্যান্ডলার যেখানে OK বাটনে চ্যানেল লিস্ট টগল হবে
  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // OK বাটনে সরাসরি চ্যানেল লিস্ট
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
      setState(() {
        _showChannelList = !_showChannelList;
        _showControls = true;
      });
      return;
    }

    // ব্যাক বাটনে এক্সিট
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      if (_showChannelList) {
        setState(() => _showChannelList = false);
      } else {
        _invokeExitWidget();
      }
      return;
    }

    // চ্যানেল আপ/ডাউন ইভেন্ট
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.channelUp) {
      _switchChannel(-1);
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.channelDown) {
      _switchChannel(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focus,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ভিডিও লেয়ার
            if (_nativeCtrl != null && _nativeCtrl!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _nativeCtrl!.value.aspectRatio,
                  child: native_vp.VideoPlayer(_nativeCtrl!),
                ),
              ),

            // চ্যানেল লিস্ট প্যানেল (OK বাটনে টগল হবে)
            if (_showChannelList)
              ChannelListPanel(
                channels: _appState!.channels,
                currentIndex: _appState!.currentChannelIndex,
                onSelect: (i) {
                  setState(() => _showChannelList = false);
                  _switchToIndex(i);
                },
                onClose: () => setState(() => _showChannelList = false),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _disposeControllers() async {
    await _nativeCtrl?.dispose();
    _nativeCtrl = null;
  }
}