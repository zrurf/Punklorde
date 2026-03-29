//! 抖动生成器

use crate::services::motion_sim::model::GeoPoint;
use super::simplex::{MultiDimensionalNoise, SimplexNoise};

/// 抖动参数配置
#[derive(Debug, Clone)]
pub struct JitterConfig {
    /// 位置抖动幅度（米）
    pub position_amplitude: f64,
    /// 速度抖动幅度（米/秒）
    pub speed_amplitude: f64,
    /// 方向抖动幅度（度）
    pub bearing_amplitude: f64,
    /// 加速度抖动幅度（m/s²）
    pub accelerometer_amplitude: f64,
    /// 陀螺仪抖动幅度（度/秒）
    pub gyroscope_amplitude: f64,
    /// 时间频率缩放
    pub time_frequency: f64,
    /// 空间频率缩放
    pub spatial_frequency: f64,
}

impl Default for JitterConfig {
    fn default() -> Self {
        Self {
            position_amplitude: 3.0,
            speed_amplitude: 0.3,
            bearing_amplitude: 5.0,
            accelerometer_amplitude: 0.2,
            gyroscope_amplitude: 2.0,
            time_frequency: 1.0,
            spatial_frequency: 0.001,  // 约1米的空间尺度
        }
    }
}

/// 抖动生成器
///
/// 生成各种类型的抖动效果，模拟真实运动和传感器数据
#[derive(Debug, Clone)]
pub struct JitterGenerator {
    /// 噪声生成器
    noise: MultiDimensionalNoise,
    /// 配置参数
    config: JitterConfig,
    /// 当前时间
    current_time: f64,
}

impl JitterGenerator {
    /// 创建新的抖动生成器
    pub fn new(seed: u64, config: JitterConfig) -> Self {
        Self {
            noise: MultiDimensionalNoise::new(seed),
            config,
            current_time: 0.0,
        }
    }

    /// 更新时间
    pub fn update_time(&mut self, dt: f64) {
        self.current_time += dt;
    }

    /// 设置当前时间
    pub fn set_time(&mut self, time: f64) {
        self.current_time = time;
    }

    /// 生成位置抖动
    ///
    /// # 参数
    /// * `base_position` - 基准位置
    ///
    /// # 返回
    /// 添加抖动后的位置
    pub fn jitter_position(&self, base_position: &GeoPoint) -> GeoPoint {
        // 将经纬度转换为噪声空间的坐标
        let x = base_position.longitude * self.config.spatial_frequency * 10000.0;
        let y = base_position.latitude * self.config.spatial_frequency * 10000.0;
        let t = self.current_time * self.config.time_frequency;

        // 生成南北和东西方向的抖动
        let lat_jitter = self.noise.smooth_temporal_noise(x, y, t, 0.5);
        let lon_jitter = self.noise.smooth_temporal_noise(x + 100.0, y + 100.0, t, 0.5);

        // 将抖动转换为位移（米到经纬度的转换）
        let earth_radius = 6_371_000.0;
        let lat_rad = base_position.latitude.to_radians();

        // 每米约等于多少度
        let meters_per_degree_lat = earth_radius * std::f64::consts::PI / 180.0;
        let meters_per_degree_lon = meters_per_degree_lat * lat_rad.cos();

        let lat_offset = lat_jitter * self.config.position_amplitude / meters_per_degree_lat;
        let lon_offset = lon_jitter * self.config.position_amplitude / meters_per_degree_lon;

        GeoPoint {
            latitude: base_position.latitude + lat_offset,
            longitude: base_position.longitude + lon_offset,
            altitude: base_position.altitude,
        }
    }

    /// 生成速度抖动
    ///
    /// # 参数
    /// * `base_speed` - 基准速度（米/秒）
    ///
    /// # 返回
    /// 添加抖动后的速度
    pub fn jitter_speed(&self, base_speed: f64) -> f64 {
        let t = self.current_time * self.config.time_frequency;
        let noise = self.noise.smooth_temporal_noise(0.0, 0.0, t, 0.3);
        let jitter = noise * self.config.speed_amplitude;

        // 确保速度不为负
        (base_speed + jitter).max(0.0)
    }

    /// 生成方向抖动
    ///
    /// # 参数
    /// * `base_bearing` - 基准方向（度）
    ///
    /// # 返回
    /// 添加抖动后的方向（度，0-360）
    pub fn jitter_bearing(&self, base_bearing: f64) -> f64 {
        let t = self.current_time * self.config.time_frequency;
        let noise = self.noise.smooth_temporal_noise(100.0, 100.0, t, 0.2);
        let jitter = noise * self.config.bearing_amplitude;

        let result = base_bearing + jitter;
        ((result % 360.0) + 360.0) % 360.0
    }

