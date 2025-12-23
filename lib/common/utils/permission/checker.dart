import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum PermissionType { storage, location, photo, notice }

Future<bool> checkAndRequestPermissions(PermissionType type) async {
  var status = await (await _getPermission(type)).status;
  if (!status.isGranted) {
    if (await (await _getPermission(type)).request().isGranted) {
      return true;
    }
  }
  return false;
}

Future<Permission> _getPermission(PermissionType type) async {
  switch (type) {
    case .storage:
      return await _getStorePermission();
    case .photo:
      return .photos;
    case .location:
      return .location;
    case .notice:
      return .notification;
  }
}

Future<Permission> _getStorePermission() async {
  final deviceInfo = await DeviceInfoPlugin().androidInfo;
  final sdkInt = deviceInfo.version.sdkInt;
  if (Platform.isAndroid) {
    return sdkInt >= 33 ? .photos : .storage;
  } else {
    return .storage;
  }
}
