part of 'material_app.dart';

/// The default reducer for [MaterialAppState] that handles
/// [MaterialAppAction.setLocale] and [MaterialAppAction.setBrightness].
final Reducer<MaterialAppState, MaterialAppAction, EmptyEnvironment> materialAppReducer = Reducer.transform(
  (state, action, env) => switch (action) {
    MaterialAppActionSetLocale(:final locale) => state.copyWith(locale: locale),
    MaterialAppActionSetBrightness(:final brightness) => state.copyWith(brightness: brightness)
  },
);
