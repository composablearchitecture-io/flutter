Map<String, String>? tryBinding(RegExp regex, String path) {
  final pathWithoutQueryParams = path.split('?').first;
  // Try to match the path against the regex
  final match = regex.firstMatch(pathWithoutQueryParams);
  if (match == null) return null;
  // Extract named groups as path parameters
  final groupNames = match.groupNames;
  final pathParameters = <String, String>{};
  for (final name in groupNames) {
    final value = match.namedGroup(name);
    if (value != null) {
      pathParameters[name] = value;
    }
  }
  return pathParameters;
}

extension PathTemplateStringExt on String {
  // Supposing you have a path template like this:
  // "/:pageId(a|b|c)/section/:sectionId/category/:categoryId/exercise"
  // Create a RegExp that can extract the path parameters
  RegExp get pathTemplateRegex {
    final pattern = replaceAllMapped(
      RegExp(r':(\w+)(\([^\)]+\))?'),
      (match) {
        final paramName = match.group(1);
        final customPattern = match.group(2);
        if (customPattern != null) {
          return '(?<$paramName>${customPattern.substring(1, customPattern.length - 1)})';
        } else {
          return '(?<$paramName>[^/]+)';
        }
      },
    );
    return RegExp('^$pattern\$');
  }
}
