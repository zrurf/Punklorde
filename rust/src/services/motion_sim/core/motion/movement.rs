//! 运动状态机

use std::time::{Duration, Instant};
pub(crate) use crate::services::motion_sim::model::{GeoPoint, MovementPhase};

/// 运动状态
#[derive(Debug, Clone)]
pub struct MovementState {
    /// 当前运动阶段
    pub phase: MovementPhase,
    /// 当前速度（米/秒）
    pub current_speed: f64,
    /// 目标速度（米/秒）
    pub target_speed: f64,
    /// 当前方向（度）
    pub current_bearing: f64,
    /// 当前位置
    pub current_position: GeoPoint,
    /// 累计距离（米）
    pub total_distance: f64,
    /// 阶段开始时间
    pub phase_start_time: Instant,
    /// 已运行时间
    pub elapsed_time: Duration,
}

impl MovementState {
    pub fn new(start_position: GeoPoint, target_speed: f64) -> Self {
        Self {
            phase: MovementPhase::Stationary,
            current_speed: 0.0,
            target_speed,
            current_bearing: 0.0,
            current_position: start_position,
            total_distance: 0.0,
            phase_start_time: Instant::now(),
            elapsed_time: Duration::ZERO,
        }
    }
}

/// 运动状态机配置
#[derive(Debug, Clone)]
pub struct MovementConfig {
    /// 目标速度（米/秒）
    pub target_speed: f64,
    /// 最小速度（米/秒）
    pub min_speed: f64,
    /// 最大速度（米/秒）
    pub max_speed: f64,
    /// 加速度（米/秒²）
    pub acceleration: f64,
    /// 减速度（米/秒²）
    pub deceleration: f64,
    /// 步频（步/分钟）
    pub step_frequency: f64,
    /// 步幅（米）
    pub stride_length: f64,
    /// 转向速度（度/秒）
    pub turn_rate: f64,
}

impl Default for MovementConfig {
    fn default() -> Self {
        Self {
            target_speed: 2.5,
            min_speed: 0.5,
            max_speed: 5.0,
            acceleration: 0.5,
            deceleration: 0.8,
            step_frequency: 160.0,
            stride_length: 0.8,
            turn_rate: 90.0, // 每秒最多转90度
        }
    }
}

/// 运动状态机
pub struct MovementStateMachine {
    /// 配置
    config: MovementConfig,
    /// 当前状态
    state: MovementState,
    /// 剩余检查点时间（秒）
    checkpoint_remaining_time: f64,
    /// 是否暂停
    paused: bool,
    /// 是否请求停止
    stop_requested: bool,
    /// 停止类型
    stop_graceful: bool,
}

impl MovementStateMachine {
    pub fn new(config: MovementConfig, start_position: GeoPoint) -> Self {
        let state = MovementState::new(start_position, config.target_speed);
        Self {
            config,
            state,
            checkpoint_remaining_time: 0.0,
            paused: false,
            stop_requested: false,
            stop_graceful: true,
        }
    }

