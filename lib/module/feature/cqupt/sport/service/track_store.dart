import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:signals/signals_flutter.dart';

/// 已录制轨迹条目（含文件保存时间）
class RecordedTrack {
  final VirtualPath track;
  final DateTime savedAt;

  const RecordedTrack({required this.track, required this.savedAt});
}

final Signal<List<RecordedTrack>> featRecordedTracks = Signal([]);

/// 生成录制轨迹ID（符合 VirtualPath schema 的 id 格式）
String generateRecordedTrackId(DateTime time) =>
    "punklorde:rec@${time.millisecondsSinceEpoch}";

/// 重新加载已录制轨迹列表
Future<void> refreshRecordedTracks() async {
  featRecordedTracks.value = await _listTracks();
}

Future<Directory> _trackDir() async {
  final dir = Directory(
    "${(await getApplicationDocumentsDirectory()).path}/cqupt_sport_tracks",
  );
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

// 列出所有已录制轨迹
Future<List<RecordedTrack>> _listTracks() async {
  final dir = await _trackDir();
  final result = <RecordedTrack>[];
  for (final file in dir.listSync()) {
    if (file is! File || !file.path.endsWith('.path.json')) continue;
    try {
      final stat = file.statSync();
      final vp = VirtualPath.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      result.add(RecordedTrack(track: vp, savedAt: stat.modified));
    } catch (_) {
      // 跳过损坏的轨迹文件
    }
  }
  result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
  return result;
}

/// 保存录制轨迹，返回文件路径
Future<String> saveRecordedTrack(VirtualPath vp) async {
  final dir = await _trackDir();
  final file = File('${dir.path}/${vp.id}.path.json');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(vp));
  await refreshRecordedTracks();
  return file.path;
}

/// 删除录制轨迹
Future<void> deleteRecordedTrack(String id) async {
  final dir = await _trackDir();
  final file = File('${dir.path}/$id.path.json');
  if (file.existsSync()) await file.delete();
  await refreshRecordedTracks();
}
