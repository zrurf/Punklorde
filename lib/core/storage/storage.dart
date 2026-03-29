import 'dart:typed_data';
import 'package:cbor/simple.dart';
import 'package:mmkv/mmkv.dart';
import 'package:zstandard/zstandard.dart';

/// StorageService 封装层
class StorageService {
  // 单例模式
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // 缓存所有 MMKV 实例
  final Map<String, MMKV> _mmkvInstances = {};

  // 默认实例的 ID
  static const String _defaultInstanceId = 'default';

  // Zstd 压缩助手
  final Zstandard _zstd = Zstandard();

  // 压缩阈值：超过此大小（字节）的数据将自动压缩
  static const int _compressionThreshold = 8 * 1024;
  // 压缩级别：1-22，数字越大压缩越强
  static const int _compressLevel = 6;

  /// 初始化服务
  /// 必须在 runApp 之前调用，并传入 Native Context
  Future<void> init({String? rootDir}) async {
    // MMKV 初始化
    await MMKV.initialize(rootDir: rootDir);

    // 预加载默认实例
    getMMKV(_defaultInstanceId);
  }

  /// 获取或创建 MMKV 实例
  /// [mmapID] 实例唯一标识
  /// [cryptKey] 加密密钥 (可选)
  MMKV getMMKV(String mmapID, {String? cryptKey}) {
    if (!_mmkvInstances.containsKey(mmapID)) {
      // 如果提供了加密key，则创建加密实例
      final instance = (mmapID == _defaultInstanceId)
          ? MMKV.defaultMMKV(cryptKey: cryptKey)
          : MMKV(mmapID, cryptKey: cryptKey);
      _mmkvInstances[mmapID] = instance;
    }
    return _mmkvInstances[mmapID]!;
  }

  /// 获取默认实例
  MMKV get defaultInstance => getMMKV(_defaultInstanceId);

  /// 存储数据（自动判断是否压缩）
  /// [key] 键
  /// [value] 字节数据
  /// [instance] 目标 MMKV 实例
  Future<void> _putBytesWithAutoCompress(
    String key,
    Uint8List value,
    MMKV instance,
  ) async {
    Uint8List finalData = value;

    // 标记是否压缩
    bool shouldCompress = value.length > _compressionThreshold;

    if (shouldCompress) {
      try {
        final compressed = await _zstd.compress(value, _compressLevel);
        if (compressed != null && compressed.length < value.length) {
          finalData = compressed;
        } else {
          shouldCompress = false; // 压缩后反而变大或失败，不压缩
        }
      } catch (e) {
        shouldCompress = false;
        print('Zstd compression failed for key $key: $e');
      }
    }

    // 我们在数据头部预留一个字节标识是否被压缩
    // 0: 未压缩, 1: 已压缩
    final header = ByteData(1);
    header.setUint8(0, shouldCompress ? 1 : 0);

    // 合并头部和数据
    final builder = BytesBuilder();
    builder.add(header.buffer.asUint8List());
    builder.add(finalData);

    instance.encodeBytes(key, MMBuffer.fromList(builder.toBytes()));
  }

  /// 读取数据（自动解压）
  Future<Uint8List?> _getBytesWithAutoDecompress(
    String key,
    MMKV instance,
  ) async {
    final rawData = instance.decodeBytes(key)?.asList();
    if (rawData == null || rawData.isEmpty) return null;

    // 解析头部
    final header = rawData[0];
    final actualData = rawData.sublist(1);

    // 检查是否被压缩
    if (header == 1) {
      try {
        final decompressed = await _zstd.decompress(actualData);
        return decompressed;
      } catch (e) {
        print('Zstd decompression failed for key $key: $e');
        return null;
      }
    } else {
      return actualData;
    }
  }

  /// 存储 Map 对象 (自动 CBOR 序列化 + 自动 Zstd 压缩)
  Future<void> putMap(
    String key,
    Map<String, dynamic> value, {
    MMKV? instance,
  }) async {
    final mmkv = instance ?? defaultInstance;

    // 1. CBOR 序列化
    final cborBytes = cbor.encode(value);

    // 2. 自动压缩存储
    await _putBytesWithAutoCompress(key, Uint8List.fromList(cborBytes), mmkv);
  }

