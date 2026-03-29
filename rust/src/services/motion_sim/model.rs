use serde::{Deserialize, Serialize};
use flutter_rust_bridge::frb;
use uuid::{Uuid};

/// 地理坐标点（WGS84坐标系）
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
#[frb]
pub struct GeoPoint {
    /// 纬度 (-90 到 90)
    pub latitude: f64,
    /// 经度 (-180 到 180)
    pub longitude: f64,
    /// 海拔高度（米）
    pub altitude: Option<f64>,
}

impl GeoPoint {
    pub fn new(latitude: f64, longitude: f64) -> Self {
        Self {
            latitude,
            longitude,
            altitude: None,
        }
    }

    pub fn with_altitude(latitude: f64, longitude: f64, altitude: f64) -> Self {
        Self {
            latitude,
            longitude,
            altitude: Some(altitude),
        }
    }

    /// 计算与另一个点的距离（使用Haversine公式，返回米）
    pub fn distance_to(&self, other: &GeoPoint) -> f64 {
        let lat1 = self.latitude.to_radians();
        let lat2 = other.latitude.to_radians();
        let dlat = (other.latitude - self.latitude).to_radians();
        let dlon = (other.longitude - self.longitude).to_radians();

        let a = (dlat / 2.0).sin().powi(2)
            + lat1.cos() * lat2.cos() * (dlon / 2.0).sin().powi(2);
        let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());

        // 地球平均半径（米）
        6_371_000.0 * c
    }

    /// 计算与另一个点的方位角（返回度数，0-360，正北为0）
    pub fn bearing_to(&self, other: &GeoPoint) -> f64 {
        let lat1 = self.latitude.to_radians();
        let lat2 = other.latitude.to_radians();
        let dlon = (other.longitude - self.longitude).to_radians();

        let x = dlon.sin() * lat2.cos();
        let y = lat1.cos() * lat2.sin() - lat1.sin() * lat2.cos() * dlon.cos();

        let bearing = y.atan2(x).to_degrees();
        (bearing + 360.0) % 360.0
    }

    /// 从当前点沿方位角移动指定距离，返回新点
    pub fn destination_point(&self, bearing: f64, distance: f64) -> GeoPoint {
        let lat1 = self.latitude.to_radians();
        let lon1 = self.longitude.to_radians();
        let brng = bearing.to_radians();

        let earth_radius = 6_371_000.0;
        let d = distance / earth_radius;

        let lat2 = (lat1.sin() * d.cos() + lat1.cos() * d.sin() * brng.cos()).asin();
        let lon2 = lon1 + brng.sin() * d.sin() * lat2.cos().atan2(lat1.cos() * d.cos() - lat1.sin() * d.sin() * lat2.cos());

        GeoPoint {
            latitude: lat2.to_degrees(),
            longitude: lon2.to_degrees(),
            altitude: self.altitude,
        }
    }
}

/// 轨迹数据
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct Trajectory {
    /// 轨迹ID
    pub id: String,
    /// 轨迹名称
    pub name: Option<String>,
    /// 轨迹点列表
    pub points: Vec<GeoPoint>,
}

impl Trajectory {
    pub fn new(points: Vec<GeoPoint>) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name: None,
            points,
        }
    }

    pub fn with_name(name: impl Into<String>, points: Vec<GeoPoint>) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name: Some(name.into()),
            points,
        }
    }

    /// 计算轨迹总长度（米）
    pub fn total_length(&self) -> f64 {
        self.points
            .windows(2)
            .map(|w| w[0].distance_to(&w[1]))
            .sum()
    }
}

/// 多边形区域（用于电子围栏和禁跑区）
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct Polygon {
    /// 多边形顶点
    pub points: Vec<GeoPoint>,
}

impl Polygon {
    pub fn new(points: Vec<GeoPoint>) -> Self {
        Self { points }
    }

    /// 判断点是否在多边形内部（射线法）
    pub fn contains(&self, point: &GeoPoint) -> bool {
        if self.points.len() < 3 {
            return false;
        }

        let mut inside = false;
        let n = self.points.len();
        let mut j = n - 1;

        for i in 0..n {
            let pi = &self.points[i];
            let pj = &self.points[j];

            let lat = point.latitude;
            let lon = point.longitude;

            if ((pi.latitude > lat) != (pj.latitude > lat))
                && (lon < (pj.longitude - pi.longitude) * (lat - pi.latitude)
                / (pj.latitude - pi.latitude) + pi.longitude)
            {
                inside = !inside;
            }
            j = i;
        }

        inside
    }

