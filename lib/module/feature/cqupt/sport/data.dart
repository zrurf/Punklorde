import 'package:punklorde/common/model/location.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/module/feature/cqupt/sport/model.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/module/platform/cqupt/sport_portal.dart';
import 'package:signals/signals_flutter.dart';

final Signal<AuthCredential?> featCredential = Signal<AuthCredential?>(
  null,
); // 身份凭据

final Computed<AuthCredential?> featPortalCredential = computed(() {
  final platId = platCquptSportPortal.id;
  return [
        authManager.getPrimaryAuthByPlatform(platId),
        ...authManager.getAllGuestAuthByPlatform(platId),
      ].nonNulls
      .toList()
      .where((v) => v.ext?["uid"] == featCredential.value?.ext?["unifyId"])
      .nonNulls
      .firstOrNull;
}); // 门户身份凭据

final Signal<UserConfig> featUserConfig = signal(UserConfig());

final Signal<String?> featPlaceCode = Signal<String?>(null); // 地点代码
final Signal<String?> featPlaceName = Signal<String?>(null); // 地点名称
final Signal<String?> featProfileId = Signal<String?>(null); // 运动配置ID
final Signal<String?> featProfileName = Signal<String?>(null); // 运动配置名称
final Signal<List<List<Coordinate>>> featPaths = Signal<List<List<Coordinate>>>(
  [],
); // 路径数据

// 运动配置索引
final Signal<Map<String, ResourceIndexEntry>?> featMotionProfileIndex =
    Signal<Map<String, ResourceIndexEntry>?>(null);

// 虚拟路径索引
final Signal<Map<String, ResourceIndexEntry>?> featVirtualPathIndex =
    Signal<Map<String, ResourceIndexEntry>?>(null);

// 运动配置
final Signal<MotionProfile?> featMotionProfile = Signal<MotionProfile?>(null);

// 虚拟路径
final Signal<Map<String, VirtualPath>?> featVirtualPaths =
    Signal<Map<String, VirtualPath>?>(null);
