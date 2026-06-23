import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'home_screen_widgets/home_top_bar.dart';
import 'home_screen_widgets/category_sidebar.dart';
import 'home_screen_widgets/channel_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'home-root');
  final FocusNode _settingsFocusNode = FocusNode(debugLabel: 'home-settings');

  int _selectedCategoryIndex = 0;
  final List<FocusNode> _catNodes = [];
  final List<FocusNode> _chNodes = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // প্রাথমিক ফোকাস সেটআপ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeInitialFocus();
    });
  }

  void _initializeInitialFocus() {
    if (_catNodes.isNotEmpty) {
      _catNodes[0].requestFocus();
    }
  }

  // ফোকাস নোড ম্যানেজমেন্ট
  void _updateFocusNodes(int targetLength, List<FocusNode> nodeList, String prefix) {
    if (nodeList.length == targetLength) return;
    if (nodeList.length < targetLength) {
      while (nodeList.length < targetLength) {
        nodeList.add(FocusNode(debugLabel: '$prefix-${nodeList.length}'));
      }
    } else {
      while (nodeList.length > targetLength) {
        nodeList.removeLast().dispose();
      }
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  void _changeCategory(int index) {
    if (_selectedCategoryIndex == index) return;

    setState(() {
      _selectedCategoryIndex = index;
    });

    // ক্যাটাগরি পরিবর্তনের পর গ্রিডে ফোকাস পাঠানো (যদি গ্রিডে ডেটা থাকে)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chNodes.isNotEmpty) {
        _chNodes[0].requestFocus();
      } else {
        // যদি গ্রিডে কিছু না থাকে, তবে ক্যাটাগরিতেই ফোকাস থাকবে
        if (_catNodes.length > index) {
          _catNodes[index].requestFocus();
        }
      }
    });
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    _settingsFocusNode.dispose();
    for (final n in _catNodes) n.dispose();
    for (final n in _chNodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    final cats = [
      {'name': 'All', 'icon': '🌐'},
      ...appState.categories.map((c) => {'name': c.name, 'icon': c.icon}),
    ];

    // নোড লিস্ট আপডেট (বিল্ড মেথডে কল করা নিরাপদ যদি লিস্ট সাইজ ঠিক থাকে)
    _updateFocusNodes(cats.length, _catNodes, 'cat');

    final currentCat = cats[_selectedCategoryIndex]['name']!;
    final filtered = appState.channels.where((ch) {
      if (currentCat == 'All') return true;
      return ch.category.trim().toLowerCase() == currentCat.trim().toLowerCase();
    }).toList();

    _updateFocusNodes(filtered.length, _chNodes, 'chan');

    return KeyboardListener(
      focusNode: _rootFocusNode,
      onKeyEvent: (node, event) => _handleKey(event),
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              HomeTopBar(
                appState: appState,
                settingsFocusNode: _settingsFocusNode,
                onSettingsDown: () {
                  if (_catNodes.isNotEmpty) _catNodes[_selectedCategoryIndex].requestFocus();
                },
              ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: size.width * 0.18,
                      child: CategorySidebar(
                        cats: cats,
                        catNodes: _catNodes,
                        selectedIndex: _selectedCategoryIndex,
                        onSelect: _changeCategory,
                        onMoveRight: () {
                          if (_chNodes.isNotEmpty) _chNodes[0].requestFocus();
                        },
                      ),
                    ),
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            _catNodes[_selectedCategoryIndex].requestFocus();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: ChannelGrid(
                          channels: filtered,
                          chNodes: _chNodes,
                          appState: appState,
                          categoryName: currentCat,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}