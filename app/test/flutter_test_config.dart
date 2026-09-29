import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// A tap that lands off screen or under another widget fails the test
/// instead of printing a warning and silently doing nothing.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
