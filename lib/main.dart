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
  //debugRepaintRainbowEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();

  /// App preferences [SharedPreferencesWithCache] require async setup
  //await AppState.initPreferences();

  // Necessary initialization for package:media_kit.
  //MediaKit.ensureInitialized();

  runApp(const AlgernonApp());
}

/// Main app wrapper.
class AlgernonApp extends StatefulWidget {
  const AlgernonApp({super.key});

  @override
  State<AlgernonApp> createState() => _AlgernonAppState();
}

class _AlgernonAppState extends AppState<AlgernonApp> {
  /// We want to rebuild when 'preferences' changes, so the widgets eg
  /// checkboxes show their correct current state.
  @override
  List<String>? listenForChanges = ['themeChange'];

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
      //case ALGERNON.routePreferences:
      //  page = const Preferences();
      //  break;
      default:
        throw Exception('UNKNOWN NAVIGATION ROUTE: ${settings.name}');
    }

    return MaterialPageRoute<dynamic>(
      builder: (context) {
        //final UiSizes ui = Screen.uiSizesFromContext(context);
        return Padding(
          padding: EdgeInsets.zero,
          child: RepaintBoundary(child: page),
        );
      },
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppState.log("main BUILD");

    /// This [main] widget rebuilds when the theme changes so this is as good a place as any to
    /// call the [AlgernonAudioHandler.updateNotification] method.
    //AlgernonAudioHandler.updateNotification();

    return MaterialApp(
      title: ALGERNON.appName,
      //theme: ThemeHelper.getFlexSchemeFromColorOptionsKey(
      //    AppState.getPreference("colorScheme"), context),
      debugShowCheckedModeBanner: false,
      //themeAnimationDuration: Duration.zero,
      onNavigationNotification: (notification) {
        //_setAppBarStateByRoute(AppState.currentRoute);
        return notification.canHandlePop;
      },
      home: Scaffold(
        body: SafeArea(
          child: AppStateWidget(
            child: Stack(
              children: [
                Padding(
                  /// Individual pages must handle the horizontal padding as it affects the position
                  /// of scrollbars, which areas are active for scrolling etc.
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
