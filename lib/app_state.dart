// SPDX-License-Identifier: GPL-3.0-only

import 'dart:async';

import 'package:algernon/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:observable/observable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// To enable shared state in the app, add this widget to the tree. All widgets which want to access shared state should
/// be children of this widget. Make this widget high enough in the tree that it wraps all of the children which need
/// it, but no higher (for efficiency).
class AppStateWidget extends StatelessWidget {
  const AppStateWidget({super.key, required this.child});

  final Widget child;

  /// This is the main container in which we'll store all of our state. As an [ObservableMap] it's a map which we can
  /// watch and be informed when its properties change. This observation is shallow so eg a [Map] property will only be
  /// recognised if it is completely reassigned, not if its own internal values change.
  static final ObservableMap _appState = ObservableMap();

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Contain and manage shared app state.
///
/// Any widget that wants to access app state should extend this class in its [createState], eg:
/// ``` dart
/// class _TabManagerWidgetState extends AppState<TabManagerWidget>
/// ```
/// When a change is made to any element in [listenForChanges], the widget will be rebuilt.
abstract class AppState<T extends StatefulWidget> extends State<T> {
  StreamSubscription? _appStateChangeSubscription;

  /// List of [_appState] keys on which extending classes will listen for changes. When the value related to a listened
  /// key changes, this widget will rebuild, eg:
  ///
  /// ``` dart
  /// listenForChanges = ['mainData', 'userNames'];
  /// ```
  /// The above code means this (inheriting) widget will be rebuilt when [_appState['mainData'] or
  /// [_appState['userNames']] is changed.
  List<String>? get listenForChanges;
  set listenForChanges(List<String>? value);

  String changedOn = '';

