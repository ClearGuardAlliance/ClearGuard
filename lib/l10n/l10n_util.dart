import 'dart:ui';

import 'package:clearguard/l10n/generated/app_localizations.dart';

Future<AppLocalizations> loadCurrentLocalizations() {
  final locale = PlatformDispatcher.instance.locale;
  final resolved = AppLocalizations.supportedLocales.contains(locale)
      ? locale
      : AppLocalizations.supportedLocales.firstWhere(
          (supported) => supported.languageCode == locale.languageCode,
          orElse: () => const Locale('en'),
        );
  return AppLocalizations.delegate.load(resolved);
}
