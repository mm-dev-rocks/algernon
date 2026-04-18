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
  await AppState.initPreferences();

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
        return RepaintBoundary(child: page);
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
              return Colors.transparent;
            }),
            shadowColor: WidgetStateColor.resolveWith((states) {
              return Colors.transparent;
            }),
            //backgroundColor: WidgetStateColor.resolveWith((states) {
            //  if (states.contains(WidgetState.pressed))
            //    return Colors.blue[700]!;
            //  if (states.contains(WidgetState.hovered))
            //    return Colors.blue[400]!;
            //  return Colors.blue; // default / normal state
            //}),
          ),
        ),
        //textTheme: Theme.of(context).textTheme.copyWith(
        //  bodySmall: const TextStyle(color: Colors.white, fontSize: 16),
        //  bodyMedium: const TextStyle(color: Colors.white, fontSize: 16),
        //  bodyLarge: const TextStyle(color: Colors.white, fontSize: 16),
        //  displaySmall: const TextStyle(color: Colors.white, fontSize: 16),
        //  displayMedium: const TextStyle(color: Colors.white, fontSize: 16),
        //  displayLarge: const TextStyle(color: Colors.white, fontSize: 16),
        //  headlineSmall: const TextStyle(color: Colors.white, fontSize: 16),
        //  headlineMedium: const TextStyle(color: Colors.white, fontSize: 16),
        //  headlineLarge: const TextStyle(color: Colors.white, fontSize: 16),
        //  labelSmall: const TextStyle(color: Colors.white, fontSize: 16),
        //  labelMedium: const TextStyle(color: Colors.white, fontSize: 16),
        //  labelLarge: const TextStyle(color: Colors.white, fontSize: 16),
        //),
        //menuButtonTheme: MenuButtonThemeData(
        //  style: MenuItemButton.styleFrom(
        //    textStyle: Theme.of(context).textTheme.labelLarge,
        //  ),
        //),
        //elevatedButtonTheme: ElevatedButtonThemeData(
        //  style: MenuItemButton.styleFrom(
        //    textStyle: Theme.of(context).textTheme.labelLarge,
        //  ),
        //),
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
