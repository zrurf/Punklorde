//! 速度模型

use super::movement::MovementPhase;

/// 速度变化模式
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VelocityPattern {
    /// 恒定速度
    Constant,
    /// 正弦波动
    Sinusoidal,
    /// 随机波动
    Random,
    /// 间歇训练（快慢交替）
    Interval,
    /// 疲劳模型（逐渐减速）
    Fatigue,
}

/// 速度模型配置
#[derive(Debug, Clone)]
pub struct VelocityModelConfig {
    /// 基准速度（米/秒）
    pub base_speed: f64,
    /// 速度波动幅度（比例）
    pub variation_amplitude: f64,
    /// 波动周期（秒）
    pub variation_period: f64,
    /// 速度变化模式
    pub pattern: VelocityPattern,
    /// 间歇训练：快跑时间（秒）
    pub interval_fast_duration: f64,
    /// 间歇训练：慢跑时间（秒）
    pub interval_slow_duration: f64,
    /// 间歇训练：快跑速度比例
    pub interval_fast_ratio: f64,
    /// 疲劳模型：每小时速度衰减率
    pub fatigue_rate: f64,
}

impl Default for VelocityModelConfig {
    fn default() -> Self {
        Self {
            base_speed: 2.5,
            variation_amplitude: 0.1,
            variation_period: 30.0,
            pattern: VelocityPattern::Sinusoidal,
            interval_fast_duration: 60.0,
            interval_slow_duration: 120.0,
            interval_fast_ratio: 1.3,
            fatigue_rate: 0.05, // 每小时衰减5%
        }
    }
}

/// 速度模型
pub struct VelocityModel {
    config: VelocityModelConfig,
    /// 当前时间（秒）
    current_time: f64,
    /// 间歇训练状态
    interval_is_fast: bool,
    interval_phase_time: f64,
    /// 疲劳累积
    fatigue_factor: f64,
}

impl VelocityModel {
    pub fn new(config: VelocityModelConfig) -> Self {
        Self {
            config,
            current_time: 0.0,
            interval_is_fast: true,
            interval_phase_time: 0.0,
            fatigue_factor: 1.0,
        }
    }

    /// 更新并获取当前速度
    ///
    /// # 参数
    /// * `dt` - 时间步长（秒）
    /// * `phase` - 当前运动阶段
    ///
    /// # 返回
    /// 目标速度（米/秒）
    pub fn update(&mut self, dt: f64, phase: MovementPhase) -> f64 {
        self.current_time += dt;

        // 更新疲劳因子
        let hours = self.current_time / 3600.0;
        self.fatigue_factor = (1.0 - self.config.fatigue_rate * hours).max(0.7);

        // 根据运动阶段调整
        let base = match phase {
            MovementPhase::Stationary => return 0.0,
            MovementPhase::Accelerating => self.config.base_speed * 0.5,
            MovementPhase::Decelerating => self.config.base_speed * 0.5,
            MovementPhase::Turning => self.config.base_speed * 0.7,
            MovementPhase::Checkpoint => self.config.base_speed * 0.3,
            MovementPhase::Cruising => self.calculate_cruise_speed(),
        };

        base * self.fatigue_factor
    }

    /// 计算巡航速度
    fn calculate_cruise_speed(&self) -> f64 {
        match self.config.pattern {
            VelocityPattern::Constant => self.config.base_speed,

            VelocityPattern::Sinusoidal => {
                let t = self.current_time / self.config.variation_period * std::f64::consts::TAU;
                let variation = t.sin() * self.config.variation_amplitude;
                self.config.base_speed * (1.0 + variation)
            }

            VelocityPattern::Random => {
                // 使用简单的伪随机
                let noise = ((self.current_time * 7.3).sin() * 13.5).sin();
                let variation = noise * self.config.variation_amplitude;
                self.config.base_speed * (1.0 + variation * 0.5)
            }

            VelocityPattern::Interval => {
                let cycle_time = if self.interval_is_fast {
                    self.config.interval_fast_duration
                } else {
                    self.config.interval_slow_duration
                };

                let phase_in_cycle = self.current_time % (self.config.interval_fast_duration + self.config.interval_slow_duration);
                let is_fast = phase_in_cycle < self.config.interval_fast_duration;

                if is_fast {
                    self.config.base_speed * self.config.interval_fast_ratio
                } else {
                    self.config.base_speed * 0.7
                }
            }

            VelocityPattern::Fatigue => {
                self.config.base_speed * self.fatigue_factor
            }
        }
    }

