//! GPS传感器模拟

use rand::rngs::StdRng;
use rand::{RngExt, SeedableRng};
use crate::services::motion_sim::core::noise::jitter::{JitterConfig, JitterGenerator};
use crate::services::motion_sim::core::noise::simplex::SimplexNoise;
use crate::services::motion_sim::model::{GeoPoint, GpsData};

/// GPS传感器配置
#[derive(Debug, Clone)]
pub struct GpsSensorConfig {
    /// 基础水平精度（米）
    pub base_horizontal_accuracy: f64,
    /// 基础垂直精度（米）
    pub base_vertical_accuracy: f64,
    /// 可见卫星数量范围
    pub satellite_count_range: (u8, u8),
    /// 信号丢失概率
    pub signal_loss_probability: f64,
}

impl Default for GpsSensorConfig {
    fn default() -> Self {
        Self {
            base_horizontal_accuracy: 5.0,
            base_vertical_accuracy: 10.0,
            satellite_count_range: (8, 16),
            signal_loss_probability: 0.001,
        }
    }
}

/// GPS传感器模拟器
pub struct GpsSensor {
    config: GpsSensorConfig,
    jitter: JitterGenerator,
    rng: StdRng,
    /// 上一次有效位置
    last_valid_position: Option<GeoPoint>,
    /// 卫星数量
    current_satellite_count: u8,
    /// 是否信号丢失
    signal_lost: bool,
}

impl GpsSensor {
    pub fn new(config: GpsSensorConfig, jitter_seed: u64) -> Self {
        let jitter_config = JitterConfig {
            position_amplitude: config.base_horizontal_accuracy,
            ..Default::default()
        };

        Self {
            config,
            jitter: JitterGenerator::new(jitter_seed, jitter_config),
            rng: StdRng::seed_from_u64(jitter_seed + 100),
            last_valid_position: None,
            current_satellite_count: 12,
            signal_lost: false,
        }
    }

    /// 生成GPS数据
    ///
    /// # 参数
    /// * `true_position` - 真实位置
    /// * `true_speed` - 真实速度（米/秒）
    /// * `true_bearing` - 真实方向（度）
    /// * `dt` - 时间步长（秒）
    pub fn generate(&mut self, true_position: &GeoPoint, true_speed: f64, true_bearing: f64, dt: f64) -> GpsData {
        // 更新抖动时间
        self.jitter.update_time(dt);

        // 更新卫星数量（模拟变化）
        self.update_satellite_count();

        // 检查信号丢失
        self.check_signal_loss();

        // 如果信号丢失，返回上一次有效位置或估算位置
        if self.signal_lost {
            return self.generate_lost_signal_data(true_position);
        }

        // 生成带抖动的位置
        let jittered_position = self.jitter.jitter_position(true_position);

        // 添加海拔抖动
        let jittered_altitude = true_position.altitude
            .map(|alt| self.jitter.jitter_altitude(alt));

        let position = GeoPoint {
            latitude: jittered_position.latitude,
            longitude: jittered_position.longitude,
            altitude: jittered_altitude,
        };

        // 更新上一次有效位置
        self.last_valid_position = Some(position);

        // 生成带抖动的速度和方向
        let speed = self.jitter.jitter_speed(true_speed);
        let bearing = self.jitter.jitter_bearing(true_bearing);

        // 计算精度（与卫星数量和速度相关）
        let accuracy_factor = 1.0 + (self.current_satellite_count as f64 / 12.0 - 1.0) * 0.5;
        let speed_factor = 1.0 + true_speed * 0.1; // 速度越快精度越低

        GpsData {
            position,
            speed,
            bearing,
            horizontal_accuracy: self.config.base_horizontal_accuracy * accuracy_factor * speed_factor,
            vertical_accuracy: self.config.base_vertical_accuracy * accuracy_factor * speed_factor,
            satellite_count: self.current_satellite_count,
        }
    }

    /// 更新卫星数量
    fn update_satellite_count(&mut self) {
        // 模拟卫星数量的缓慢变化
        let change = (self.jitter.noise2d(
            chrono::Utc::now().timestamp() as f64,
            0.0
        ) * 2.0) as i8;

        let new_count = (self.current_satellite_count as i8 + change).clamp(
            self.config.satellite_count_range.0 as i8,
            self.config.satellite_count_range.1 as i8,
        );
        self.current_satellite_count = new_count as u8;
    }

    /// 检查是否信号丢失
    fn check_signal_loss(&mut self) {
        // 简单的概率模型
        if self.signal_lost {
            if self.rng.random::<f64>() < 0.3 {
                self.signal_lost = false;
            }
        } else {
            // 信号丢失概率较低
            if self.rng.random::<f64>() < self.config.signal_loss_probability {
                self.signal_lost = true;
            }
        }
    }

    /// 生成信号丢失时的数据
    fn generate_lost_signal_data(&self, _true_position: &GeoPoint) -> GpsData {
        // 返回上一次有效位置，精度设为很低
        let position = self.last_valid_position.unwrap_or_else(|| GeoPoint::new(0.0, 0.0));

        GpsData {
            position,
            speed: 0.0,
            bearing: 0.0,
            horizontal_accuracy: 100.0, // 精度很差
            vertical_accuracy: 150.0,
            satellite_count: 0,
        }
    }

    /// 更新配置
    pub fn update_config(&mut self, config: GpsSensorConfig) {
        self.config = config;
    }

    /// 是否信号丢失
    pub fn is_signal_lost(&self) -> bool {
        self.signal_lost
    }

    /// 获取抖动生成器的引用（用于访问noise2d等内部方法）
    fn generator(&self) -> &JitterGenerator {
        &self.jitter
    }
}

/// GPS精度模拟器
///
/// 根据环境条件模拟GPS精度变化
pub struct GpsAccuracySimulator {
    /// 环境类型
    environment: Environment,
    /// 当前天气
    weather: Weather,
}

/// 环境类型
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Environment {
    /// 开阔地区
    OpenArea,
    /// 城市街道
    UrbanStreet,
    /// 高楼密集区
    UrbanCanyon,
    /// 室内
    Indoor,
    /// 森林
    Forest,
    /// 山区
    Mountain,
}

/// 天气条件
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Weather {
    /// 晴朗
    Clear,
    /// 多云
    Cloudy,
    /// 雨天
    Rainy,
    /// 大雨/暴风雨
    Stormy,
}

impl GpsAccuracySimulator {
    pub fn new(environment: Environment, weather: Weather) -> Self {
        Self { environment, weather }
    }

    /// 获取精度因子
    pub fn get_accuracy_factor(&self) -> f64 {
        let env_factor = match self.environment {
            Environment::OpenArea => 1.0,
            Environment::UrbanStreet => 1.5,
            Environment::UrbanCanyon => 3.0,
            Environment::Indoor => 10.0,
            Environment::Forest => 2.0,
            Environment::Mountain => 2.5,
        };

        let weather_factor = match self.weather {
            Weather::Clear => 1.0,
            Weather::Cloudy => 1.2,
            Weather::Rainy => 1.5,
            Weather::Stormy => 2.0,
        };

        env_factor * weather_factor
    }

    /// 设置环境
    pub fn set_environment(&mut self, environment: Environment) {
        self.environment = environment;
    }

    /// 设置天气
    pub fn set_weather(&mut self, weather: Weather) {
        self.weather = weather;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gps_large_time_no_panic() {
        let config = GpsSensorConfig::default();
        let mut gps = GpsSensor::new(config, 42);
        let pos = GeoPoint::new(0.0, 0.0);
        let _data = gps.generate(&pos, 0.0, 0.0, 0.1);
    }
}