    /// 更新运动状态
    ///
    /// # 参数
    /// * `dt` - 时间步长（秒）
    /// * `target_bearing` - 目标方向（度）
    /// * `remaining_distance` - 剩余距离（米），用于减速判断
    ///
    /// # 返回
    /// 本时间步移动的距离（米）
    pub fn update(&mut self, dt: f64, target_bearing: f64, remaining_distance: f64) -> f64 {
        if self.paused {
            return 0.0;
        }

        // 先更新方向（转向逻辑已在 update_bearing 中，可能改变 phase）
        self.update_bearing(target_bearing, dt);

        // 处理打卡阶段计时
        if self.state.phase == MovementPhase::Checkpoint {
            if self.checkpoint_remaining_time > 0.0 {
                self.checkpoint_remaining_time -= dt;
                self.state.current_speed = 0.0;  // 静止
            } else {
                self.state.phase = MovementPhase::Accelerating;  // 恢复加速
            }
        }

        // 根据当前阶段调整速度
        match self.state.phase {
            MovementPhase::Stationary => {
                if !self.stop_requested {
                    self.state.phase = MovementPhase::Accelerating;
                    self.state.phase_start_time = Instant::now();
                }
            }
            MovementPhase::Accelerating => {
                self.state.current_speed += self.config.acceleration * dt;
                if self.state.current_speed >= self.state.target_speed {
                    self.state.current_speed = self.state.target_speed;
                    self.state.phase = MovementPhase::Cruising;
                    self.state.phase_start_time = Instant::now();
                }
            }
            MovementPhase::Cruising => {
                self.state.current_speed = self.state.target_speed;
                if self.stop_requested || self.should_decelerate(remaining_distance) {
                    self.state.phase = MovementPhase::Decelerating;
                    self.state.phase_start_time = Instant::now();
                }
            }
            MovementPhase::Decelerating => {
                self.state.current_speed -= self.config.deceleration * dt;
                if self.state.current_speed <= self.config.min_speed {
                    self.state.current_speed = self.config.min_speed;
                    if self.stop_requested && self.stop_graceful {
                        self.state.phase = MovementPhase::Stationary;
                        self.state.current_speed = 0.0;
                    } else if !self.should_decelerate(remaining_distance) {
                        self.state.phase = MovementPhase::Accelerating;
                    }
                }
            }
            MovementPhase::Turning => {
                // 转向时维持一个较低速度（如目标速度的70%）
                let turn_target_speed = self.config.target_speed * 0.7;
                if self.state.current_speed < turn_target_speed {
                    self.state.current_speed += self.config.acceleration * dt;
                    if self.state.current_speed > turn_target_speed {
                        self.state.current_speed = turn_target_speed;
                    }
                } else if self.state.current_speed > turn_target_speed {
                    self.state.current_speed -= self.config.deceleration * dt;
                    if self.state.current_speed < turn_target_speed {
                        self.state.current_speed = turn_target_speed;
                    }
                }
            }
            MovementPhase::Checkpoint => {
            }
        }

        // 速度限制
        self.state.current_speed = self.state.current_speed
            .clamp(self.config.min_speed, self.config.max_speed);

        let distance = self.state.current_speed * dt;
        self.state.total_distance += distance;
        self.state.elapsed_time += Duration::from_secs_f64(dt);

        distance
    }

    /// 进入打卡阶段
    ///
    /// # 参数
    /// * `duration` - 持续时间（秒）
    ///
    pub fn enter_checkpoint(&mut self, duration: f64) {
        self.state.phase = MovementPhase::Checkpoint;
        self.checkpoint_remaining_time = duration;
        self.state.current_speed = 0.0;
    }

    /// 更新方向（平滑转向）
    fn update_bearing(&mut self, target_bearing: f64, dt: f64) {
        let mut bearing_diff = target_bearing - self.state.current_bearing;

        // 标准化到[-180, 180]
        while bearing_diff > 180.0 {
            bearing_diff -= 360.0;
        }
        while bearing_diff < -180.0 {
            bearing_diff += 360.0;
        }

        // 检查是否需要进入转向状态
        if bearing_diff.abs() > 15.0 && self.state.phase == MovementPhase::Cruising {
            self.state.phase = MovementPhase::Turning;
            self.state.phase_start_time = Instant::now();
        }

        // 平滑转向
        let max_turn = self.config.turn_rate * dt;
        let turn = bearing_diff.clamp(-max_turn, max_turn);
        self.state.current_bearing = (self.state.current_bearing + turn + 360.0) % 360.0;

        // 检查是否转向完成
        if bearing_diff.abs() < 5.0 && self.state.phase == MovementPhase::Turning {
            self.state.phase = MovementPhase::Accelerating;
        }
    }

    /// 判断是否应该开始减速
    fn should_decelerate(&self, remaining_distance: f64) -> bool {
        // 计算从当前速度减速到最小速度需要的距离
        // v² = v0² + 2as => s = (v² - v0²) / (2a)
        let decel_distance = (self.state.current_speed.powi(2) - self.config.min_speed.powi(2))
            / (2.0 * self.config.deceleration);

        // 留一些余量
        remaining_distance <= decel_distance * 1.2
    }

    /// 请求停止
    pub fn request_stop(&mut self, graceful: bool) {
        self.stop_requested = true;
        self.stop_graceful = graceful;
    }

    /// 取消停止请求
    pub fn cancel_stop(&mut self) {
        self.stop_requested = false;
    }

    /// 暂停
    pub fn pause(&mut self) {
        self.paused = true;
    }

