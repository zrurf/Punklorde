//! 加速度计传感器模拟

use rand::rngs::StdRng;
use rand::{RngExt, SeedableRng};
use crate::services::motion_sim::core::motion::movement::GaitCycle;
use crate::services::motion_sim::core::noise::jitter::{JitterConfig, JitterGenerator};
use crate::services::motion_sim::model::AccelerometerData;

/// 加速度计传感器配置
#[derive(Debug, Clone)]
pub struct AccelerometerConfig {
    /// 传感器量程（±g）
    pub range: f64,
    /// 分辨率
    pub resolution: f64,
    /// 噪声密度（μg/√Hz）
    pub noise_density: f64,
    /// 零偏稳定性
    pub bias_stability: f64,
}

impl Default for AccelerometerConfig {
    fn default() -> Self {
        Self {
            range: 16.0,        // ±16g
            resolution: 0.001,  // 0.001g
            noise_density: 100.0, // 100μg/√Hz
            bias_stability: 0.01,
        }
    }
}

/// 加速度计传感器模拟器
pub struct AccelerometerSensor {
    config: AccelerometerConfig,
    jitter: JitterGenerator,
    rng: StdRng,
    gait_cycle: GaitCycle,
    /// 零偏
    bias: (f64, f64, f64),
    /// 设备方向（相对于水平面的倾斜角度，度）
    device_tilt: (f64, f64, f64), // (pitch, roll, yaw)
}

impl AccelerometerSensor {
    pub fn new(config: AccelerometerConfig, jitter_seed: u64) -> Self {
        let jitter_config = JitterConfig {
            accelerometer_amplitude: config.noise_density * 0.001, // 转换为g
            ..Default::default()
        };
        
        let mut rng = StdRng::seed_from_u64(jitter_seed + 1);

        // 初始化零偏（模拟传感器误差）
        let bias = (
            (rng.random::<f64>() - 0.5) * config.bias_stability,
            (rng.random::<f64>() - 0.5) * config.bias_stability,
            (rng.random::<f64>() - 0.5) * config.bias_stability,
        );

        Self {
            config,
            jitter: JitterGenerator::new(jitter_seed, jitter_config),
            rng,
            gait_cycle: GaitCycle::new(160.0, 0.8),
            bias,
            device_tilt: (0.0, 0.0, 0.0), // 默认水平放置
        }
    }

    /// 生成加速度计数据
    ///
    /// # 参数
    /// * `forward_acceleration` - 前进加速度（m/s²）
    /// * `is_moving` - 是否正在移动
    /// * `dt` - 时间步长（秒）
    pub fn generate(&mut self, forward_acceleration: f64, is_moving: bool, dt: f64) -> AccelerometerData {
        // 更新抖动时间
        self.jitter.update_time(dt);

        // 更新步态周期
        if is_moving {
            self.gait_cycle.update(dt);
        }

        // 计算基础加速度
        let (mut ax, mut ay, mut az) = if is_moving {
            // 运动时的加速度
            let vertical = self.gait_cycle.get_vertical_acceleration();
            let forward = self.gait_cycle.get_forward_acceleration();
            let lateral = self.gait_cycle.get_lateral_acceleration();

            // 转换到设备坐标系
            self.transform_to_device_frame(forward, lateral, vertical + 1.0) // +1.0 是重力
        } else {
            // 静止时只有重力
            self.transform_to_device_frame(0.0, 0.0, 1.0)
        };

        // 添加前进加速度（假设手机朝向前进方向）
        ax += forward_acceleration / 9.81; // 转换为g

        // 添加零偏
        ax += self.bias.0;
        ay += self.bias.1;
        az += self.bias.2;

        // 添加噪声
        let (jx, jy, jz) = self.jitter.jitter_accelerometer(0.0, 0.0, 0.0);
        ax += jx;
        ay += jy;
        az += jz;

        // 限制在量程范围内
        ax = ax.clamp(-self.config.range, self.config.range);
        ay = ay.clamp(-self.config.range, self.config.range);
        az = az.clamp(-self.config.range, self.config.range);

        // 应用分辨率
        ax = (ax / self.config.resolution).round() * self.config.resolution;
        ay = (ay / self.config.resolution).round() * self.config.resolution;
        az = (az / self.config.resolution).round() * self.config.resolution;

        AccelerometerData { x: ax, y: ay, z: az }
    }

    /// 转换到设备坐标系
    fn transform_to_device_frame(&self, forward: f64, lateral: f64, vertical: f64) -> (f64, f64, f64) {
        let pitch = self.device_tilt.0.to_radians();
        let roll = self.device_tilt.1.to_radians();

        // 简化的旋转矩阵
        let ax = forward * pitch.cos() + vertical * pitch.sin();
        let ay = lateral * roll.cos() + vertical * pitch.sin() * roll.sin();
        let az = vertical * pitch.cos() * roll.cos() - lateral * roll.sin();

        (ax, ay, az)
    }

    /// 设置设备方向
    pub fn set_device_orientation(&mut self, pitch: f64, roll: f64, yaw: f64) {
        self.device_tilt = (pitch, roll, yaw);
    }

    /// 设置步态参数
    pub fn set_gait_params(&mut self, step_frequency: f64, stride_length: f64) {
        self.gait_cycle.set_step_frequency(step_frequency);
        self.gait_cycle.set_stride_length(stride_length);
    }

    /// 更新配置
    pub fn update_config(&mut self, config: AccelerometerConfig) {
        self.config = config;
    }

    /// 校准（移除零偏）
    pub fn calibrate(&mut self) {
        // 模拟校准过程
        self.bias = (0.0, 0.0, 0.0);
    }
}

/// 运动检测器
///
/// 从加速度计数据中检测运动状态
pub struct MotionDetector {
    /// 检测阈值（g）
    threshold: f64,
    /// 历史数据窗口
    history: Vec<AccelerometerData>,
    /// 窗口大小
    window_size: usize,
}

impl MotionDetector {
    pub fn new(threshold: f64) -> Self {
        Self {
            threshold,
            history: Vec::new(),
            window_size: 10,
        }
    }

    /// 添加数据并检测运动
    pub fn detect(&mut self, data: &AccelerometerData) -> MotionType {
        // 移除重力分量（假设z轴平均值为重力）
        self.history.push(data.clone());
        if self.history.len() > self.window_size {
            self.history.remove(0);
        }

        // 计算加速度变化
        let magnitude = data.magnitude();
        let gravity = 1.0; // 简化假设

        // 动态加速度（去除重力）
        let dynamic_acc = (magnitude - gravity).abs();

        if dynamic_acc < self.threshold * 0.1 {
            MotionType::Stationary
        } else if dynamic_acc < self.threshold {
            MotionType::Walking
        } else if dynamic_acc < self.threshold * 2.0 {
            MotionType::Running
        } else {
            MotionType::Shaking
        }
    }

    /// 设置检测阈值
    pub fn set_threshold(&mut self, threshold: f64) {
        self.threshold = threshold;
    }
}

/// 运动类型
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotionType {
    /// 静止
    Stationary,
    /// 行走
    Walking,
    /// 跑步
    Running,
    /// 剧烈晃动
    Shaking,
}