  /// 读取 Map 对象 (自动 CBOR 反序列化 + 自动 Zstd 解压)
  Future<Map<String, dynamic>?> getMap(String key, {MMKV? instance}) async {
    final mmkv = instance ?? defaultInstance;

    // 1. 读取并自动解压
    final rawBytes = await _getBytesWithAutoDecompress(key, mmkv);
    if (rawBytes == null) return null;

    // 2. CBOR 反序列化
    try {
      return cbor.decode(rawBytes) as Map<String, dynamic>?;
    } catch (e) {
      print('CBOR decode failed for key $key: $e');
      return null;
    }
  }

  /// 存储 List 对象 (自动 CBOR 序列化 + 自动 Zstd 压缩)
  Future<void> putList(
    String key,
    List<dynamic> value, {
    MMKV? instance,
  }) async {
    final mmkv = instance ?? defaultInstance;
    try {
      // CBOR 序列化
      final cborBytes = cbor.encode(value);
      await _putBytesWithAutoCompress(key, Uint8List.fromList(cborBytes), mmkv);
    } catch (e) {
      print('CBOR encode failed for list key $key: $e');
      rethrow; // 或根据业务决定是否吞掉异常
    }
  }

  /// 读取 List 对象 (自动 CBOR 反序列化 + 自动 Zstd 解压)
  Future<List<dynamic>?> getList(String key, {MMKV? instance}) async {
    final mmkv = instance ?? defaultInstance;
    try {
      // 读取并自动解压
      final rawBytes = await _getBytesWithAutoDecompress(key, mmkv);
      if (rawBytes == null) return null;

      // CBOR 反序列化
      final decoded = cbor.decode(rawBytes);
      // 类型校验
      if (decoded is List) {
        return decoded;
      } else {
        print('Decoded data for key $key is not a List');
        return null;
      }
    } catch (e) {
      print('Failed to get list for key $key: $e');
      return null;
    }
  }

  /// 存储大对象 - 仅自动压缩
  Future<void> putBytes(String key, Uint8List value, {MMKV? instance}) async {
    final mmkv = instance ?? defaultInstance;
    await _putBytesWithAutoCompress(key, value, mmkv);
  }

  /// 读取大对象 - 仅自动解压
  Future<Uint8List?> getBytes(String key, {MMKV? instance}) async {
    final mmkv = instance ?? defaultInstance;
    return await _getBytesWithAutoDecompress(key, mmkv);
  }

  /// 存储Int
  void putInt(String key, int value, {MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    mmkv.encodeInt(key, value);
  }

  /// 读取Int
  int getInt(String key, {int defaultValue = 0, MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    return mmkv.decodeInt(key, defaultValue: defaultValue);
  }

  /// 存储String
  void putString(String key, String value, {MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    mmkv.encodeString(key, value);
  }

  /// 读取String
  String? getString(String key, {MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    return mmkv.decodeString(key);
  }

  /// 存储Bool
  void putBool(String key, bool value, {MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    mmkv.encodeBool(key, value);
  }

  /// 读取Bool
  bool getBool(String key, {bool defaultValue = false, MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    return mmkv.decodeBool(key, defaultValue: defaultValue);
  }

  /// 存储Double
  void putDouble(String key, double value, {MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    mmkv.encodeDouble(key, value);
  }

  /// 读取Double
  double getDouble(String key, {double defaultValue = 0.0, MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    return mmkv.decodeDouble(key, defaultValue: defaultValue);
  }

  /// 检查 Key 是否存在
  bool containsKey(String key, {MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    return mmkv.containsKey(key);
  }

  /// 删除指定 Key
  void remove(String key, {MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    mmkv.removeValue(key);
  }

  /// 清空指定实例
  void clear({MMKV? instance}) {
    final mmkv = instance ?? defaultInstance;
    mmkv.clearAll();
  }
}
