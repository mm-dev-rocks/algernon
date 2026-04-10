// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter/material.dart';

import '../algernon_player.dart';

/// First route/page for the app.
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    //
    // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    // COULD BE USEFUL FOR ROUTE MANAGEMENT, KEEP FOR A WHILE
    // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    //
    //return ListenableBuilder(
    //    listenable: WebDavConnectionManager.statusNotifier,
    //    builder: (BuildContext context, Widget? child) {
    //      AppState.log('RootPage::ListenableBuilder: WebDavConnectionManager.statusNotifier.value: ${WebDavConnectionManager.statusNotifier.value}');
    //      AppState.log('RootPage::ListenableBuilder: AppState.currentRoute: ${AppState.currentRoute}');
    //      WebDavConnectionStatus status = WebDavConnectionManager.statusNotifier.value;

    //      Widget contents = (status == WebDavConnectionStatus.error ||
    //              status == WebDavConnectionStatus.verifiedWithBadAudiobookDirectory ||
    //              status == WebDavConnectionStatus.firstTimeSetup)
    //          ? AlgernonTextButton(
    //              'Enter WebDAV server settings',
    //              () {
    //                AppState.navigateMainToNamedRoute(ALGERNON.routePreferences);
    //              },
    //            )
    //          : Text("...");
    //
    //      AppState.forwardToBookListIfConnected();

    //      //if (status == WebDavConnectionStatus.verified &&
    //      //    AppState.currentRoute == ALGERNON.routeRoot) {
    //      //  /// We need to redirect, but can't do it inline here as the [build] method must return a
    //      //  /// [Widget]. A [Future.microtask] will execute immediately after [build], so gets us the
    //      //  /// desired effect.
    //      //  Future.microtask(() {
    //      //    AppState.navigateMainToNamedRoute(ALGERNON.routeBookList);
    //      //  });
    //      //}
    //
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // COULD BE USEFUL FOR ROUTE MANAGEMENT, KEEP FOR A WHILE
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    //

    return const AlgernonPlayer();
  }
}
