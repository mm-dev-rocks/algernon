// SPDX-License-Identifier: GPL-3.0-only

import 'dart:io' show Platform;

import 'package:algernon/keyboard_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app_state.dart';
import 'constants.dart';
import 'pages/root_page.dart';

/// Main app entry point / main class.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize window_manager on desktop
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
  }

  /// App preferences [SharedPreferencesWithCache] require async setup
  await AppState.initPreferences();

  WakelockPlus.enable();

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

    KeyboardHandler.init();

    super.initState();
  }

  @override
  void dispose() {
    KeyboardHandler.dispose();
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
          textStyle: TextStyle(color: ALGERNON.uiStrongForegroundColor),
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
          activeTrackColor: ALGERNON.uiSoftForegroundColor,
          inactiveTrackColor: ALGERNON.uiSoftForegroundColor,
          disabledThumbColor: ALGERNON.uiInactiveForegroundColor,
          disabledActiveTrackColor: ALGERNON.uiInactiveForegroundColor,
          disabledInactiveTrackColor: ALGERNON.uiInactiveForegroundColor,
          thumbColor: ALGERNON.uiStrongForegroundColor,
          overlayColor: ALGERNON.uiSoftForegroundColor,
          valueIndicatorColor: ALGERNON.uiStrongBackgroundColor,
          valueIndicatorTextStyle: TextStyle(
            color: ALGERNON.uiStrongForegroundColor,
          ),
          trackHeight: 1.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
          valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
          showValueIndicator: ShowValueIndicator.alwaysVisible,
        ),
        checkboxTheme: Theme.of(context).checkboxTheme.copyWith(
          side: BorderSide(color: ALGERNON.uiDefaultForegroundColor),
          checkColor: WidgetStateProperty<Color?>.fromMap(
            <WidgetStatesConstraint, Color?>{
              WidgetState.hovered & WidgetState.focused:
                  ALGERNON.uiStrongForegroundColor,
              WidgetState.focused: ALGERNON.uiStrongForegroundColor,
              ~WidgetState.disabled: ALGERNON.uiDefaultForegroundColor,
            },
          ),
          fillColor: WidgetStateProperty<Color?>.fromMap(
            <WidgetStatesConstraint, Color?>{
              WidgetState.hovered & WidgetState.focused:
                  ALGERNON.uiInactiveForegroundColor,
              WidgetState.focused: ALGERNON.uiInactiveForegroundColor,
              ~WidgetState.disabled: Colors.transparent,
            },
          ),
          overlayColor: WidgetStatePropertyAll<Color?>(Colors.transparent),
        ),
        scrollbarTheme: Theme.of(context).scrollbarTheme.copyWith(
          thickness: WidgetStatePropertyAll<double?>(
            ALGERNON.scrollbarThickness,
          ),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(color: ALGERNON.uiStrongBackgroundColor),
          textStyle: TextStyle(color: ALGERNON.uiStrongForegroundColor),
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
