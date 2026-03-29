import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// 确定性 UUID 生成器
class DeterministicUuidUtil {
  /// 预计算的 Hex 查找表。
  /// 将 0-255 的值直接映射为两个 ASCII 字符码（例如：15 -> [0x31, 0x66] 即 '1', 'f'）。
  /// 这样可以消除运行时的位运算和格式化开销。
  static final List<int> _hexLookupTable = _buildHexTable();

  /// 生成确定性 UUID
  static String generate(String input) {
    // 1. UTF-8 编码 & MD5 哈希
    // utf8.encode 已经很快，md5.convert 是计算瓶颈所在
    final digest = md5.convert(utf8.encode(input));
    final bytes = digest.bytes;

    // 2. 准备输出缓冲区 (36 bytes: 32 hex + 4 hyphens)
    final out = Uint8List(36);

    // 3. 填充数据 (展开循环 + 查表法)
    // UUID 格式: 8-4-4-4-12
    // 注意：我们在此处处理版本位和变体位，但不修改原始 bytes 数组

    // --- 第一段: 8 chars (bytes 0-3) ---
    _writeByte(out, 0, bytes[0]);
    _writeByte(out, 2, bytes[1]);
    _writeByte(out, 4, bytes[2]);
    _writeByte(out, 6, bytes[3]);
    out[8] = 45; // '-'

    // --- 第二段: 4 chars (bytes 4-5) ---
    _writeByte(out, 9, bytes[4]);
    _writeByte(out, 11, bytes[5]);
    out[13] = 45; // '-'

    // --- 第三段: 4 chars (bytes 6-7) ---
    // 处理 Version 3 (MD5) 逻辑: 清除高4位，设为 0x3
    // 原始: bytes[6] = (bytes[6] & 0x0f) | 0x30
    // 我们直接查表，因为查表索引就是处理后的值
    _writeByte(out, 14, (bytes[6] & 0x0f) | 0x30);
    _writeByte(out, 16, bytes[7]);
    out[18] = 45; // '-'

    // --- 第四段: 4 chars (bytes 8-9) ---
    // 处理 Variant 逻辑: 清除高2位，设为 0x8
    // 原始: bytes[8] = (bytes[8] & 0x3f) | 0x80
    _writeByte(out, 19, (bytes[8] & 0x3f) | 0x80);
    _writeByte(out, 21, bytes[9]);
    out[23] = 45; // '-'

    // --- 第五段: 12 chars (bytes 10-15) ---
    _writeByte(out, 24, bytes[10]);
    _writeByte(out, 26, bytes[11]);
    _writeByte(out, 28, bytes[12]);
    _writeByte(out, 30, bytes[13]);
    _writeByte(out, 32, bytes[14]);
    _writeByte(out, 34, bytes[15]);

    return String.fromCharCodes(out);
  }

  /// 内联辅助方法：从查找表写入两个字符
  static void _writeByte(Uint8List out, int offset, int byteValue) {
    final int lookupIndex = byteValue * 2;
    out[offset] = _hexLookupTable[lookupIndex];
    out[offset + 1] = _hexLookupTable[lookupIndex + 1];
  }

  /// 构建静态查找表
  static List<int> _buildHexTable() {
    const hexDigits = '0123456789abcdef';
    final table = List<int>.filled(512, 0);
    for (int i = 0; i < 256; i++) {
      final highChar = hexDigits.codeUnitAt((i >> 4) & 0x0F);
      final lowChar = hexDigits.codeUnitAt(i & 0x0F);
      table[i * 2] = highChar;
      table[i * 2 + 1] = lowChar;
    }
    return table;
  }
}