    /// 计算点到多边形边界的最短距离
    pub fn distance_to_boundary(&self, point: &GeoPoint) -> f64 {
        if self.points.len() < 2 {
            return f64::MAX;
        }

        let mut min_dist = f64::MAX;
        let n = self.points.len();

        for i in 0..n {
            let p1 = &self.points[i];
            let p2 = &self.points[(i + 1) % n];
            let dist = point_to_segment_distance(point, p1, p2);
            min_dist = min_dist.min(dist);
        }

        min_dist
    }

    /// 获取多边形中心点（简单平均）
    pub fn centroid(&self) -> Option<GeoPoint> {
        if self.points.is_empty() {
            return None;
        }

        let (lat, lon): (f64, f64) = self
            .points
            .iter()
            .fold((0.0, 0.0), |(lat_sum, lon_sum), p| {
                (lat_sum + p.latitude, lon_sum + p.longitude)
            });

        Some(GeoPoint::new(
            lat / self.points.len() as f64,
            lon / self.points.len() as f64,
        ))
    }
}

/// 点到线段的最短距离
fn point_to_segment_distance(point: &GeoPoint, seg_start: &GeoPoint, seg_end: &GeoPoint) -> f64 {
    // 将地理坐标转换为平面坐标（近似）
    let earth_radius = 6_371_000.0;
    let lat_mid = (point.latitude + seg_start.latitude) / 2.0;
    let cos_lat = lat_mid.to_radians().cos();

    let x0 = point.longitude * cos_lat;
    let y0 = point.latitude;
    let x1 = seg_start.longitude * cos_lat;
    let y1 = seg_start.latitude;
    let x2 = seg_end.longitude * cos_lat;
    let y2 = seg_end.latitude;

    // 转换为米
    let scale = earth_radius * std::f64::consts::PI / 180.0;
    let dx = (x2 - x1) * scale * cos_lat;
    let dy = (y2 - y1) * scale;
    let length_sq = dx * dx + dy * dy;

    if length_sq == 0.0 {
        return point.distance_to(seg_start);
    }

    // 计算投影参数t
    let px = (x0 - x1) * scale * cos_lat;
    let py = (y0 - y1) * scale;
    let t = ((px * dx + py * dy) / length_sq).clamp(0.0, 1.0);

    // 计算最近点
    let nearest_lon = x1 + t * (x2 - x1) / cos_lat / scale * cos_lat;
    let nearest_lat = y1 + t * (y2 - y1);

    point.distance_to(&GeoPoint::new(nearest_lat, nearest_lon / cos_lat))
}

/// 打卡点
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct Checkpoint {
    /// 打卡点ID
    pub id: String,
    /// 打卡点名称
    pub name: Option<String>,
    /// 打卡点位置（点打卡）
    pub point: Option<GeoPoint>,
    /// 打卡区域（区域打卡）
    pub area: Option<Polygon>,
    /// 打卡半径（米），用于点打卡
    pub radius: Option<f64>,
    /// 是否必经
    pub mandatory: bool,
    /// 顺序编号
    pub sequence: u32,
    /// 是否已打卡
    pub checked: bool,
}

impl Checkpoint {
    /// 创建点打卡点
    pub fn point_checkpoint(latitude: f64, longitude: f64, radius: f64, sequence: u32) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name: None,
            point: Some(GeoPoint::new(latitude, longitude)),
            area: None,
            radius: Some(radius),
            mandatory: true,
            sequence,
            checked: false,
        }
    }

    /// 创建区域打卡点
    pub fn area_checkpoint(area: Polygon, sequence: u32) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name: None,
            point: None,
            area: Some(area),
            radius: None,
            mandatory: true,
            sequence,
            checked: false,
        }
    }

    /// 检查是否在打卡范围内
    pub fn is_in_range(&self, position: &GeoPoint) -> bool {
        if let Some(point) = &self.point {
            if let Some(radius) = self.radius {
                return position.distance_to(point) <= radius;
            }
        }
        if let Some(area) = &self.area {
            return area.contains(position);
        }
        false
    }
}

