import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Locale name for intl formatters (e.g. `pt`, `es`).
  String get localeName => AppLocalizations.of(this).localeName;
}
