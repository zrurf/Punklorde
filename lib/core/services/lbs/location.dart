import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:punklorde/common/models/location.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/core/status/location.dart';
import 'package:signals/signals.dart';

final LocationFlutterPlugin _locationClient = LocationFlutterPlugin();

class LocationServiceOptions {
  final CoordinateType coorType;
  final LocationPurpose? purpose;
  final int interval;
  final double distanceFilter;
  final bool? isNeedAltitude;
  final bool? isNeedAddress;
  LocationServiceOptions({
    this.coorType = CoordinateType.GCJ02,
    this.purpose,
    this.interval = 1000,
    this.distanceFilter = 1.0,
    this.isNeedAltitude,
    this.isNeedAddress,
  });
}

void initLocationService() {
  _locationClient.setAgreePrivacy(true);
}

Future<bool> startLocationService(LocationServiceOptions options) async {
  await _locationClient.prepareLoc(
    _getAndroidOptionsMap(options),
    _getIosOptionsMap(options),
  );
  _locationClient.seriesLocationCallback(
    callback: (BaiduLocation location) {
      batch(() {
        if (location.latitude != null) rawLat.value = location.latitude!;
        if (location.longitude != null) rawLng.value = location.longitude!;
        if (location.altitude != null) rawAlt.value = location.altitude!;
        if (location.speed != null) rawSpeed.value = location.speed!;
        if (location.course != null) rawCourse.value = location.course!;
        rawAddress.value = location.address;
      });
    },
  );
  rawRunning.value = await _locationClient.startLocation();
  return rawRunning.value;
}

Future<bool> stopLocationService() async {
  rawRunning.value = !(await _locationClient.stopLocation());
  return rawRunning.value;
}

Future<bool> startHeadingService() async {
  _locationClient.updateHeadingCallback(
    callback: (BaiduHeading result) {
      if (result.trueHeading != null) rawHeading.value = result.trueHeading!;
    },
  );
  rawHeadingRunning.value = await _locationClient.startUpdatingHeading();
  return rawHeadingRunning.value;
}

Future<bool> stopHeadingService() async {
  rawHeadingRunning.value = !(await _locationClient.stopUpdatingHeading());
  return rawHeadingRunning.value;
}

Map _getAndroidOptionsMap(LocationServiceOptions options) {
  return BaiduLocationAndroidOption(
    coordType: options.coorType.toBDMapCoordinateType(),
    locationPurpose: options.purpose?.toBDMapLocationPurpose(),
    openGps: true,
    isNeedAddress: options.isNeedAddress ?? true,
    isNeedAltitude: options.isNeedAltitude ?? true,
    isNeedNewVersionRgc: false,
    locationMode: .hightAccuracy,
    scanspan: options.interval,
  ).getMap();
}

Map _getIosOptionsMap(LocationServiceOptions options) {
  return BaiduLocationIOSOption(
    coordType: options.coorType.toBDMapCoordinateType(),
    locationTimeout: options.interval,
    isNeedNewVersionRgc: true,
    distanceFilter: options.distanceFilter,
  ).getMap();
}