/// 模拟器配置
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct SimulatorConfig {
    // ============ 速度相关配置 ============
    /// 目标速度（米/秒）
    pub target_speed: f64,
    /// 最小速度（米/秒）
    pub min_speed: f64,
    /// 最大速度（米/秒）
    pub max_speed: f64,
    /// 起跑加速度（米/秒²）
    pub acceleration: f64,
    /// 减速度（米/秒²）
    pub deceleration: f64,
    /// 步频（步/分钟）
    pub step_frequency: f64,
    /// 步幅（米）
    pub stride_length: f64,

    // ============ 刷新率配置 ============
    /// GPS刷新率
    pub gps_refresh_rate: f64,
    /// 加速度计刷新率
    pub accelerometer_refresh_rate: f64,
    /// 陀螺仪刷新率
    pub gyroscope_refresh_rate: f64,
    /// 指南针刷新率
    pub compass_refresh_rate: f64,
    /// 气压计刷新率
    pub barometer_refresh_rate: f64,

    // ============ 抖动参数配置 ============
    /// 抖动种子
    pub jitter_seed: u64,
    /// 位置抖动幅度（米）
    pub position_jitter_amplitude: f64,
    /// 速度抖动幅度（米/秒）
    pub speed_jitter_amplitude: f64,
    /// 方向抖动幅度（度）
    pub bearing_jitter_amplitude: f64,
    /// 加速度抖动幅度（米/秒²）
    pub accelerometer_jitter_amplitude: f64,
    /// 陀螺仪抖动幅度（度/秒）
    pub gyroscope_jitter_amplitude: f64,
    /// 抖动频率缩放
    pub jitter_frequency_scale: f64,

    // ============ 轨迹播放配置 ============
    /// 轨迹播放模式
    pub trajectory_mode: TrajectoryMode,
    /// 循环次数（0表示无限循环）
    pub loop_count: u32,

    // ============ 电子围栏配置 ============
    /// 电子围栏（必须在区域内）
    pub geofence: Option<Polygon>,
    /// 禁跑区（必须不在区域内）
    pub forbidden_zones: Vec<Polygon>,
    // 电子围栏警告距离（米）
    pub fence_warning_distance: f64,

    // ============ 打卡点配置 ============
    /// 预设打卡点列表
    pub checkpoints: Vec<Checkpoint>,
    /// 打卡点偏差容忍度（米）
    pub checkpoint_tolerance: f64,
    /// 是否自动调整路径经过打卡点
    pub auto_route_to_checkpoint: bool,
    /// 打卡点停留时间（秒）
    pub checkpoint_stay_time: f64,

    // ============ 寻路配置 ============
    /// A* 寻路网格分辨率（米）
    pub pathfinding_grid_resolution: f64,
    /// 平滑因子
    pub smoothing_factor: f64,

    // ============ 其他配置 ============
    /// 海拔基准（米）
    pub base_altitude: f64,
    /// 海拔变化幅度（米）
    pub altitude_variation: f64,
}

impl Default for SimulatorConfig {
    fn default() -> Self {
        Self {
            target_speed: 3.0,           // 3m/s，约为5′30″配速
            min_speed: 0.5,
            max_speed: 5.0,
            acceleration: 0.5,           // 每秒加速0.5m/s
            deceleration: 0.8,
            step_frequency: 160.0,       // 每分钟160步
            stride_length: 0.8,          // 80厘米步幅

            gps_refresh_rate: 1.0,       // 1Hz
            accelerometer_refresh_rate: 50.0,  // 50Hz
            gyroscope_refresh_rate: 50.0,
            compass_refresh_rate: 10.0,
            barometer_refresh_rate: 5.0,

            jitter_seed: 42,
            position_jitter_amplitude: 3.0,    // 3米
            speed_jitter_amplitude: 0.3,
            bearing_jitter_amplitude: 5.0,
            accelerometer_jitter_amplitude: 0.2,
            gyroscope_jitter_amplitude: 2.0,
            jitter_frequency_scale: 1.0,

            trajectory_mode: TrajectoryMode::Loop,
            loop_count: 0,

            geofence: None,
            forbidden_zones: Vec::new(),
            fence_warning_distance: 5.0,

            checkpoints: Vec::new(),
            checkpoint_tolerance: 10.0,
            auto_route_to_checkpoint: true,
            checkpoint_stay_time: 1.0,

            pathfinding_grid_resolution: 10.0,
            smoothing_factor: 0.5,

            base_altitude: 50.0,
            altitude_variation: 20.0,
        }
    }
}

/// 轨迹播放模式
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[frb]
pub enum TrajectoryMode {
    /// 单条轨迹循环播放
    Loop,
    /// 多条轨迹顺序播放
    Sequential,
    /// 多条轨迹随机播放
    Random,
}

/// 模拟器状态
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[frb]
pub enum SimulatorState {
    /// 空闲状态
    Idle,
    /// 准备中
    Preparing,
    /// 运行中
    Running,
    /// 暂停
    Paused,
    /// 停止中
    Stopping,
    /// 已停止
    Stopped,
    /// 错误
    Error,
}

