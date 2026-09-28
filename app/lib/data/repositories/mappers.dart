import '../../domain/models/catch.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/species.dart';
import '../../domain/models/tackle.dart';
import '../../domain/models/trip.dart';
import '../db/app_database.dart';

GeoPoint? _point(double? lat, double? lon) =>
    lat == null || lon == null ? null : GeoPoint(lat, lon);

extension TripRowMapper on TripRow {
  Trip toModel() => Trip(
    id: id,
    startedAt: startedAt.toUtc(),
    endedAt: endedAt?.toUtc(),
    timezone: timezone,
    location: _point(latitude, longitude),
    locationAccuracyMeters: locationAccuracyM,
    locationName: locationName,
    locationRegion: locationRegion,
    privacyLevel: privacyLevel,
    moonPhase: moonPhase,
    moonIllumination: moonIllumination,
    notes: notes,
    isRetroactive: isRetroactive,
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
  );
}

extension CatchRowMapper on CatchRow {
  Catch toModel({List<CatchPhoto> photos = const []}) => Catch(
    id: id,
    tripId: tripId,
    speciesId: speciesId,
    caughtAt: caughtAt.toUtc(),
    weightGrams: weightG,
    lengthMillimeters: lengthMm,
    released: released,
    baitId: baitId,
    gearId: gearId,
    depthMillimeters: depthMm,
    location: _point(latitude, longitude),
    notes: notes,
    photos: photos,
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
  );
}

extension CatchPhotoRowMapper on CatchPhotoRow {
  CatchPhoto toModel() => CatchPhoto(
    id: id,
    catchId: catchId,
    relativePath: relativePath,
    width: width,
    height: height,
    takenAt: takenAt?.toUtc(),
  );
}

extension SpeciesRowMapper on SpeciesRow {
  Species toModel(List<SpeciesNameRow> nameRows) => Species(
    id: id,
    scientificName: scientificName,
    habitats: habitats,
    regionTags: regionTags,
    isCustom: isCustom,
    names: [
      for (final n in nameRows)
        SpeciesName(
          lang: n.lang,
          name: n.name,
          isPrimary: n.isPrimary,
          region: n.region,
          needsReview: n.needsReview,
        ),
    ],
  );
}

extension BaitRowMapper on BaitRow {
  Bait toModel() =>
      Bait(id: id, name: name, type: type, notes: notes, archived: archived);
}

extension GearRowMapper on GearRow {
  Gear toModel() =>
      Gear(id: id, name: name, type: type, notes: notes, archived: archived);
}
