import 'package:mmkv/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';

late final MMKV defaultMMKV;
late final MMKV authMMKV;
late final MMKV cacheMMKV;

Future<void> initMMKV(String cryptKey) async {
  final storage = StorageService();
  defaultMMKV = storage.getMMKV('default', cryptKey: cryptKey);
  authMMKV = storage.getMMKV('auth', cryptKey: cryptKey);
  cacheMMKV = storage.getMMKV('cache', cryptKey: cryptKey);
}
