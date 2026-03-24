part of 'material_app.dart';

/// Actions for updating [MaterialAppState].
sealed class MaterialAppAction {
  const MaterialAppAction();

  /// Sets the app locale.
  const factory MaterialAppAction.setLocale(Locale locale) = MaterialAppActionSetLocale;

  /// Sets the app brightness (light/dark mode).
  const factory MaterialAppAction.setBrightness(Brightness brightness) = MaterialAppActionSetBrightness;
}

/// Sets the locale. See [MaterialAppAction.setLocale].
class MaterialAppActionSetLocale implements MaterialAppAction {
  /// The new locale.
  final Locale locale;

  /// Creates a set locale action.
  const MaterialAppActionSetLocale(this.locale);
}

/// Sets the brightness. See [MaterialAppAction.setBrightness].
class MaterialAppActionSetBrightness implements MaterialAppAction {
  /// The new brightness.
  final Brightness brightness;

  /// Creates a set brightness action.
  const MaterialAppActionSetBrightness(this.brightness);
}
