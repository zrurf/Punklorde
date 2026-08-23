import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:punklorde/module/service/lbs/map.dart';
import 'package:signals/signals_flutter.dart';

/// 地图实现（默认取第一个可用 provider）
final Signal<MapProviderType> mapProviderSignal = signal(
  _firstAvailableProvider(),
);

MapProviderType _firstAvailableProvider() {
  final list = availableMapProviders;
  return (list.isEmpty) ? MapProviderType.baidu : list.first;
}

/// 切换地图实现（仅允许选择已提供 Key 的实现）
void setMapProvider(MapProviderType type) {
  if (!type.available) return;
  mapProviderSignal.value = type;
}

// 初始化地图实现状态
void initMapStatus() {
  effect(() {
    storeMapProvider();
  });
}

void storeMapProvider() {
  StorageService().putString(
    'map_provider',
    mapProviderSignal.value.raw,
    instance: defaultMMKV,
  );
}

void loadMapProvider() {
  final raw = StorageService().getString(
    'map_provider',
    instance: defaultMMKV,
  );
  final saved = MapProviderTypeX.fromRaw(raw);
  if (saved != null && saved.available) {
    mapProviderSignal.value = saved;
  } else {
    mapProviderSignal.value = _firstAvailableProvider();
  }
}