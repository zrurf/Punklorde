import 'dart:convert';
import 'dart:io';

import 'package:punklorde/core/status/resource.dart';
import 'package:punklorde/module/feature/cqupt/sport/data.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/feature/cqupt/sport/resource/endpoint.dart';

// 加载资源索引
Future<bool> loadReourceIndex() async {
  final mpIdxPath = await resourceManager.loadResource(
    epMotionProfileIndex,
    expiry: const Duration(days: 1),
  );
  final vpIdxPath = await resourceManager.loadResource(
    epVirtualPathIndex,
    expiry: const Duration(days: 1),
  );

  if (mpIdxPath == null || vpIdxPath == null) {
    return false;
  }

  final mpIdxStr = await File(mpIdxPath).readAsString();
  final vpIdxStr = await File(vpIdxPath).readAsString();

  try {
    final mpIdx = IndexSchema.fromJson(jsonDecode(mpIdxStr));
    final vpIdx = IndexSchema.fromJson(jsonDecode(vpIdxStr));

    final Map<String, ResourceIndexEntry> mpIdxMap = {};
    final Map<String, ResourceIndexEntry> vpIdxMap = {};

    for (final v in mpIdx.map) {
      mpIdxMap[v.id] = v;
    }
    for (final v in vpIdx.map) {
      vpIdxMap[v.id] = v;
    }

    featMotionProfileIndex.value = mpIdxMap;
    featVirtualPathIndex.value = vpIdxMap;
  } catch (e) {
    return false;
  }
  return true;
}

// 通过MotionProfile ID加载资源
Future<bool> loadMotionProfile(String id) async {
  if (featMotionProfileIndex.value == null ||
      featVirtualPathIndex.value == null ||
      !featMotionProfileIndex.value!.containsKey(id)) {
    return false;
  }
  try {
    final mp = featMotionProfileIndex.value![id]!;
    final mpPath = await resourceManager.loadResource(
      '$epMotionProfileBase/${mp.path}',
      expiry: const Duration(days: 7),
    );
    if (mpPath == null) {
      return false;
    }
    final mpStr = await File(mpPath).readAsString();
    featMotionProfile.value = MotionProfile.fromJson(jsonDecode(mpStr));

    Map<String, VirtualPath> vpIdxMap = {};
    for (final v in featMotionProfile.value!.data?.paths ?? []) {
      if (!featVirtualPathIndex.value!.containsKey(v)) {
        return false;
      }
      final vp = featVirtualPathIndex.value![v]!;
      final vpPath = await resourceManager.loadResource(
        '$epVirtualPathBase/${vp.path}',
        expiry: const Duration(days: 7),
      );
      if (vpPath == null) {
        return false;
      }
      final vpStr = await File(vpPath).readAsString();
      vpIdxMap[v] = VirtualPath.fromJson(jsonDecode(vpStr));
    }
    featVirtualPaths.value = vpIdxMap;
    featPlaceCode.value = featMotionProfile.value?.data?.ext?["placeCode"];
    featPlaceName.value = featMotionProfile.value?.data?.ext?["placeName"];
  } catch (e) {
    return false;
  }
  return true;
}
