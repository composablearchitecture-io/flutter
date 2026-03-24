part of 'cupertino_app.dart';

/// Actions for updating [CupertinoAppState].
sealed class CupertinoAppAction {
  const CupertinoAppAction();

  /// Sets the app locale.
  const factory CupertinoAppAction.setLocale(Locale locale) = CupertinoAppActionSetLocale;

  /// Sets the app brightness (light/dark mode).
  const factory CupertinoAppAction.setBrightness(Brightness brightness) = CupertinoAppActionSetBrightness;
}

/// Sets the locale. See [CupertinoAppAction.setLocale].
final class CupertinoAppActionSetLocale extends CupertinoAppAction {
  /// The new locale.
  final Locale locale;

  /// Creates a set locale action.
  const CupertinoAppActionSetLocale(this.locale);
}

/// Sets the brightness. See [CupertinoAppAction.setBrightness].
final class CupertinoAppActionSetBrightness extends CupertinoAppAction {
  /// The new brightness.
  final Brightness brightness;

  /// Creates a set brightness action.
  const CupertinoAppActionSetBrightness(this.brightness);
}
