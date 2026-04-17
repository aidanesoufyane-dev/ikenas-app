import 'package:flutter/material.dart';
import 'app_localizations.dart';

extension AppTranslation on String {
  /// Translates a static key from JSON files.
  /// If the key is not found, it returns the key itself.
  String tr(BuildContext context) {
    return AppLocalizations.of(context)?.translate(this) ?? this;
  }
}

extension AppTranslationContext on BuildContext {
  /// Translates a static key from JSON files.
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }

  /// Checks if the current locale is Arabic (RTL).
  bool get isAr => Localizations.localeOf(this).languageCode == 'ar';
}
