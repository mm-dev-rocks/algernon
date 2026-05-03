// SPDX-License-Identifier: GPL-3.0-only

import 'package:algernon/algernon_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final OutlineInputBorder _dropdownBorder = OutlineInputBorder(
    borderSide: BorderSide(color: ALGERNON.uiSoftForegroundColor),
  );

  @override
  void initState() {
    AppState.log("main INITSTATE");

    /// A reference to [_navigatorKey] is stored in [AppState] (as
    /// [mainNavigatorKey]) so that other classes can access it.
    AppState.update("mainNavigatorKey", _navigatorKey);

    HardwareKeyboard.instance.addHandler(_onKey);

    super.initState();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
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

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      debugPrint(event.logicalKey.toString());
      switch (event.logicalKey.keyLabel) {
        /// Space toggle pause
        case " ":
          AlgernonPlayer.currentSoundNotifier.togglePause();

        /// Number keys for memory slots
        case "1":
          AlgernonPlayer.painterConfig.currentMemorySlot = 0;
        case "2":
          AlgernonPlayer.painterConfig.currentMemorySlot = 1;
        case "3":
          AlgernonPlayer.painterConfig.currentMemorySlot = 2;
        case "4":
          AlgernonPlayer.painterConfig.currentMemorySlot = 3;
        case "5":
          AlgernonPlayer.painterConfig.currentMemorySlot = 4;
      }
    }
    // don't consume — let focus/text fields still work normally
    return false;
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
          inputDecorationTheme: InputDecorationTheme(
            border: _dropdownBorder,
            enabledBorder: _dropdownBorder,
            focusedBorder: _dropdownBorder,
          ),
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
              return Colors.black.withValues(
                alpha: ALGERNON.fadeDarkBackgroundOpacity,
              );
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
        scrollbarTheme: Theme.of(context).scrollbarTheme.copyWith(
          thickness: WidgetStatePropertyAll<double?>(
            ALGERNON.scrollbarThickness,
          ),
        ),
      ),
      home: Scaffold(
        body: AppStateWidget(
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
    );
  }
}