    /// 生成加速度抖动（三轴）
    ///
    /// # 参数
    /// * `base_acc` - 基准加速度
    ///
    /// # 返回
    /// (x, y, z) 轴的抖动加速度
    pub fn jitter_accelerometer(&self, base_x: f64, base_y: f64, base_z: f64) -> (f64, f64, f64) {
        let t = self.current_time * self.config.time_frequency * 2.0; // 加速度计需要更高的频率响应

        // 生成三轴独立的抖动，但有一定的相关性
        let noise_x = self.noise.smooth_temporal_noise(0.0, 0.0, t, 0.4);
        let noise_y = self.noise.smooth_temporal_noise(50.0, 50.0, t, 0.4);
        let noise_z = self.noise.smooth_temporal_noise(100.0, 100.0, t, 0.4);

        let amp = self.config.accelerometer_amplitude;

        (
            base_x + noise_x * amp,
            base_y + noise_y * amp,
            base_z + noise_z * amp,
        )
    }

    /// 生成陀螺仪抖动（三轴角速度）
    ///
    /// # 参数
    /// * `base_gyro` - 基准角速度
    ///
    /// # 返回
    /// (x, y, z) 轴的抖动角速度（度/秒）
    pub fn jitter_gyroscope(&self, base_x: f64, base_y: f64, base_z: f64) -> (f64, f64, f64) {
        let t = self.current_time * self.config.time_frequency * 3.0; // 陀螺仪需要最高的频率响应

        let noise_x = self.noise.smooth_temporal_noise(0.0, 0.0, t, 0.3);
        let noise_y = self.noise.smooth_temporal_noise(75.0, 75.0, t, 0.3);
        let noise_z = self.noise.smooth_temporal_noise(150.0, 150.0, t, 0.3);

        let amp = self.config.gyroscope_amplitude;

        (
            base_x + noise_x * amp,
            base_y + noise_y * amp,
            base_z + noise_z * amp,
        )
    }

    /// 生成气压抖动
    ///
    /// # 参数
    /// * `base_pressure` - 基准气压（百帕）
    ///
    /// # 返回
    /// 添加抖动后的气压
    pub fn jitter_pressure(&self, base_pressure: f64) -> f64 {
        let t = self.current_time * self.config.time_frequency * 0.1; // 气压变化较慢
        let noise = self.noise.smooth_temporal_noise(0.0, 0.0, t, 0.1);

        // 气压抖动幅度约0.1-0.5 hPa
        base_pressure + noise * 0.3
    }

    /// 生成高度抖动
    ///
    /// # 参数
    /// * `base_altitude` - 基准高度（米）
    ///
    /// # 返回
    /// 添加抖动后的高度
    pub fn jitter_altitude(&self, base_altitude: f64) -> f64 {
        let t = self.current_time * self.config.time_frequency * 0.2;
        let noise = self.noise.smooth_temporal_noise(0.0, 0.0, t, 0.15);

        // GPS高度精度较低，抖动幅度较大（约5-10米）
        base_altitude + noise * 7.0
    }

    pub fn noise2d(&self, x: f64, y: f64) -> f64 {
        let noise = SimplexNoise::new(42);
        noise.noise2d(x, y)
    }

    /// 更新配置
    pub fn update_config(&mut self, config: JitterConfig) {
        self.config = config;
    }

    /// 获取当前配置
    pub fn config(&self) -> &JitterConfig {
        &self.config
    }
}

/// 运动模式抖动策略
///
/// 根据运动模式调整抖动参数
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotionPattern {
    /// 静止
    Stationary,
    /// 行走
    Walking,
    /// 跑步
    Running,
    /// 骑行
    Cycling,
    /// 驾驶
    Driving,
}

impl MotionPattern {
    /// 获取该模式下的默认抖动配置
    pub fn default_jitter_config(&self) -> JitterConfig {
        match self {
            MotionPattern::Stationary => JitterConfig {
                position_amplitude: 2.0,
                speed_amplitude: 0.0,
                bearing_amplitude: 2.0,
                accelerometer_amplitude: 0.05,
                gyroscope_amplitude: 0.5,
                time_frequency: 0.5,
                spatial_frequency: 0.0005,
            },
            MotionPattern::Walking => JitterConfig {
                position_amplitude: 2.5,
                speed_amplitude: 0.2,
                bearing_amplitude: 3.0,
                accelerometer_amplitude: 0.3,
                gyroscope_amplitude: 1.5,
                time_frequency: 1.5,
                spatial_frequency: 0.001,
            },
            MotionPattern::Running => JitterConfig {
                position_amplitude: 4.0,
                speed_amplitude: 0.5,
                bearing_amplitude: 5.0,
                accelerometer_amplitude: 0.8,
                gyroscope_amplitude: 3.0,
                time_frequency: 2.5,
                spatial_frequency: 0.0015,
            },
            MotionPattern::Cycling => JitterConfig {
                position_amplitude: 2.0,
                speed_amplitude: 0.3,
                bearing_amplitude: 3.0,
                accelerometer_amplitude: 0.2,
                gyroscope_amplitude: 1.0,
                time_frequency: 1.0,
                spatial_frequency: 0.001,
            },
            MotionPattern::Driving => JitterConfig {
                position_amplitude: 5.0,
                speed_amplitude: 1.0,
                bearing_amplitude: 2.0,
                accelerometer_amplitude: 0.15,
                gyroscope_amplitude: 0.5,
                time_frequency: 0.8,
                spatial_frequency: 0.0008,
            },
        }
    }
}
