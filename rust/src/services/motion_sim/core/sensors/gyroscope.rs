//! 陀螺仪传感器模拟

use rand::rngs::StdRng;
use rand::{RngExt, SeedableRng};
use crate::services::motion_sim::core::noise::jitter::{JitterConfig, JitterGenerator};
use crate::services::motion_sim::model::{AccelerometerData, GyroscopeData};

/// 陀螺仪传感器配置
#[derive(Debug, Clone)]
pub struct GyroscopeConfig {
    /// 传感器量程（±度/秒）
    pub range: f64,
    /// 分辨率（度/秒）
    pub resolution: f64,
    /// 噪声密度（度/秒/√Hz）
    pub noise_density: f64,
    /// 零偏稳定性（度/秒）
    pub bias_stability: f64,
    /// 随机游走（度/秒/√Hz）
    pub random_walk: f64,
}

impl Default for GyroscopeConfig {
    fn default() -> Self {
        Self {
            range: 2000.0,
            resolution: 0.01,
            noise_density: 0.01,
            bias_stability: 0.1,
            random_walk: 0.005,
        }
    }
}

/// 陀螺仪传感器模拟器
pub struct GyroscopeSensor {
    config: GyroscopeConfig,
    jitter: JitterGenerator,
    rng: StdRng,
    /// 零偏
    bias: (f64, f64, f64),
    /// 上一次方向
    last_bearing: f64,
    /// 方向变化率
    bearing_change_rate: f64,
}

impl GyroscopeSensor {
    pub fn new(config: GyroscopeConfig, jitter_seed: u64) -> Self {
        let jitter_config = JitterConfig {
            gyroscope_amplitude: config.noise_density,
            ..Default::default()
        };

        let mut rng = StdRng::seed_from_u64(jitter_seed + 1);

        // 初始化零偏
        let bias = (
            (rng.random::<f64>() - 0.5) * config.bias_stability,
            (rng.random::<f64>() - 0.5) * config.bias_stability,
            (rng.random::<f64>() - 0.5) * config.bias_stability,
        );

        Self {
            config,
            jitter: JitterGenerator::new(jitter_seed, jitter_config),
            rng,
            bias,
            last_bearing: 0.0,
            bearing_change_rate: 0.0,
        }
    }

    /// 生成陀螺仪数据
    ///
    /// # 参数
    /// * `current_bearing` - 当前方向（度）
    /// * `is_turning` - 是否正在转向
    /// * `turn_rate` - 转向速率（度/秒）
    /// * `dt` - 时间步长（秒）
    pub fn generate(
        &mut self,
        current_bearing: f64,
        is_turning: bool,
        turn_rate: f64,
        dt: f64,
    ) -> GyroscopeData {
        // 更新抖动时间
        self.jitter.update_time(dt);

        // 计算方向变化
        let mut bearing_diff = current_bearing - self.last_bearing;

        // 处理跨0度的情况
        if bearing_diff > 180.0 {
            bearing_diff -= 360.0;
        } else if bearing_diff < -180.0 {
            bearing_diff += 360.0;
        }

        // 平滑处理方向变化率
        let instant_rate = bearing_diff / dt.max(0.001);
        self.bearing_change_rate = self.bearing_change_rate * 0.7 + instant_rate * 0.3;

        // 计算各轴角速度
        // 假设手机水平放置，z轴向上
        let mut gz = if is_turning {
            turn_rate
        } else {
            self.bearing_change_rate
        };

        // x和y轴的角速度通常较小（除非手机倾斜或晃动）
        let mut gx = self.generate_minor_rotation();
        let mut gy = self.generate_minor_rotation();

        // 添加零偏
        gx += self.bias.0;
        gy += self.bias.1;
        gz += self.bias.2;

        // 添加噪声
        let (jx, jy, jz) = self.jitter.jitter_gyroscope(0.0, 0.0, 0.0);
        gx += jx;
        gy += jy;
        gz += jz;

        // 限制在量程范围内
        gx = gx.clamp(-self.config.range, self.config.range);
        gy = gy.clamp(-self.config.range, self.config.range);
        gz = gz.clamp(-self.config.range, self.config.range);

        // 应用分辨率
        gx = (gx / self.config.resolution).round() * self.config.resolution;
        gy = (gy / self.config.resolution).round() * self.config.resolution;
        gz = (gz / self.config.resolution).round() * self.config.resolution;

        // 更新上一次方向
        self.last_bearing = current_bearing;

        GyroscopeData { x: gx, y: gy, z: gz }
    }

