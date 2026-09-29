import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piscatio/domain/services/ruler_scale.dart';
import 'package:piscatio/features/cards/application/card_data.dart';
import 'package:piscatio/features/cards/presentation/card_view.dart';
import 'package:piscatio/l10n/generated/app_localizations.dart';

import '../helpers/pump_app.dart';
import '../helpers/screenshots.dart';

final _photo = File('test/fixtures/card_photo.jpg').absolute.path;

CatchCardData sampleCatch({String? photo, bool record = true}) => CatchCardData(
  id: '0192f7a0-7a1b-7c3d-8e4f-5a6b7c8d9e0f',
  speciesName: 'Dourado',
  scientificName: 'Salminus brasiliensis',
  dateLabel: '12 de set. de 2026',
  timeLabel: '06:40',
  romanDate: '12.IX.2026',
  catchNumber: 42,
  place: 'Cuiabá, MT',
  lengthLabel: '72 cm',
  weightLabel: '4,2 kg',
  baitLabel: 'Tuvira',
  released: true,
  photoPath: photo,
  ruler: const RulerScale(
    unit: RulerUnit.centimeter,
    max: 80,
    major: 10,
    minor: 1,
    value: 72,
    previous: 63,
  ),
  rulerUnit: 'cm',
  headline: const [CardQuantity('72', 'cm')],
  record: record ? const CardRecord.record(improvement: '+14%') : null,
  previousRecordLabel: record ? '63 cm' : null,
  moon: const CardMoon(
    illumination: 0.68,
    waxing: true,
    label: 'Crescente gibosa',
    southern: true,
  ),
  wind: const CardWind(fromDegrees: 135, label: '9 km/h SE'),
  temperatureLabel: '24 °C',
  pressureLabel: '1012 hPa',
);

TripCardData sampleTrip({String? photo}) => TripCardData(
  id: '0192f7a0-0000-7c3d-8e4f-5a6b7c8d9e0f',
  dateLabel: '12 de set. de 2026',
  romanDate: '12.IX.2026',
  place: 'Cuiabá, MT',
  durationLabel: '4 h 12 min',
  timeRangeLabel: 'Das 05:40 às 09:52',
  catchCount: 8,
  speciesCount: 4,
  catches: const [
    TripCardCatch(
      speciesName: 'Traíra',
      timeLabel: '05:52',
      offset: 0.04,
      measureLabel: '41 cm',
    ),
    TripCardCatch(
      speciesName: 'Piraputanga',
      timeLabel: '06:10',
      offset: 0.1,
      measureLabel: '30 cm',
    ),
    TripCardCatch(
      speciesName: 'Dourado',
      timeLabel: '06:40',
      offset: 0.2,
      measureLabel: '4,2 kg',
      isRecord: true,
    ),
    TripCardCatch(speciesName: 'Traíra', timeLabel: '07:05', offset: 0.28),
    TripCardCatch(
      speciesName: 'Pacu',
      timeLabel: '07:48',
      offset: 0.42,
      measureLabel: '2,1 kg',
    ),
    TripCardCatch(
      speciesName: 'Traíra',
      timeLabel: '08:30',
      offset: 0.56,
      measureLabel: '38 cm',
    ),
    TripCardCatch(
      speciesName: 'Piraputanga',
      timeLabel: '09:02',
      offset: 0.66,
      measureLabel: '33 cm',
      isRecord: true,
    ),
    TripCardCatch(
      speciesName: 'Traíra',
      timeLabel: '09:40',
      offset: 0.8,
      measureLabel: '44 cm',
    ),
  ],
  speciesTally: const [
    ('Traíra', 4),
    ('Piraputanga', 2),
    ('Dourado', 1),
    ('Pacu', 1),
  ],
  spanHours: 5,
  elapsedFraction: 0.84,
  biggestLabel: 'Dourado, 4,2 kg',
  topBaitLabel: 'Tuvira',
  photoPath: photo,
  recordCount: 2,
  moon: const CardMoon(
    illumination: 0.68,
    waxing: true,
    label: 'Crescente gibosa',
    southern: true,
  ),
  wind: const CardWind(fromDegrees: 135, label: '9 km/h SE'),
  temperatureLabel: '24 °C',
  pressureLabel: '1012 hPa',
);

