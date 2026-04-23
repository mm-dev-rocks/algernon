// SPDX-License-Identifier: GPL-3.0-only

import 'dart:io';

import 'package:flutter/material.dart';

/// Provides [Player], [Media], [Playlist] etc.
import 'package:path_provider/path_provider.dart';

import 'app_state.dart';
import 'constants.dart';
import 'pages/root_page.dart';

/// Main app entry point / main class.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// App preferences [SharedPreferencesWithCache] require async setup
  await AppState.initPreferences();

  runApp(const AlgernonApp());
}

/// Main app wrapper.
class AlgernonApp extends StatefulWidget {
  const AlgernonApp({super.key});

  @override
  State<AlgernonApp> createState() => _AlgernonAppState();
}

class _AlgernonAppState extends State<AlgernonApp> {
  /// [_navigatorKey] is used to refer to the state of a specific Navigator.
  ///
  /// It will be assigned as the [key] to our main Navigator below, then when
  /// parts of the app want to navigate within that Navigator they will refer
  /// to [_navigatorKey].
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    AppState.log("main INITSTATE");
    _setupCacheDirectory();

    /// A reference to [_navigatorKey] is stored in [AppState] (as
    /// [mainNavigatorKey]) so that other classes can access it.
    AppState.update("mainNavigatorKey", _navigatorKey);

    super.initState();
  }

  /// Generate routes for nested navigation
  Route _onGenerateRoute(RouteSettings settings) {
    late Widget page;

    //AppState.debug("_onGenerateRoute(${settings.name})");

    switch (settings.name) {
      case ALGERNON.routeRoot:
        page = const RootPage();
        break;
      default:
        throw Exception('UNKNOWN NAVIGATION ROUTE: ${settings.name}');
    }

    return MaterialPageRoute<dynamic>(
      builder: (context) {
        return RepaintBoundary(child: page);
      },
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppState.log("main BUILD");

    return MaterialApp(
      title: ALGERNON.appName,
      debugShowCheckedModeBanner: false,
      onNavigationNotification: (notification) {
        return notification.canHandlePop;
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        dropdownMenuTheme: Theme.of(context).dropdownMenuTheme.copyWith(
          textStyle: const TextStyle(color: Colors.white),
          menuStyle: MenuStyle(
            padding: WidgetStateProperty<EdgeInsets?>.fromMap(
              <WidgetStatesConstraint, EdgeInsets?>{
                WidgetState.error: const EdgeInsets.all(6),
                WidgetState.hovered & WidgetState.focused: const EdgeInsets.all(
                  6,
                ),
                WidgetState.focused: const EdgeInsets.all(6),
                ~WidgetState.disabled: const EdgeInsets.all(6),
              },
            ),
            backgroundColor: WidgetStateColor.resolveWith((states) {
              return Colors.black.withValues(alpha: 0.7);
            }),
            shadowColor: WidgetStateColor.resolveWith((states) {
              return Colors.transparent;
            }),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.white.withValues(alpha: 0.2),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
          thumbColor: Colors.white,
          overlayColor: Colors.white.withValues(alpha: 0.2),
          valueIndicatorColor: Colors.white,
          trackHeight: 1.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
          valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
          showValueIndicator: ShowValueIndicator.alwaysVisible,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: AppStateWidget(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: NavigatorPopHandler(
                    onPop: () async {
                      await AppState.handleNavigateBack();
                    },
                    child: Navigator(
                      key: _navigatorKey,
                      initialRoute: ALGERNON.routeRoot,
                      onGenerateRoute: _onGenerateRoute,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setupCacheDirectory() async {
    // Get cache directory and store reference to it for use throughout the app
    Directory dir = await getApplicationCacheDirectory();
    AppState.update('cacheDirectoryPath', "${dir.path}/");
  }
}
