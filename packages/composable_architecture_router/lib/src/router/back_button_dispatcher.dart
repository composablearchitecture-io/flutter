import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:composable_architecture_flutterw/composable_architecture_flutterw.dart';
import 'package:composable_architecture_router/src/action.dart';
import 'package:composable_architecture_router/src/state.dart';

class ComposableBackButtonDispatcher<AppState, AppAction>
    extends RootBackButtonDispatcher {
  final Store<RouterState<AppState, AppAction>,
      RouterAction<AppState, AppAction>> store;
  ComposableBackButtonDispatcher(this.store) : super() {
    addCallback(
      () {
        debugPrint("[NAV] Back button pressed");
        if (store.state.count > 1) {
          // TODO: handle pop
          return SynchronousFuture<bool>(true);
        }
        return SynchronousFuture<bool>(false);
      },
    );
  }
}
