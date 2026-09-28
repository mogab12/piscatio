import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/core/media/photo_source.dart';
import 'package:piscatio/core/providers.dart';
import 'package:piscatio/data/media/photo_importer.dart';
import 'package:piscatio/domain/models/enums.dart';
import 'package:piscatio/features/quick_catch/presentation/quick_catch_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

Future<TestApp> _start(WidgetTester tester, FakePhotoSource photos) =>
    TestApp.start(
      tester,
      overrides: [
        photoSourceProvider.overrideWithValue(photos),
        imageProcessorProvider.overrideWithValue(PassThroughImageProcessor()),
      ],
    );

void main() {
  testWidgets('a photo lost to the camera resumes the catch', (tester) async {
    final photos = FakePhotoSource()..lost = 'test/fixtures/exif_gps.jpg';
    final app = await _start(tester, photos);
    await app.run(tester, () async {
      await app.read(settingsRepositoryProvider).completeOnboarding();
      await app
          .read(tripRepositoryProvider)
          .startTrip(timezone: 'UTC', privacy: PrivacyLevel.private);
    });
    await app.pumpApp(tester);
    final screen = tester.widget<QuickCatchScreen>(
      find.byType(QuickCatchScreen),
    );
    expect(screen.photoPath, 'test/fixtures/exif_gps.jpg');
    // No camera or gallery was opened again.
    expect(photos.picks, isEmpty);
    await app.dispose(tester);
  });

  testWidgets('without a running trip the lost photo is ignored', (
    tester,
  ) async {
    final photos = FakePhotoSource()..lost = 'test/fixtures/exif_gps.jpg';
    final app = await _start(tester, photos);
    await app.run(
      tester,
      () => app.read(settingsRepositoryProvider).completeOnboarding(),
    );
    await app.pumpApp(tester);
    expect(find.byType(QuickCatchScreen), findsNothing);
    await app.dispose(tester);
  });
}
