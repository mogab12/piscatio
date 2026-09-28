import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'formatters.dart';
import 'l10n.dart';

extension FormattersX on BuildContext {
  /// Formatters for the active language and the user's unit system.
  Formatters formatters(WidgetRef ref) =>
      Formatters(l10n, ref.watch(unitSystemProvider));
}
