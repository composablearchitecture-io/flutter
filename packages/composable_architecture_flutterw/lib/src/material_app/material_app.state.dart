part of 'material_app.dart';

/// State for [ComposableMaterialApp], tracking locale and brightness.
///
/// Use [MaterialAppState.initial] to initialize from the current platform
/// settings.
class MaterialAppState {
  /// The current locale.
  final Locale locale;

  /// The current brightness (light/dark mode).
  final Brightness brightness;

  /// Creates a [MaterialAppState].
  const MaterialAppState({
    required this.locale,
    required this.brightness,
  });

  /// Returns a copy with the given fields replaced.
  MaterialAppState copyWith({
    Locale? locale,
    Brightness? brightness,
  }) {
    return MaterialAppState(
      locale: locale ?? this.locale,
      brightness: brightness ?? this.brightness,
    );
  }

  /// Creates a state initialized from the current platform locale and
  /// brightness.
  factory MaterialAppState.initial() => MaterialAppState(
        locale: PlatformDispatcher.instance.locale,
        brightness: PlatformDispatcher.instance.platformBrightness,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialAppState && other.locale == locale && other.brightness == brightness;
  }

  @override
  int get hashCode => Object.hash(locale, brightness);
}
