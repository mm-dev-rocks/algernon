// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:algernon/constants.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class AlgernonWindow extends StatefulWidget {
  const AlgernonWindow({super.key});

  static ValueNotifier<bool> isFullscreenNotifier = ValueNotifier(false);

  static void toggleFullscreen() async {
    AlgernonWindow.isFullscreenNotifier.value = !(await windowManager
        .isFullScreen());
    await windowManager.setFullScreen(
      AlgernonWindow.isFullscreenNotifier.value,
    );
  }

  static void setFullscreenState(bool isFullscreen) async {
    AlgernonWindow.isFullscreenNotifier.value = isFullscreen;
  }

  @override
  State<AlgernonWindow> createState() => _AlgernonWindowState();
}

class _AlgernonWindowState extends State<AlgernonWindow> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowLeaveFullScreen() {
    debugPrint('AlgernonWindow::onWindowLeaveFullScreen()');
    AlgernonWindow.setFullscreenState(false);
    super.onWindowLeaveFullScreen();
  }

  @override
  void onWindowEnterFullScreen() {
    debugPrint('AlgernonWindow::onWindowEnterFullScreen()');
    AlgernonWindow.setFullscreenState(true);
    super.onWindowEnterFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AlgernonWindow.isFullscreenNotifier,
      builder: (context, value, child) {
        bool isFullscreen = value;
        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          onPressed: AlgernonWindow.toggleFullscreen,
          icon: Icon(
            isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: ALGERNON.uiDefaultForegroundColor,
          ),
        );
      },
    );
  }
}
