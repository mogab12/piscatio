import 'package:piscatio/core/location/location_service.dart';
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