  @override
  void initState() {
    /// Listen for changes in [_appState] and rebuild any interested widgets (those which are listening for the specific
    /// key which changed).
    _appStateChangeSubscription = AppStateWidget._appState.changes.listen((
      List event,
    ) {
      for (ChangeRecord change in event) {
        if (change is MapChangeRecord) {
          if (listenForChanges != null &&
              listenForChanges!.contains(change.key)) {
            /// if the key was removed, that indicates this is just the first step in a forced rebuild, so ignore this
            /// change - another change of the same key will follow immediately and we don't want to rebuild twice.
            if (!change.isRemove) {
              //String widgetDescription =
              //    widget.key?.toString() ?? '${widget.toStringShort()}::${widget.hashCode}';
              //print('$widgetDescription HEARD: \'${change.key}\'');

              setState(() {
                //changedOn = change.key.toString();
              });
            }
          }
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _appStateChangeSubscription?.cancel();
  }

  /// Update a part (based on [key]) of the shared state of the app. The app will only notice the change if [newValue]
  /// is a different object to the previous object saved under the same [key]. If the object has only mutated internally
  /// and you want the app to notice you must call [forceRebuildOn()] with the same [key].
  static void update(String key, dynamic newValue) {
    AppStateWidget._appState[key] = newValue;
  }

  /// Get a part (based on [key]) of the shared state of the app.
  static dynamic get(String key) {
    return AppStateWidget._appState[key];
  }

  /// Sometimes we want to trigger a rebuild for certain widgets without any specific variable changing. These 'states'
  /// just hold nulls as we only need the key, not the value.
  ///
  /// Or maybe an object has only mutated its properties (so in a shallow sense object still == object) but we want the
  /// app to adapt to the latest state of the object.
  ///
  /// Or sometimes we want to bundle lots of changes into one concept, eg when any of preferences for [useCoverImages],
  /// [decorationLevelIndex], [themeBrightnessModeIndex] have changed, it's nicer for widgets to just be able to listen
  /// for a single [themeChange].
  static void forceRebuildOn(String key) {
    /// Removing the object completely then re-adding it forces the change to be recognised.
    dynamic object = AppState.get(key);
    AppStateWidget._appState.remove(key);
    AppState.update(key, object);
  }

  /// [SharedPreferencesWithCache] must be use the [SharedPreferencesWithCache.create] constructor,
  /// which is async.
  /// https://pub.dev/packages/shared_preferences
  static Future<void> initPreferences() async {
    AppState.update(
      'preferences',
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      ),
    );
  }

  static Future<void> setPreference(String key, dynamic value) async {
    SharedPreferencesWithCache? sharedPreferences = AppState.get('preferences');

    if (sharedPreferences == null) {
      AppState.log('[SharedPreferencesWithCache] has not yet been initialised');
    } else if (!ALGERNON.defaultPreferences.containsKey(key)) {
      AppState.log(
        "Preference '$key' does not exist in app (not found in 'ALGERNON.defaultPreferences')",
      );
    } else {
      var [defaultType, defaultValue] = ALGERNON.defaultPreferences[key];
      if (value.runtimeType != defaultType) {
        AppState.log(
          "Trying to set preference to incorrect type. '$key' should be '$defaultType', not '${value.runtimeType}'",
        );
      } else {
        switch (defaultType) {
          case const (bool):
            await sharedPreferences.setBool(key, value);
          case const (String):
            await sharedPreferences.setString(key, value);
          case const (double):
            await sharedPreferences.setDouble(key, value);
          case const (int):
            await sharedPreferences.setInt(key, value);
        }
      }
    }
    //AppState.log("SET $key: ${value.toString()}");

    AppState.update('preferences', sharedPreferences);
  }

  static dynamic getPreference(String key) {
    SharedPreferencesWithCache? sharedPreferences = AppState.get('preferences');
    dynamic userPreference;

    if (sharedPreferences == null) {
      AppState.log(
        'SharedPreferencesWithCache has not yet been initialised: $key',
      );
      if (ALGERNON.defaultPreferences.containsKey(key)) {
        var [defaultType, defaultValue] = ALGERNON.defaultPreferences[key];
        userPreference = defaultValue;
        AppState.log('- returning default ($defaultValue)');
      }
    } else if (ALGERNON.defaultPreferences.containsKey(key)) {
      var [defaultType, defaultValue] = ALGERNON.defaultPreferences[key];
      switch (defaultType) {
        case const (bool):
          userPreference = sharedPreferences.getBool(key) ?? defaultValue;
        case const (String):
          userPreference = sharedPreferences.getString(key) ?? defaultValue;
        case const (double):
          userPreference = sharedPreferences.getDouble(key) ?? defaultValue;
        case const (int):
          userPreference = sharedPreferences.getInt(key) ?? defaultValue;
      }
    } else {
      AppState.log(
        "Shared preference '$key' does not exist in app (not found in 'ALGERNON.defaultPreferences')",
      );
    }
    //AppState.log("GET $key: ${userPreference.toString()}");

    return userPreference;
  }

  //static Future<void> setShaderTweakValue(String key, dynamic value) async {
  //  Map<String, dynamic> currentMap = AppState.getPreference(
  //    "shaderTweakValuesMap",
  //  );
  //  currentMap[key] = value;
  //  AppState.setPreference("shaderTweakValuesMap", currentMap);
  //}

  //static dynamic getShaderTweakValue(String key) {
  //  return AppState.getPreference("shaderTweakValuesMap")[key];
  //}

  /// Get the current route/page we are on
  static String get currentRoute {
    String currentAppRoute = '';

    AppState.get("mainNavigatorKey").currentState!.popUntil((currentRoute) {
      currentAppRoute = currentRoute.settings.name.toString();
      // Return true so popUntil() pops nothing.
      return true;
    });

    return currentAppRoute;
  }

  /// Simple wrapper to be used for most navigation in the app, centralised for consistency.
  static Future<void> navigateMainToNamedRoute(String routeName) async {
    await AppState.get("mainNavigatorKey").currentState!.pushNamed(routeName);
  }

  /// Get the current route/page we are on
  static BuildContext get globalContext {
    return AppState.get("mainNavigatorKey").currentContext;
  }

  /// Output debugging info.
  static void log(str, {tempDisableOverride = true}) {
    if (tempDisableOverride) {
      if (kDebugMode) {
        debugPrint(str);
      }
      List<String> messages = AppState.get('debugMessage') ?? [];

      messages.add(str.toString());
      AppState.update('debugMessage', messages);
      AppState.forceRebuildOn('debugMessage');
    }
  }

  // THIS IS THE SINGLE POINT OF TRUTH FOR BACK NAVIGATION.
  static Future<bool> handleNavigateBack() async {
    final didPop = await AppState.get(
      "mainNavigatorKey",
    ).currentState!.maybePop();
    //AppState.forwardToBookListIfConnected();

    return didPop;
  }

  static void quitWithError(str) {
    //log(DebugStrings.catastrophicError(str));
    log(str);
    SystemNavigator.pop();
  }
}
