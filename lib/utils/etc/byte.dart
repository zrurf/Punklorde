import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// U8List添加魔数
Uint8List prependMagic(Uint8List original, List<int> magic) {
  final result = Uint8List(magic.length + original.length);
  result.setAll(0, magic); // 将魔数写入开头
  result.setAll(magic.length, original); // 将原数据接在后面
  return result;
}

// 提取魔数后的数据
Uint8List extractAfterMagic(Uint8List fullData, List<int> expectedMagic) {
  if (fullData.length < expectedMagic.length) {
    throw FormatException();
  }
  if (!ListEquality().equals(
    fullData.sublist(0, expectedMagic.length),
    expectedMagic,
  )) {
    throw FormatException("Magic number mismatch");
  }
  return fullData.sublist(expectedMagic.length);
}

// 检查数据是否以指定数据开头
bool startsWith(Uint8List data, List<int> magic) {
  if (data.length < magic.length) return false;
  return listEquals(data.sublist(0, magic.length), magic);
}