/// 运动阶段
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[frb]
pub enum MovementPhase {
    /// 静止
    #[default]
    Stationary,
    /// 起跑加速
    Accelerating,
    /// 巡航
    Cruising,
    /// 减速
    Decelerating,
    /// 转向
    Turning,
    /// 打卡中
    Checkpoint,
}

/// 传感器数据包
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct SensorData {
    /// 时间戳（毫秒）
    pub timestamp: i64,
    /// GPS数据
    pub gps: Option<GpsData>,
    /// 加速度计数据
    pub accelerometer: Option<AccelerometerData>,
    /// 陀螺仪数据
    pub gyroscope: Option<GyroscopeData>,
    /// 指南针数据
    pub compass: Option<CompassData>,
    /// 气压计数据
    pub barometer: Option<BarometerData>,
    /// 计步数据
    pub pedometer: Option<PedometerData>,
}

/// GPS数据
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct GpsData {
    /// 当前位置
    pub position: GeoPoint,
    /// 当前速度（米/秒）
    pub speed: f64,
    /// 当前方向（度，0-360）
    pub bearing: f64,
    /// 水平精度（米）
    pub horizontal_accuracy: f64,
    /// 垂直精度（米）
    pub vertical_accuracy: f64,
    /// 卫星数量
    pub satellite_count: u8,
}

/// 加速度计数据
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct AccelerometerData {
    /// X轴加速度（m/s²）
    pub x: f64,
    /// Y轴加速度（m/s²）
    pub y: f64,
    /// Z轴加速度（m/s²）
    pub z: f64,
}

