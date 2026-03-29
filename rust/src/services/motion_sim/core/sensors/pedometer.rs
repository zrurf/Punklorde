//! 计步器模拟

use crate::services::motion_sim::model::PedometerData;

/// 计步器配置
#[derive(Debug, Clone)]
pub struct PedometerConfig {
    /// 步幅（米）
    pub stride_length: f64,
    /// 检测阈值
    pub detection_threshold: f64,
}

impl Default for PedometerConfig {
    fn default() -> Self {
        Self {
            stride_length: 0.75,
            detection_threshold: 0.5,
        }
    }
}

/// 计步器模拟器
pub struct PedometerSensor {
    config: PedometerConfig,
    /// 总步数
    total_steps: u64,
    /// 当前步频（步/分钟）
    current_step_frequency: f64,
    /// 当前步幅（米）
    current_stride_length: f64,
    /// 累计距离
    total_distance: f64,
    /// 步态周期相位
    gait_phase: f64,
    /// 步态周期计数器
    step_counter: f64,
}

impl PedometerSensor {
    pub fn new(config: PedometerConfig) -> Self {
        Self {
            config: config.clone(),
            total_steps: 0,
            current_step_frequency: 160.0,
            current_stride_length: config.stride_length,
            total_distance: 0.0,
            gait_phase: 0.0,
            step_counter: 0.0,
        }
    }

    /// 更新计步数据
    ///
    /// # 参数
    /// * `speed` - 当前速度（米/秒）
    /// * `dt` - 时间步长（秒）
    /// * `is_moving` - 是否正在移动
    pub fn update(&mut self, speed: f64, dt: f64, is_moving: bool) -> PedometerData {
        if is_moving && speed > 0.1 {
            // 计算步频（基于速度）
            // 步频 = 速度 / 步幅 * 60
            self.current_step_frequency = (speed / self.current_stride_length) * 60.0;
            self.current_step_frequency = self.current_step_frequency.clamp(100.0, 220.0);

            // 更新步态相位
            let steps_per_second = self.current_step_frequency / 60.0;
            self.gait_phase += steps_per_second * dt;

            // 检测是否完成一步
            if self.gait_phase >= 1.0 {
                let steps_completed = self.gait_phase.floor() as u64;
                self.total_steps += steps_completed;
                self.gait_phase = self.gait_phase.fract();

                // 更新累计距离
                self.total_distance += steps_completed as f64 * self.current_stride_length;
            }

            // 动态调整步幅（基于速度）
            // 步幅 = 速度 / (步频 / 60)
            self.current_stride_length = speed / steps_per_second;
            self.current_stride_length = self.current_stride_length.clamp(0.5, 1.5);
        }

        PedometerData {
            total_steps: self.total_steps,
            current_step_frequency: self.current_step_frequency,
            current_stride_length: self.current_stride_length,
            distance: self.total_distance,
        }
    }

    /// 设置步频
    pub fn set_step_frequency(&mut self, frequency: f64) {
        self.current_step_frequency = frequency.clamp(100.0, 220.0);
    }

    /// 设置步幅
    pub fn set_stride_length(&mut self, length: f64) {
        self.current_stride_length = length.clamp(0.4, 2.0);
        self.config.stride_length = self.current_stride_length;
    }

    /// 重置
    pub fn reset(&mut self) {
        self.total_steps = 0;
        self.total_distance = 0.0;
        self.gait_phase = 0.0;
    }

    /// 获取总步数
    pub fn total_steps(&self) -> u64 {
        self.total_steps
    }

    /// 获取累计距离
    pub fn total_distance(&self) -> f64 {
        self.total_distance
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pedometer_large_step_count() {
        let config = PedometerConfig::default();
        let mut ped = PedometerSensor::new(config);
        // 模拟超长运动，检查 total_steps 是否可能溢出 u64（实际测试不会）
        for _ in 0..1_000_000 {
            ped.update(3.0, 0.01, true);
        }
        // 仅验证函数不 panic
        assert!(ped.total_steps() > 0);
    }
}