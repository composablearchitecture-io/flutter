part of 'cupertino_app.dart';

/// The default reducer for [CupertinoAppState] that handles
/// [CupertinoAppAction.setLocale] and [CupertinoAppAction.setBrightness].
final Reducer<CupertinoAppState, CupertinoAppAction, EmptyEnvironment> materialAppReducer = Reducer.transform(
  (state, action, env) => switch (action) {
    CupertinoAppActionSetLocale(:final locale) => state.copyWith(locale: locale),
    CupertinoAppActionSetBrightness(:final brightness) => state.copyWith(brightness: brightness)
  },
);