    /// 生成较小的旋转（模拟手持抖动）
    fn generate_minor_rotation(&self) -> f64 {
        let t = chrono::Utc::now().timestamp_nanos_opt().unwrap_or(0) as f64 * 1e-9;
        let noise = (t * 3.7).sin() * 0.5 + (t * 7.3).sin() * 0.3;
        noise
    }

    /// 设置零偏
    pub fn set_bias(&mut self, bias: (f64, f64, f64)) {
        self.bias = bias;
    }

    /// 校准（移除零偏）
    pub fn calibrate(&mut self) {
        // 实际校准需要静止状态采样
        self.bias = (0.0, 0.0, 0.0);
    }

    /// 更新配置
    pub fn update_config(&mut self, config: GyroscopeConfig) {
        self.config = config;
    }
}

/// 姿态估计器
///
/// 融合加速度计和陀螺仪数据估计设备姿态
pub struct AttitudeEstimator {
    /// 当前姿态（四元数：w, x, y, z）
    quaternion: (f64, f64, f64, f64),
    /// 互补滤波系数
    alpha: f64,
}

impl AttitudeEstimator {
    pub fn new() -> Self {
        Self {
            quaternion: (1.0, 0.0, 0.0, 0.0), // 单位四元数
            alpha: 0.98,
        }
    }

    /// 更新姿态估计
    pub fn update(
        &mut self,
        gyro: &GyroscopeData,
        accel: &AccelerometerData,
        dt: f64,
    ) -> (f64, f64, f64) {
        // 简化的互补滤波

        // 从加速度计估计倾角
        let accel_pitch = accel.x.atan2(accel.z).to_degrees();
        let accel_roll = accel.y.atan2(accel.z).to_degrees();

        // 从陀螺仪积分得到倾角（简化）
        let gyro_pitch = self.get_pitch() + gyro.x * dt;
        let gyro_roll = self.get_roll() + gyro.y * dt;

        // 互补滤波融合
        let pitch = self.alpha * gyro_pitch + (1.0 - self.alpha) * accel_pitch;
        let roll = self.alpha * gyro_roll + (1.0 - self.alpha) * accel_roll;

        // 更新四元数（简化）
        self.update_quaternion(pitch, roll, gyro.z * dt);

        (pitch, roll, self.get_yaw())
    }

    fn get_pitch(&self) -> f64 {
        // 从四元数提取pitch
        let (_, x, y, z) = self.quaternion;
        (2.0 * (x * z - y)).asin().to_degrees()
    }

    fn get_roll(&self) -> f64 {
        let (w, x, y, z) = self.quaternion;
        (2.0 * (x * y + w * z)).atan2(1.0 - 2.0 * (y * y + z * z)).to_degrees()
    }

    fn get_yaw(&self) -> f64 {
        let (w, x, y, z) = self.quaternion;
        (2.0 * (y * z + w * x)).atan2(1.0 - 2.0 * (x * x + y * y)).to_degrees()
    }

    fn update_quaternion(&mut self, pitch: f64, roll: f64, yaw_delta: f64) {
        // 简化的四元数更新
        let half_pitch = pitch.to_radians() / 2.0;
        let half_roll = roll.to_radians() / 2.0;
        let half_yaw_delta = yaw_delta.to_radians() / 2.0;

        let (w, x, y, z) = self.quaternion;

        // 偏航旋转
        let dq = (
            half_yaw_delta.cos(),
            0.0,
            0.0,
            half_yaw_delta.sin(),
        );

        // 四元数乘法
        self.quaternion = (
            w * dq.0 - x * dq.1 - y * dq.2 - z * dq.3,
            w * dq.1 + x * dq.0 + y * dq.3 - z * dq.2,
            w * dq.2 - x * dq.3 + y * dq.0 + z * dq.1,
            w * dq.3 + x * dq.2 - y * dq.1 + z * dq.0,
        );

        // 归一化
        let mag = (self.quaternion.0.powi(2) + self.quaternion.1.powi(2)
            + self.quaternion.2.powi(2) + self.quaternion.3.powi(2)).sqrt();
        self.quaternion = (
            self.quaternion.0 / mag,
            self.quaternion.1 / mag,
            self.quaternion.2 / mag,
            self.quaternion.3 / mag,
        );
    }

    /// 重置姿态估计
    pub fn reset(&mut self) {
        self.quaternion = (1.0, 0.0, 0.0, 0.0);
    }
}

impl Default for AttitudeEstimator {
    fn default() -> Self {
        Self::new()
    }
}
