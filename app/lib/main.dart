import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'core/bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Archivo',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Courier Prime',
    ], await rootBundle.loadString('assets/fonts/OFL-CourierPrime.txt'));
    yield LicenseEntryWithLineBreaks([
      'Shrikhand',
    ], await rootBundle.loadString('assets/fonts/OFL-Shrikhand.txt'));
  });
  installReadableErrorWidget();
  // Nothing is awaited before the first frame: the database opens behind
  // the boot screen, which reports a slow step or an error on screen.
  runApp(const BootstrapApp());
}