Future<void> shoot(
  WidgetTester tester,
  String name,
  Widget card,
  CardFormat format, {
  String? photo,
}) async {
  tester.view.physicalSize = format.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget app(Widget home) => RepaintBoundary(
    key: screenKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Align(alignment: Alignment.topLeft, child: home),
    ),
  );
  if (photo != null) {
    // Decode on the real event loop *before* any widget asks for the
    // image: a load started in the fake zone would never finish.
    await tester.pumpWidget(app(const SizedBox()));
    final context = tester.element(find.byType(SizedBox).last);
    await tester.runAsync(() => precacheImage(FileImage(File(photo)), context));
  }
  await tester.pumpWidget(app(card));
  await tester.pumpAndSettle();
  await saveScreenshot(tester, name);
}

void main() {
  setUpAll(loadRealFonts);

  for (final style in CardStyle.values) {
    for (final format in CardFormat.values) {
      final f = format.name;
      testWidgets('catch ${style.name} $f', (tester) async {
        await shoot(
          tester,
          'card_catch_${style.name}_${f}_photo',
          CatchCardView(
            data: sampleCatch(photo: _photo),
            style: style,
            format: format,
          ),
          format,
          photo: _photo,
        );
        await shoot(
          tester,
          'card_catch_${style.name}_${f}_plain',
          CatchCardView(
            data: sampleCatch(record: false),
            style: style,
            format: format,
          ),
          format,
        );
      }, skip: !screenshotsEnabled);

      testWidgets('trip ${style.name} $f', (tester) async {
        await shoot(
          tester,
          'card_trip_${style.name}_${f}_photo',
          TripCardView(
            data: sampleTrip(photo: _photo),
            style: style,
            format: format,
          ),
          format,
          photo: _photo,
        );
        await shoot(
          tester,
          'card_trip_${style.name}_${f}_plain',
          TripCardView(data: sampleTrip(), style: style, format: format),
          format,
        );
      }, skip: !screenshotsEnabled);
    }
  }

  // The editor's options: theme, caption, weather hidden, no photo.
  for (final (style, palette) in [
    (CardStyle.board, CardPalette.dawn),
    (CardStyle.chart, CardPalette.tucunare),
    (CardStyle.tag, CardPalette.moon),
  ]) {
    testWidgets('custom ${style.name}', (tester) async {
      await shoot(
        tester,
        'card_custom_${style.name}_story',
        CatchCardView(
          data: sampleCatch(photo: _photo),
          style: style,
          format: CardFormat.story,
          options: CardOptions(
            palette: palette,
            caption: 'Primeiro dourado da temporada, no raso da prainha',
          ),
        ),
        CardFormat.story,
        photo: _photo,
      );
      await shoot(
        tester,
        'card_custom_${style.name}_trip_square',
        TripCardView(
          data: sampleTrip(photo: _photo),
          style: style,
          format: CardFormat.square,
          options: CardOptions(
            palette: palette,
            showWeather: false,
            caption: 'Manhã de piracema',
          ).withPhoto(null),
        ),
        CardFormat.square,
      );
    }, skip: !screenshotsEnabled);
  }

  // Every theme on every style, to review them side by side.
  for (final palette in CardPalette.values) {
    testWidgets('theme ${palette.name}', (tester) async {
      for (final style in CardStyle.values) {
        await shoot(
          tester,
          'theme_${palette.name}_${style.name}',
          CatchCardView(
            data: sampleCatch(photo: _photo),
            style: style,
            format: CardFormat.story,
            options: CardOptions(palette: palette),
          ),
          CardFormat.story,
          photo: _photo,
        );
      }
    }, skip: !screenshotsEnabled);
  }
}