impl AccelerometerData {
    /// 计算加速度幅值
    pub fn magnitude(&self) -> f64 {
        (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
    }
}

/// 陀螺仪数据
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct GyroscopeData {
    /// X轴角速度（度/秒）
    pub x: f64,
    /// Y轴角速度（度/秒）
    pub y: f64,
    /// Z轴角速度（度/秒）
    pub z: f64,
}

/// 指南针数据
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct CompassData {
    /// 磁北方向（度）
    pub magnetic_heading: f64,
    /// 真北方向（度）
    pub true_heading: f64,
    /// 磁偏角（度）
    pub declination: f64,
    /// X轴磁场强度（微特斯拉）
    pub magnetic_field_x: f64,
    /// Y轴磁场强度（微特斯拉）
    pub magnetic_field_y: f64,
    /// Z轴磁场强度（微特斯拉）
    pub magnetic_field_z: f64,
}

/// 气压计数据
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct BarometerData {
    /// 气压（百帕）
    pub pressure: f64,
    /// 相对海拔（米）
    pub relative_altitude: f64,
}

/// 计步器数据
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct PedometerData {
    /// 总步数
    pub total_steps: u64,
    /// 当前步频（步/分钟）
    pub current_step_frequency: f64,
    /// 当前步幅（米）
    pub current_stride_length: f64,
    /// 本次跑步距离（米）
    pub distance: f64,
}

/// 模拟器统计信息
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[frb]
pub struct SimulatorStats {
    /// 运行时长（毫秒）
    pub elapsed_time_ms: u64,
    /// 总模拟距离（米）
    pub total_distance: f64,
    /// 当前速度（米/秒）
    pub current_speed: f64,
    /// 平均速度（米/秒）
    pub average_speed: f64,
    /// 消耗卡路里
    pub calories: f64,
    /// 总步数
    pub total_steps: u64,
    /// 当前轨迹索引
    pub current_trajectory_index: usize,
    /// 当前轨迹进度（0.0-1.0）
    pub trajectory_progress: f64,
    /// 已完成打卡点数
    pub checked_points: u32,
    /// 当前运动阶段
    pub current_phase: MovementPhase,
    /// 当前位置
    pub current_position: Option<GeoPoint>,
}

/// 指令类型
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub enum Command {
    // ============ 速度控制 ============
    /// 设置目标速度（米/秒）
    SetTargetSpeed(f64),
    /// 设置速度范围
    SetSpeedRange { min: f64, max: f64 },
    /// 设置加速度（米/秒²）
    SetAcceleration(f64),
    /// 设置减速度（米/秒²）
    SetDeceleration(f64),

    // ============ 步频控制 ============
    /// 设置步频（步/分钟）
    SetStepFrequency(f64),
    /// 设置步幅（米）
    SetStrideLength(f64),

    // ============ 运动控制 ============
    /// 暂停模拟
    Pause,
    /// 恢复模拟
    Resume,
    /// 立即停止模拟
    StopImmediately,
    /// N帧后延迟停止
    StopAfterFrames { frames: u32, graceful: bool },
    /// N秒后延迟停止
    StopAfterTime { seconds: f64, graceful: bool},
    /// 跳转到指定位置（轨迹进度）
    JumpToProgress(f64),
    /// 跳转到下一个轨迹
    NextTrajectory,

    // ============ 打卡点控制 ============
    /// 添加打卡点
    AddCheckpoint(Checkpoint),
    /// 移除打卡点
    RemoveCheckpoint(String),
    /// 清除所有打卡点
    ClearCheckpoints,
    /// 重置打卡状态
    ResetCheckpointStatus,

    // ============ 参数调整 ============
    /// 设置抖动参数
    SetJitterParams {
        position_amplitude: Option<f64>,
        speed_amplitude: Option<f64>,
        bearing_amplitude: Option<f64>,
    },
    /// 设置刷新率
    SetRefreshRate {
        gps: Option<f64>,
        accelerometer: Option<f64>,
        gyroscope: Option<f64>,
        compass: Option<f64>,
        barometer: Option<f64>,
    },
    /// 设置围栏警告距离
    SetFenceWarningDistance(f64),

    // ============ 轨迹控制 ============
    /// 切换轨迹
    SwitchTrajectory { index: usize, seamless: bool },
    /// 追加轨迹
    AppendTrajectory(Trajectory),

    // ============ 其他 ============
    /// 自定义指令（JSON格式）
    Custom(String),
}

/// 指令执行结果
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct CommandResult {
    /// 是否成功
    pub success: bool,
    /// 结果消息
    pub message: String,
    /// 额外数据（JSON格式）
    pub data: Option<String>,
}

/// 事件类型（用于回调）
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub enum SimulatorEvent {
    /// 模拟开始
    Started,
    /// 模拟暂停
    Paused,
    /// 模拟恢复
    Resumed,
    /// 模拟停止
    Stopped { reason: StopReason },
    /// 传感器数据更新
    SensorDataUpdated { data: SensorData },
    /// 位置更新
    PositionUpdated { position: GeoPoint, speed: f64, bearing: f64 },
    /// 速度变化
    SpeedChanged { old_speed: f64, new_speed: f64 },
    /// 运动阶段变化
    PhaseChanged { old_phase: MovementPhase, new_phase: MovementPhase },
    /// 轨迹切换
    TrajectorySwitched { index: usize, trajectory_id: String },
    /// 打卡成功
    CheckpointReached { checkpoint: Checkpoint },
    /// 所有打卡完成
    AllCheckpointsCompleted,
    /// 进入电子围栏边界
    GeofenceEntered,
    /// 离开电子围栏
    GeofenceExited,
    /// 进入禁跑区
    ForbiddenZoneEntered { zone_index: usize },
    /// 离开禁跑区
    ForbiddenZoneExited { zone_index: usize },
    /// 错误发生
    ErrorOccurred { message: String },
}

/// 停止原因
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub enum StopReason {
    /// 正常结束
    Normal,
    /// 用户请求
    UserRequested,
    /// 超出电子围栏
    GeofenceViolation,
    /// 进入禁跑区
    ForbiddenZoneViolation,
    /// 错误
    Error,
    /// 帧数或时间限制
    Limit,
}

/// 流更新事件
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub enum SimulatorUpdate {
    Event(SimulatorEvent),
    SensorData(SensorData),
}

// 集成测试
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_polygon_contains_edge_cases() {
        let polygon = Polygon::new(vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.0, 1.0),
            GeoPoint::new(1.0, 1.0),
            GeoPoint::new(1.0, 0.0),
        ]);
        // 点在左边边界上（经度 0.0），通常视为在区域内
        let on_edge = GeoPoint::new(0.5, 0.0);
        assert!(polygon.contains(&on_edge));
    }

    #[test]
    fn test_polygon_centroid_empty() {
        let empty = Polygon::new(vec![]);
        assert_eq!(empty.centroid(), None);
    }

    #[test]
    fn test_checkpoint_is_in_range() {
        let point_cp = Checkpoint::point_checkpoint(10.0, 10.0, 5.0, 1);
        let pos = GeoPoint::new(10.0, 10.0);
        assert!(point_cp.is_in_range(&pos));

        let area = Polygon::new(vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.0, 10.0),
            GeoPoint::new(10.0, 10.0),
            GeoPoint::new(10.0, 0.0),
        ]);
        let area_cp = Checkpoint::area_checkpoint(area, 2);
        let inside = GeoPoint::new(5.0, 5.0);
        assert!(area_cp.is_in_range(&inside));
        let outside = GeoPoint::new(-1.0, -1.0);
        assert!(!area_cp.is_in_range(&outside));
    }
}