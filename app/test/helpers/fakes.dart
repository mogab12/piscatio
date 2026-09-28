import 'dart:io';

import 'package:piscatio/core/location/location_service.dart';
import 'package:piscatio/core/media/photo_source.dart';
import 'package:piscatio/data/media/photo_importer.dart';
import 'package:piscatio/data/remote/place_name_service.dart';
import 'package:piscatio/domain/models/geo_point.dart';

class FakeLocationService implements LocationService {
  FakeLocationService({this.accessResult = LocationAccess.granted, this.fix});

  LocationAccess accessResult;
  LocationFix? fix;
  var requests = 0;

  @override
  Future<LocationAccess> access() async => accessResult;

  @override
  Future<LocationAccess> requestAccess() async {
    requests++;
    return accessResult;
  }

  @override
  Future<LocationFix?> currentFix({Duration? timeout}) async => fix;
}

const pantanal = LocationFix(GeoPoint(-16.52, -56.41), 12);

/// Returns a fixed file for camera and gallery (null = user cancelled).
class FakePhotoSource implements PhotoSource {
  FakePhotoSource([this.path = 'test/fixtures/exif_gps.jpg']);

  String? path;
  final picks = <PhotoOrigin>[];

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    picks.add(origin);
    return path;
  }
}

/// Stands in for the native re-encoder (a platform plugin): passes bytes
/// through so the Dart metadata stripper still runs.
class PassThroughImageProcessor implements ImageProcessor {
  @override
  Future<ProcessedImage?> process(String sourcePath) async =>
      ProcessedImage(File(sourcePath).readAsBytesSync(), 64, 48);
}

/// Geocoder stand-in: answers [region] and records what it was asked.
class FakePlaceNameService implements PlaceNameService {
  FakePlaceNameService({this.region = 'Cuiabá, MT'});

  String? region;
  Exception? error;
  final asked = <GeoPoint>[];

  @override
  Future<String?> regionFor(
    GeoPoint point, {
    required String languageCode,
  }) async {
    asked.add(point);
    if (error != null) throw error!;
    return region;
  }
}