    /// 设置基准速度
    pub fn set_base_speed(&mut self, speed: f64) {
        self.config.base_speed = speed;
    }

    /// 设置速度变化模式
    pub fn set_pattern(&mut self, pattern: VelocityPattern) {
        self.config.pattern = pattern;
    }

    /// 重置模型
    pub fn reset(&mut self) {
        self.current_time = 0.0;
        self.interval_is_fast = true;
        self.interval_phase_time = 0.0;
        self.fatigue_factor = 1.0;
    }

    /// 获取当前配置
    pub fn config(&self) -> &VelocityModelConfig {
        &self.config
    }

    /// 更新配置
    pub fn update_config(&mut self, config: VelocityModelConfig) {
        self.config = config;
    }
}

/// 配速计算工具
pub struct PaceCalculator;

impl PaceCalculator {
    /// 将速度（米/秒）转换为配速（分/公里）
    pub fn speed_to_pace(speed_mps: f64) -> f64 {
        if speed_mps <= 0.0 {
            return f64::INFINITY;
        }
        1000.0 / speed_mps / 60.0
    }

    /// 将配速（分/公里）转换为速度（米/秒）
    pub fn pace_to_speed(pace_min_per_km: f64) -> f64 {
        if pace_min_per_km <= 0.0 {
            return 0.0;
        }
        1000.0 / (pace_min_per_km * 60.0)
    }

    /// 格式化配速为 MM:SS 格式
    pub fn format_pace(pace_min_per_km: f64) -> String {
        let minutes = pace_min_per_km.floor() as u32;
        let seconds = ((pace_min_per_km - minutes as f64) * 60.0).round() as u32;
        format!("{:02}:{:02}", minutes, seconds)
    }

    /// 估算卡路里消耗
    ///
    /// # 参数
    /// * `distance_km` - 距离（公里）
    /// * `weight_kg` - 体重（公斤）
    /// * `speed_mps` - 速度（米/秒）
    pub fn estimate_calories(distance_km: f64, weight_kg: f64, speed_mps: f64) -> f64 {
        // MET值估算
        let met = if speed_mps < 1.4 {
            2.0 // 慢走
        } else if speed_mps < 2.0 {
            3.5 // 正常走
        } else if speed_mps < 2.8 {
            5.0 // 快走
        } else if speed_mps < 3.3 {
            8.0 // 慢跑
        } else if speed_mps < 4.2 {
            10.0 // 跑步
        } else if speed_mps < 5.0 {
            12.5 // 快跑
        } else {
            15.0 // 冲刺
        };

        // 卡路里 = MET × 体重 × 时间
        let hours = distance_km / (speed_mps * 3.6);
        met * weight_kg * hours
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pace_conversion() {
        // 速度 2.78 m/s ≈ 10 km/h，配速应为 6:00/km
        let speed = 10.0 / 3.6;
        let pace = PaceCalculator::speed_to_pace(speed);
        assert!((pace - 6.0).abs() < 0.01);

        let back = PaceCalculator::pace_to_speed(6.0);
        assert!((back - speed).abs() < 0.01);
    }

    #[test]
    fn test_velocity_model_constant() {
        let config = VelocityModelConfig {
            pattern: VelocityPattern::Constant,
            base_speed: 3.0,
            ..Default::default()
        };
        let mut model = VelocityModel::new(config);

        let v1 = model.update(0.1, MovementPhase::Cruising);
        let v2 = model.update(1.0, MovementPhase::Cruising);

        assert!((v1 - 3.0).abs() < 0.01);
        assert!((v2 - 3.0).abs() < 0.01);
    }

    #[test]
    fn test_velocity_model_sinusoidal() {
        let config = VelocityModelConfig {
            pattern: VelocityPattern::Sinusoidal,
            base_speed: 3.0,
            variation_amplitude: 0.2,
            variation_period: 10.0,
            ..Default::default()
        };
        let mut model = VelocityModel::new(config);

        // 在半个周期后速度应该有变化
        let _ = model.update(5.0, MovementPhase::Cruising);
        let v = model.update(0.1, MovementPhase::Cruising);

        // 速度应该在 3.0 * (1 - 0.2) 到 3.0 * (1 + 0.2) 之间
        assert!(v >= 2.4 && v <= 3.6);
    }
}