    /// 恢复
    pub fn resume(&mut self) {
        self.paused = false;
        if self.state.phase == MovementPhase::Stationary && !self.stop_requested {
            self.state.phase = MovementPhase::Accelerating;
        }
    }

    /// 设置目标速度
    pub fn set_target_speed(&mut self, speed: f64) {
        self.state.target_speed = speed.clamp(self.config.min_speed, self.config.max_speed);
        self.config.target_speed = self.state.target_speed;
    }

    /// 更新位置
    pub fn update_position(&mut self, position: GeoPoint) {
        self.state.current_position = position;
    }

    /// 获取当前状态
    pub fn state(&self) -> &MovementState {
        &self.state
    }

    /// 获取可变状态
    pub fn state_mut(&mut self) -> &mut MovementState {
        &mut self.state
    }

    /// 获取配置
    pub fn config(&self) -> &MovementConfig {
        &self.config
    }

    /// 更新配置
    pub fn update_config(&mut self, config: MovementConfig) {
        self.config = config;
        self.state.target_speed = self.config.target_speed;
    }

    /// 是否正在运行
    pub fn is_running(&self) -> bool {
        !self.paused && self.state.phase != MovementPhase::Stationary
    }

    /// 是否已停止
    pub fn is_stopped(&self) -> bool {
        self.state.phase == MovementPhase::Stationary && self.state.current_speed == 0.0
    }

    /// 是否暂停
    pub fn is_paused(&self) -> bool {
        self.paused
    }
}

/// 步态周期生成器
///
/// 模拟跑步/行走时的步态周期，用于生成加速度计数据
pub struct GaitCycle {
    /// 步频（步/分钟）
    pub step_frequency: f64,
    /// 步幅（米）
    pub stride_length: f64,
    /// 当前相位（0-1）
    pub phase: f64,
    /// 步态类型
    pub gait_type: GaitType,
}

/// 步态类型
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GaitType {
    /// 行走
    Walk,
    /// 慢跑
    Jog,
    /// 跑步
    Run,
    /// 冲刺
    Sprint,
}

impl GaitCycle {
    pub fn new(step_frequency: f64, stride_length: f64) -> Self {
        let gait_type = if step_frequency < 120.0 {
            GaitType::Walk
        } else if step_frequency < 160.0 {
            GaitType::Jog
        } else if step_frequency < 180.0 {
            GaitType::Run
        } else {
            GaitType::Sprint
        };

        Self {
            step_frequency,
            stride_length,
            phase: 0.0,
            gait_type,
        }
    }

    /// 更新步态周期
    pub fn update(&mut self, dt: f64) {
        // 每秒的周期数 = 步频 / 60
        let cycles_per_second = self.step_frequency / 60.0;
        self.phase += dt * cycles_per_second;
        self.phase = self.phase.fract();
    }

    /// 获取当前垂直加速度（模拟跑步时的上下震动）
    /// 返回值单位为g（重力加速度）
    pub fn get_vertical_acceleration(&self) -> f64 {
        match self.gait_type {
            GaitType::Walk => self.walk_vertical_acc(),
            GaitType::Jog => self.jog_vertical_acc(),
            GaitType::Run => self.run_vertical_acc(),
            GaitType::Sprint => self.sprint_vertical_acc(),
        }
    }

    /// 获取当前前后加速度
    pub fn get_forward_acceleration(&self) -> f64 {
        // 在步态周期中有微小的前后加速度变化
        (self.phase * std::f64::consts::TAU).sin() * 0.1
    }

    /// 获取当前左右加速度
    pub fn get_lateral_acceleration(&self) -> f64 {
        // 左右摇摆
        (self.phase * std::f64::consts::TAU * 0.5).sin() * 0.05
    }

    fn walk_vertical_acc(&self) -> f64 {
        // 行走：较小的垂直震动
        let t = self.phase * std::f64::consts::TAU;
        0.1 * (2.0 * t).sin() + 0.05 * t.cos()
    }

    fn jog_vertical_acc(&self) -> f64 {
        // 慢跑：中等垂直震动
        let t = self.phase * std::f64::consts::TAU;
        0.3 * (2.0 * t).sin() + 0.15 * t.cos()
    }

