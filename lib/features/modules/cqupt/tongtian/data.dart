import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:punklorde/common/const/urls.dart';
import 'package:punklorde/features/modules/cqupt/tongtian/model.dart';
import 'package:signals/signals.dart';

final Dio _dio = Dio();

final Signal<Map<String, MapItem>> globalMpIndex = signal({});
final Signal<Map<String, MapItem>> globalVpIndex = signal({});

Future<List<MapItem>> getMotionProfilesIndex() async {
  try {
    final res = await _dio.get(motionProfileIndex);
    return IndexSchema.fromJson(res.data).map;
  } catch (e) {
    print("[ERR] At getMotionProfilesIndex: $e");
    return [];
  }
}

Future<List<MapItem>> getVirtualPathsIndex() async {
  try {
    final res = await _dio.get(motionVirtualPathIndex);
    return IndexSchema.fromJson(res.data).map;
  } catch (e) {
    print("[ERR] At getVirtualPathsIndex: $e");
    return [];
  }
}

Future<MotionProfile?> getMotionProfile(String path) async {
  try {
    final res = await _dio.get(motionProfileBaseUrl + path);
    return MotionProfile.fromJson(res.data);
  } catch (e) {
    print("[ERR] At getMotionProfile: $e");
    return null;
  }
}

Future<VirtualPath?> getVirtualPath(String path) async {
  try {
    final res = await _dio.get(motionVirtualPathBaseUrl + path);
    return VirtualPath.fromJson(res.data);
  } catch (e) {
    print("[ERR] At getVirtualPath: $e");
    return null;
  }
}

Future<void> initIndex() async {
  clearIndex();
  final mpIndex = await getMotionProfilesIndex();
  final vpIndex = await getVirtualPathsIndex();
  for (var item in mpIndex) {
    globalMpIndex.value[item.id] = item;
  }
  for (var item in vpIndex) {
    globalVpIndex.value[item.id] = item;
  }
}

void clearIndex() {
  globalMpIndex.value.clear();
  globalVpIndex.value.clear();
}
