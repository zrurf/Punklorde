//! 指南针/磁力计传感器模拟

use crate::services::motion_sim::core::noise::jitter::{JitterConfig, JitterGenerator};
use crate::services::motion_sim::model::CompassData;

/// 磁力计传感器配置
#[derive(Debug, Clone)]
pub struct CompassConfig {
    /// 磁偏角（度）
    pub declination: f64,
    /// 本地磁场强度（微特斯拉）
    pub local_field_strength: f64,
    /// 噪声幅度（微特斯拉）
    pub noise_amplitude: f64,
}

impl Default for CompassConfig {
    fn default() -> Self {
        Self {
            declination: 5.0, // 中国大部分地区约5-8度
            local_field_strength: 50.0, // 约50μT
            noise_amplitude: 0.5,
        }
    }
}

/// 磁力计传感器模拟器
pub struct CompassSensor {
    config: CompassConfig,
    jitter: JitterGenerator,
    /// 硬铁偏移（设备本身的磁场干扰）
    hard_iron_offset: (f64, f64, f64),
    /// 软铁缩放（设备材料对磁场的扭曲）
    soft_iron_scale: (f64, f64, f64),
}

impl CompassSensor {
    pub fn new(config: CompassConfig, jitter_seed: u64) -> Self {
        let jitter_config = JitterConfig {
            ..Default::default()
        };

        Self {
            config,
            jitter: JitterGenerator::new(jitter_seed, jitter_config),
            hard_iron_offset: (0.0, 0.0, 0.0),
            soft_iron_scale: (1.0, 1.0, 1.0),
        }
    }

    /// 生成磁力计数据
    ///
    /// # 参数
    /// * `device_heading` - 设备朝向（度）
    /// * `device_pitch` - 设备俯仰角（度）
    /// * `device_roll` - 设备翻滚角（度）
    /// * `dt` - 时间步长（秒）
    pub fn generate(
        &mut self,
        device_heading: f64,
        device_pitch: f64,
        device_roll: f64,
        dt: f64,
    ) -> CompassData {
        self.jitter.update_time(dt);

        // 地磁场向量（北东地向）
        let field_strength = self.config.local_field_strength;
        let inclination = 60.0_f64.to_radians(); // 磁倾角，中国大部分地区约50-60度

        let north = field_strength * inclination.cos();
        let vertical = field_strength * inclination.sin();

        // 转换到设备坐标系
        let heading_rad = device_heading.to_radians();
        let pitch_rad = device_pitch.to_radians();
        let roll_rad = device_roll.to_radians();

        // 简化的坐标变换
        let (mx, my, mz) = self.transform_magnetic_field(
            north * heading_rad.cos(),
            north * heading_rad.sin(),
            vertical,
            pitch_rad,
            roll_rad,
        );

        // 添加硬铁偏移
        let mx = (mx + self.hard_iron_offset.0) * self.soft_iron_scale.0;
        let my = (my + self.hard_iron_offset.1) * self.soft_iron_scale.1;
        let mz = (mz + self.hard_iron_offset.2) * self.soft_iron_scale.2;

        // 添加噪声
        let noise_scale = self.config.noise_amplitude;
        let mx = mx + (self.jitter.noise2d(dt, 0.0) * noise_scale);
        let my = my + (self.jitter.noise2d(0.0, dt) * noise_scale);
        let mz = mz + (self.jitter.noise2d(dt, dt) * noise_scale);

        // 计算磁北方向
        let magnetic_heading = mx.atan2(my).to_degrees();
        let magnetic_heading = (magnetic_heading + 360.0) % 360.0;

        // 真北方向 = 磁北 + 磁偏角
        let true_heading = (magnetic_heading + self.config.declination + 360.0) % 360.0;

        CompassData {
            magnetic_heading,
            true_heading,
            declination: self.config.declination,
            magnetic_field_x: mx,
            magnetic_field_y: my,
            magnetic_field_z: mz,
        }
    }

    /// 变换磁场到设备坐标系
    fn transform_magnetic_field(
        &self,
        bx: f64,
        by: f64,
        bz: f64,
        pitch: f64,
        roll: f64,
    ) -> (f64, f64, f64) {
        // 简化的旋转矩阵
        let mx = bx * pitch.cos() + bz * pitch.sin();
        let my = bx * roll.sin() * pitch.sin() + by * roll.cos() - bz * roll.sin() * pitch.cos();
        let mz = -bx * roll.cos() * pitch.sin() + by * roll.sin() + bz * roll.cos() * pitch.cos();

        (mx, my, mz)
    }

    /// 设置磁偏角
    pub fn set_declination(&mut self, declination: f64) {
        self.config.declination = declination;
    }

    /// 设置硬铁偏移（校准用）
    pub fn set_hard_iron_offset(&mut self, offset: (f64, f64, f64)) {
        self.hard_iron_offset = offset;
    }

    /// 设置软铁缩放（校准用）
    pub fn set_soft_iron_scale(&mut self, scale: (f64, f64, f64)) {
        self.soft_iron_scale = scale;
    }

    /// 校准
    pub fn calibrate(&mut self) {
        // 实际校准需要旋转设备采集数据
        self.hard_iron_offset = (0.0, 0.0, 0.0);
        self.soft_iron_scale = (1.0, 1.0, 1.0);
    }

    /// 获取抖动生成器的引用
    fn generator(&self) -> &JitterGenerator {
        &self.jitter
    }
}
