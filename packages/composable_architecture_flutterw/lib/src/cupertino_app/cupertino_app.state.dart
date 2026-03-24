part of 'cupertino_app.dart';

/// State for [ComposableCupertinoApp], tracking locale and brightness.
///
/// Use [CupertinoAppState.initial] to initialize from the current platform
/// settings.
class CupertinoAppState {
  /// The current locale.
  final Locale locale;

  /// The current brightness (light/dark mode).
  final Brightness brightness;

  /// Creates a [CupertinoAppState].
  CupertinoAppState({
    required this.locale,
    required this.brightness,
  });

  /// Creates a state initialized from the current platform locale and
  /// brightness.
  factory CupertinoAppState.initial() {
    return CupertinoAppState(
      locale: PlatformDispatcher.instance.locale,
      brightness: PlatformDispatcher.instance.platformBrightness,
    );
  }

  /// Returns a copy with the given fields replaced.
  CupertinoAppState copyWith({
    Locale? locale,
    Brightness? brightness,
  }) {
    return CupertinoAppState(
      locale: locale ?? this.locale,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CupertinoAppState && other.locale == locale && other.brightness == brightness;
  }

  @override
  int get hashCode => Object.hash(locale, brightness);
}
