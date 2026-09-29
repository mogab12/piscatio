import 'dart:io';

import 'package:piscatio/core/location/location_service.dart';
import 'package:piscatio/core/media/photo_source.dart';
import 'package:piscatio/data/account/account_repository.dart';
import 'package:piscatio/data/media/photo_importer.dart';
import 'package:piscatio/data/remote/place_name_service.dart';
import 'package:piscatio/domain/models/geo_point.dart';
import 'package:piscatio/features/cards/application/photo_filter_service.dart';
import 'package:piscatio/features/cards/application/photo_filters.dart';

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

  /// What [recoverLost] returns (a photo from a killed session).
  String? lost;

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    picks.add(origin);
    return path;
  }

  @override
  Future<String?> recoverLost() async {
    final l = lost;
    lost = null;
    return l;
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

  /// Answers every search with these places.
  List<PlaceResult> results = const [];
  final searched = <String>[];

  @override
  Future<List<PlaceResult>> search(
    String query, {
    required String languageCode,
  }) async {
    searched.add(query);
    if (error != null) throw error!;
    return results;
  }

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

/// Filter stand-in: answers at once with [result] (the photo itself when
/// null) and records every request.
class FakePhotoFilterService implements PhotoFilterService {
  final requests = <(String, CardPhotoFilter)>[];
  var cleared = false;

  /// Makes every request fail, like an unreadable photo.
  var fail = false;
  String? result;

  @override
  Future<String?> separation(String photoPath, CardPhotoFilter filter) async {
    requests.add((photoPath, filter));
    if (fail) return null;
    return result ?? photoPath;
  }

  @override
  Future<void> clear() async => cleared = true;
}

/// The secure storage stand-in: keeps the token in memory.
class FakeTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String? value) async => token = value;
}