    fn run_vertical_acc(&self) -> f64 {
        // 跑步：较大的垂直震动
        let t = self.phase * std::f64::consts::TAU;
        let impact = if self.phase < 0.2 {
            // 落地冲击
            0.8 * (t / 0.2 * std::f64::consts::PI).sin()
        } else {
            0.0
        };
        0.5 * (2.0 * t).sin() + 0.2 * t.cos() + impact
    }

    fn sprint_vertical_acc(&self) -> f64 {
        // 冲刺：最大的垂直震动
        let t = self.phase * std::f64::consts::TAU;
        let impact = if self.phase < 0.15 {
            1.2 * (t / 0.15 * std::f64::consts::PI).sin()
        } else {
            0.0
        };
        0.7 * (2.0 * t).sin() + 0.3 * t.cos() + impact
    }

    /// 设置步频
    pub fn set_step_frequency(&mut self, frequency: f64) {
        self.step_frequency = frequency;
        self.gait_type = if frequency < 120.0 {
            GaitType::Walk
        } else if frequency < 160.0 {
            GaitType::Jog
        } else if frequency < 180.0 {
            GaitType::Run
        } else {
            GaitType::Sprint
        };
    }

    /// 设置步幅
    pub fn set_stride_length(&mut self, length: f64) {
        self.stride_length = length;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    #[test]
    fn test_movement_state_machine_stop_after_frames() {
        let config = MovementConfig {
            target_speed: 1.0,
            min_speed: 0.0,
            ..Default::default()
        };
        let start = GeoPoint::new(0.0, 0.0);
        let mut sm = MovementStateMachine::new(config, start);

        // 加速到巡航：需要 2 秒（20 次更新）
        for _ in 0..30 {
            sm.update(0.1, 0.0, 100.0);
        }
        assert_eq!(sm.state().phase, MovementPhase::Cruising);

        sm.request_stop(true);

        for _ in 0..20 {
            sm.update(0.1, 0.0, 100.0);
        }
        assert!(sm.is_stopped());
    }

    #[test]
    #[test]
    fn test_movement_state_machine_turning_phase() {
        let config = MovementConfig {
            turn_rate: 90.0,
            target_speed: 5.0,
            acceleration: 0.5,
            ..Default::default()
        };
        let target_speed = config.target_speed;
        let start = GeoPoint::new(0.0, 0.0);
        let mut sm = MovementStateMachine::new(config, start);

        // 加速到巡航
        for _ in 0..100 {
            sm.update(0.1, 0.0, 100.0);
        }
        assert_eq!(sm.state().phase, MovementPhase::Cruising);
        let cruising_speed = sm.state().current_speed;
        assert!((cruising_speed - 5.0).abs() < 0.01);

        // 触发大角度转向
        sm.update(0.1, 30.0, 100.0);
        assert_eq!(sm.state().phase, MovementPhase::Turning);

        // 持续更新直到转向完成（phase 变为 Accelerating）
        let mut turned_to_accel = false;
        for _ in 0..100 {  // 最多 100 步（10 秒），确保转向能完成
            sm.update(0.1, 30.0, 100.0);
            if sm.state().phase == MovementPhase::Accelerating {
                turned_to_accel = true;
                break;
            }
        }
        assert!(turned_to_accel, "转向完成后应进入加速阶段");

        // 验证转向后速度有所降低（但仍保持合理范围）
        let speed_after_turn = sm.state().current_speed;
        assert!(speed_after_turn < target_speed,
                "转向后速度应低于巡航速度，实际为 {:.2}", speed_after_turn);
        assert!(speed_after_turn > target_speed * 0.5,
                "转向后速度不应过低，实际为 {:.2}", speed_after_turn);

        // 继续更新直到进入巡航
        let mut accel_to_cruise = false;
        for _ in 0..100 {
            sm.update(0.1, 30.0, 100.0);
            if sm.state().phase == MovementPhase::Cruising {
                accel_to_cruise = true;
                break;
            }
        }
        assert!(accel_to_cruise, "加速后应进入巡航阶段");
        assert!((sm.state().current_speed - target_speed).abs() < 0.1);
    }

    #[test]
    fn test_gait_cycle_update_no_panic() {
        let mut gait = GaitCycle::new(160.0, 0.8);
        gait.update(0.01);
        gait.update(1000.0); // 长时间更新，相位应正常 wrap
        assert!(gait.phase >= 0.0 && gait.phase < 1.0);
    }
}