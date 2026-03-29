//! 气压计传感器模拟

use crate::services::motion_sim::core::noise::jitter::{JitterConfig, JitterGenerator};
use crate::services::motion_sim::core::noise::simplex::SimplexNoise;
use crate::services::motion_sim::model::BarometerData;

/// 气压计传感器配置
#[derive(Debug, Clone)]
pub struct BarometerConfig {
    /// 海平面气压（百帕）
    pub sea_level_pressure: f64,
    /// 分辨率（百帕）
    pub resolution: f64,
    /// 噪声幅度（百帕）
    pub noise_amplitude: f64,
    /// 温度（摄氏度），用于高度计算
    pub temperature: f64,
}

impl Default for BarometerConfig {
    fn default() -> Self {
        Self {
            sea_level_pressure: 1013.25,
            resolution: 0.01,
            noise_amplitude: 0.1,
            temperature: 15.0,
        }
    }
}

/// 气压计传感器模拟器
pub struct BarometerSensor {
    config: BarometerConfig,
    jitter: JitterGenerator,
    /// 基准气压（用于相对海拔计算）
    reference_pressure: f64,
    /// 气压变化趋势
    pressure_trend: f64,
}

impl BarometerSensor {
    pub fn new(config: BarometerConfig, jitter_seed: u64) -> Self {
        let jitter_config = JitterConfig {
            ..Default::default()
        };
        let reference_pressure = config.sea_level_pressure;

        Self {
            config,
            jitter: JitterGenerator::new(jitter_seed, jitter_config),
            reference_pressure,
            pressure_trend: 0.0,
        }
    }

    /// 生成气压计数据
    ///
    /// # 参数
    /// * `true_altitude` - 真实海拔（米）
    /// * `dt` - 时间步长（秒）
    pub fn generate(&mut self, true_altitude: f64, dt: f64) -> BarometerData {
        self.jitter.update_time(dt);

        // 更新气压趋势（模拟天气变化）
        self.update_pressure_trend(dt);

        // 使用气压公式计算气压
        // P = P0 * (1 - L*h/T0)^(g*M/R*T0)
        // 简化为：P = P0 * exp(-Mgh/RT)
        let m = 0.02896; // 空气摩尔质量 kg/mol
        let g = 9.81;    // 重力加速度 m/s²
        let r = 8.314;   // 气体常数 J/(mol·K)
        let t = self.config.temperature + 273.15; // 开尔文

        let pressure = self.config.sea_level_pressure * (-m * g * true_altitude / (r * t)).exp();

        // 添加天气趋势影响
        let pressure = pressure + self.pressure_trend;

        // 添加噪声
        let noisy_pressure = self.jitter.jitter_pressure(pressure);

        // 应用分辨率
        let quantized_pressure = (noisy_pressure / self.config.resolution).round() * self.config.resolution;

        // 计算相对海拔
        let relative_altitude = self.pressure_to_altitude(quantized_pressure)
            - self.pressure_to_altitude(self.reference_pressure);

        BarometerData {
            pressure: quantized_pressure,
            relative_altitude,
        }
    }

    /// 气压转海拔
    fn pressure_to_altitude(&self, pressure: f64) -> f64 {
        // 使用国际标准大气模型
        let p0 = self.config.sea_level_pressure;
        let t0 = 288.15; // 15°C in Kelvin
        let l = 0.0065;  // 温度递减率 K/m

        // h = T0/L * (1 - (P/P0)^(RL/gM))
        t0 / l * (1.0 - (pressure / p0).powf(0.1903))
    }

    /// 更新气压趋势
    fn update_pressure_trend(&mut self, dt: f64) {
        let noise = SimplexNoise::new(42);
        let t = chrono::Utc::now().timestamp_millis() as f64 / 3600000.0; // 小时为单位

        // 每小时变化约 0.1-0.5 hPa
        let change = noise.noise2d(t, 0.0) * 0.3;
        self.pressure_trend = self.pressure_trend * 0.95 + change * 0.05;
    }

    /// 设置参考气压（校准用）
    pub fn set_reference_pressure(&mut self, pressure: f64) {
        self.reference_pressure = pressure;
    }

    /// 设置温度
    pub fn set_temperature(&mut self, temperature: f64) {
        self.config.temperature = temperature;
    }

    /// 获取当前参考气压
    pub fn reference_pressure(&self) -> f64 {
        self.reference_pressure
    }
}

/// 高度变化检测器
pub struct AltitudeChangeDetector {
    /// 历史气压数据
    pressure_history: Vec<f64>,
    /// 窗口大小
    window_size: usize,
    /// 变化阈值（百帕）
    threshold: f64,
}

impl AltitudeChangeDetector {
    pub fn new(threshold: f64) -> Self {
        Self {
            pressure_history: Vec::new(),
            window_size: 10,
            threshold,
        }
    }

    /// 添加气压数据并检测变化
    pub fn detect(&mut self, pressure: f64) -> AltitudeChange {
        self.pressure_history.push(pressure);
        if self.pressure_history.len() > self.window_size {
            self.pressure_history.remove(0);
        }

        if self.pressure_history.len() < self.window_size {
            return AltitudeChange::Stable;
        }

        let first_half: f64 = self.pressure_history[..self.window_size / 2].iter().sum::<f64>()
            / (self.window_size / 2) as f64;
        let second_half: f64 = self.pressure_history[self.window_size / 2..].iter().sum::<f64>()
            / (self.window_size - self.window_size / 2) as f64;

        let diff = second_half - first_half;

        if diff > self.threshold {
            AltitudeChange::Descending // 气压上升 = 海拔下降
        } else if diff < -self.threshold {
            AltitudeChange::Ascending // 气压下降 = 海拔上升
        } else {
            AltitudeChange::Stable
        }
    }
}

/// 高度变化类型
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AltitudeChange {
    /// 稳定
    Stable,
    /// 上升
    Ascending,
    /// 下降
    Descending,
}
