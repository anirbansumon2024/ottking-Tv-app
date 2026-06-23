// lib/presentation/screens/player_screen.dart
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
import 'player_widgets/channel_list_panel.dart';
import 'player_widgets/loading_overlay.dart';
import 'player_widgets/app_exit_settings.dart';

class _SecurePlayerHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => "DIRECT"; 
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true; 
    return client;
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final FocusNode _focus = FocusNode(debugLabel: 'player-root');
  native_vp.VideoPlayerController? _nativeCtrl;
  
  bool _isLoading = false;
  bool _hasStreamError = false;
  bool _showChannelList = false;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    HttpOverrides.global = _SecurePlayerHttpOverrides();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appState = Provider.of<AppState>(context, listen: false);
      _initController();
      _focus.requestFocus();
    });
  }

  Future<void> _initController() async {
    if (!mounted || _appState == null) return;
    final channel = _appState!.currentChannel;

    setState(() {
      _isLoading = true;
      _hasStreamError = false;
    });

    await _disposeControllers();

    final newCtrl = native_vp.VideoPlayerController.networkUrl(
      Uri.parse(channel.streamUrl),
      httpHeaders: {
        'User-Agent': 'oTtking-AndroidTV-Secure-Agent',
        'Referer': 'https://ottking.internal/',
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
      if (mounted) setState(() => _hasStreamError = true);
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // OK বাটনে চ্যানেল লিস্ট টগল
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
      setState(() => _showChannelList = !_showChannelList);
      return;
    }

    // ব্যাক বাটনে এক্সিট বা লিস্ট ক্লোজ
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      if (_showChannelList) {
        setState(() => _showChannelList = false);
      } else {
        _invokeExitWidget();
      }
      return;
    }

    // চ্যানেল পরিবর্তন
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.channelUp) _switchChannel(-1);
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.channelDown) _switchChannel(1);
  }

  void _switchChannel(int direction) async {
    _appState!.switchChannel(direction);
    _initController();
  }

  void _switchToIndex(int index) async {
    _appState!.selectChannelByIndex(index);
    _initController();
  }

  Future<void> _invokeExitWidget() async {
    if (_appState == null) return;
    await AppExitHandler.handleExit(
      context: context,
      appState: _appState!,
      onBeforeDispose: _disposeControllers,
    );
  }

  // রিকোয়েস্ট অনুযায়ী ডিসপোজ মেথডটি আবার যুক্ত করা হলো
  Future<void> _disposeControllers() async {
    if (_nativeCtrl != null) {
      await _nativeCtrl!.dispose();
      _nativeCtrl = null;
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    _focus.dispose();
    WakelockPlus.disable();
    super.dispose();
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
            if (_nativeCtrl != null && _nativeCtrl!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _nativeCtrl!.value.aspectRatio,
                  child: native_vp.VideoPlayer(_nativeCtrl!),
                ),
              ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
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
}