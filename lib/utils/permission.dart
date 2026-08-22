import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum PermissionType { storage, location, photo, notice, camera, microphone }

Future<bool> checkAndRequestPermission(PermissionType type) async {
  var status = await (await _getPermission(type)).status;
  if (!status.isGranted) {
    if (await (await _getPermission(type)).request().isGranted) {
      return true;
    }
  }
  return status.isGranted;
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
    case .camera:
      return .camera;
    case .microphone:
      return .microphone;
  }
}

Future<Permission> _getStorePermission() async {
  // 非 Android 平台直接使用相册权限（iOS/macOS 等没有 Android 的“存储”权限概念）
  if (!Platform.isAndroid) {
    return .storage;
  }
  final deviceInfo = await DeviceInfoPlugin().androidInfo;
  final sdkInt = deviceInfo.version.sdkInt;
  return sdkInt >= 33 ? .photos : .storage;
}
