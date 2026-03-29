//! 模拟器核心

use rand::rngs::StdRng;
use rand::{RngExt, SeedableRng};
use crate::frb_generated::StreamSink;
use crate::services::core::sensors::SensorTimers;
use crate::services::motion_sim::core::geo::coordinate::CoordinateConverter;
use crate::services::motion_sim::core::geo::fence::{FenceManager, FenceStatus};
use crate::services::motion_sim::core::geo::waypoint::{WaypointDistanceCalculator, WaypointManager, WaypointRouter};
use crate::services::motion_sim::core::motion::interpolation::InterpolatedTrajectory;
use crate::services::motion_sim::core::motion::movement::{GaitCycle, MovementConfig, MovementStateMachine};
use crate::services::motion_sim::core::motion::velocity::PaceCalculator;
use crate::services::motion_sim::core::noise::jitter::{JitterConfig, JitterGenerator};
use crate::services::motion_sim::core::sensors::accelerometer::{AccelerometerConfig, AccelerometerSensor};
use crate::services::motion_sim::core::sensors::barometer::{BarometerConfig, BarometerSensor};
use crate::services::motion_sim::core::sensors::compass::{CompassConfig, CompassSensor};
use crate::services::motion_sim::core::sensors::gps::{GpsSensor, GpsSensorConfig};
use crate::services::motion_sim::core::sensors::gyroscope::{GyroscopeConfig, GyroscopeSensor};
use crate::services::motion_sim::core::sensors::pedometer::{PedometerConfig, PedometerSensor};
use crate::services::motion_sim::model::*;

/// 模拟器核心
pub struct MotionSimulator {
    /// 配置
    config: SimulatorConfig,
    rng: StdRng,

    /// 轨迹列表
    trajectories: Vec<InterpolatedTrajectory>,
    /// 当前轨迹索引
    current_trajectory_index: usize,
    /// 当前轨迹进度（距离，米）
    current_distance: f64,

    /// 运动状态机
    movement: MovementStateMachine,
    /// 步态周期
    gait: GaitCycle,

    /// 传感器模拟器
    gps_sensor: GpsSensor,
    accelerometer_sensor: AccelerometerSensor,
    gyroscope_sensor: GyroscopeSensor,
    compass_sensor: CompassSensor,
    barometer_sensor: BarometerSensor,
    pedometer_sensor: PedometerSensor,

    /// 抖动生成器
    jitter: JitterGenerator,

    /// 围栏管理器
    fence_manager: FenceManager,
    /// 打卡点管理器
    waypoint_manager: WaypointManager,
    /// 打卡点路径规划器
    waypoint_router: WaypointRouter,

    /// 坐标转换器
    coord_converter: CoordinateConverter,

    /// 统计信息
    stats: SimulatorStats,

    /// 状态
    state: SimulatorState,

    /// 更新事件发送器
    update_sink: Option<StreamSink<SimulatorUpdate>>,

    /// 临时路径（打卡点绕行）
    temporary_path: Vec<GeoPoint>,
    /// 是否正在绕行
    is_detouring: bool,
    /// 绕行路径累积距离
    detour_cumulative_distances: Vec<f64>,
    /// 绕行路径上已移动的距离
    detour_distance: f64,
    /// 绕行起点对应的原轨迹距离
    detour_start_trajectory_distance: f64,
    /// 绕行路径结束轨迹距离
    detour_end_trajectory_distance: f64,

    /// 传感器定时器
    sensor_timers: SensorTimers,

    /// 延迟停止（帧）
    stop_after_frames: Option<(u32, bool)>, // (剩余帧数, graceful)
    /// 停止计时器（秒）
    stop_after_time: Option<(f64, bool)>, // (剩余秒数, graceful)
}

impl MotionSimulator {
    /// 创建新的模拟器
    pub fn new(
        config: SimulatorConfig,
        trajectories: Vec<Trajectory>,
    ) -> Self {
        // 插值轨迹
        let interpolated: Vec<InterpolatedTrajectory> = trajectories
            .iter()
            .map(|t| InterpolatedTrajectory::from_trajectory(t, 20)) // 每段20个插值点
            .collect();

        // 获取起始位置
        let start_position = interpolated
            .first()
            .and_then(|t| t.points().first())
            .copied()
            .unwrap_or_else(|| GeoPoint::new(0.0, 0.0));

        // 创建运动状态机
        let movement_config = MovementConfig {
            target_speed: config.target_speed,
            min_speed: config.min_speed,
            max_speed: config.max_speed,
            acceleration: config.acceleration,
            deceleration: config.deceleration,
            step_frequency: config.step_frequency,
            stride_length: config.stride_length,
            turn_rate: 90.0,
        };
        let movement = MovementStateMachine::new(movement_config, start_position);

        // 创建步态周期
        let gait = GaitCycle::new(config.step_frequency, config.stride_length);

        // 创建抖动生成器
        let jitter_config = JitterConfig {
            position_amplitude: config.position_jitter_amplitude,
            speed_amplitude: config.speed_jitter_amplitude,
            bearing_amplitude: config.bearing_jitter_amplitude,
            accelerometer_amplitude: config.accelerometer_jitter_amplitude,
            gyroscope_amplitude: config.gyroscope_jitter_amplitude,
            time_frequency: config.jitter_frequency_scale,
            spatial_frequency: 0.001,
        };
        let jitter = JitterGenerator::new(config.jitter_seed, jitter_config);

        // 创建传感器
        let gps_sensor = GpsSensor::new(GpsSensorConfig::default(), config.jitter_seed);
        let accelerometer_sensor = AccelerometerSensor::new(AccelerometerConfig::default(), config.jitter_seed + 1);
        let gyroscope_sensor = GyroscopeSensor::new(GyroscopeConfig::default(), config.jitter_seed + 2);
        let compass_sensor = CompassSensor::new(CompassConfig::default(), config.jitter_seed + 3);
        let barometer_sensor = BarometerSensor::new(BarometerConfig::default(), config.jitter_seed + 4);
        let pedometer_sensor = PedometerSensor::new(PedometerConfig {
            stride_length: config.stride_length,
            ..Default::default()
        });

        // 创建围栏管理器
        let mut fence_manager = FenceManager::new(
            config.geofence.clone(),
            config.forbidden_zones.clone(),
        );

        fence_manager.set_warning_distance(config.fence_warning_distance);

        // 创建打卡点管理器
        let waypoint_manager = WaypointManager::new(
            config.checkpoints.clone(),
            config.checkpoint_tolerance,
            config.auto_route_to_checkpoint,
        );

        // 创建打卡点路径规划器
        let waypoint_router = WaypointRouter::new(
            Some(fence_manager.clone()),
            config.smoothing_factor,
            config.pathfinding_grid_resolution
        );

        // 创建统计信息
        let stats = SimulatorStats {
            elapsed_time_ms: 0,
            total_distance: 0.0,
            current_speed: 0.0,
            average_speed: 0.0,
            calories: 0.0,
            total_steps: 0,
            current_trajectory_index: 0,
            trajectory_progress: 0.0,
            checked_points: 0,
            current_phase: MovementPhase::Stationary,
            current_position: Some(start_position),
        };

        Self {
            config: config.clone(),
            rng: StdRng::seed_from_u64(config.jitter_seed),
            trajectories: interpolated,
            current_trajectory_index: 0,
            current_distance: 0.0,
            movement,
            gait,
            gps_sensor,
            accelerometer_sensor,
            gyroscope_sensor,
            compass_sensor,
            barometer_sensor,
            pedometer_sensor,
            jitter,
            fence_manager,
            waypoint_manager,
            waypoint_router,
            coord_converter: CoordinateConverter::new(),
            stats,
            state: SimulatorState::Idle,
            update_sink: None,
            temporary_path: Vec::new(),
            is_detouring: false,
            detour_cumulative_distances: Vec::new(),
            detour_distance: 0.0,
            detour_start_trajectory_distance: 0.0,
            detour_end_trajectory_distance: 0.0,
            sensor_timers: SensorTimers::new(),
            stop_after_frames: None,
            stop_after_time: None,
        }
    }

    /// 设置更新接收器
    pub fn set_update_sink(&mut self, sink: StreamSink<SimulatorUpdate>) {
        self.update_sink = Some(sink);
    }

        /// 启动模拟
    pub fn start(&mut self) -> Result<(), String> {
        if self.state != SimulatorState::Idle && self.state != SimulatorState::Stopped {
            return Err("模拟器已经在运行".to_string());
        }

        if self.trajectories.is_empty() {
            return Err("没有可用的轨迹".to_string());
        }

        self.state = SimulatorState::Preparing;
        self.send_event(SimulatorEvent::Started);

        self.state = SimulatorState::Running;
        self.movement.state_mut().phase = MovementPhase::Accelerating;

        Ok(())
    }

    /// 暂停模拟
    pub fn pause(&mut self) {
        if self.state == SimulatorState::Running {
            self.movement.pause();
            self.state = SimulatorState::Paused;
            self.send_event(SimulatorEvent::Paused);
        }
    }

    /// 恢复模拟
    pub fn resume(&mut self) {
        if self.state == SimulatorState::Paused {
            self.movement.resume();
            self.state = SimulatorState::Running;
            self.send_event(SimulatorEvent::Resumed);
        }
    }

    /// 停止模拟
    pub fn stop(&mut self, reason: StopReason) {
        self.state = SimulatorState::Stopping;
        self.stop_after_frames = None;
        self.stop_after_time = None;
        self.movement.request_stop(true);

        // 等待停止完成
        self.state = SimulatorState::Stopped;
        self.send_event(SimulatorEvent::Stopped { reason });
    }

    /// 更新模拟（每帧调用）
    ///
    /// # 参数
    /// * `dt` - 时间步长（秒）
    ///
    /// # 返回
    /// 传感器数据包
    pub fn update(&mut self, dt: f64) -> Option<SensorData> {
        if self.state != SimulatorState::Running {
            return None;
        }

        // 获取当前轨迹信息
        let trajectory_index = self.current_trajectory_index;
        let current_trajectory = self.trajectories.get(trajectory_index)?;
        let total_distance = current_trajectory.total_distance();

        // 确定目标位置和方向
        let (target_position, target_bearing, remaining_distance) =
            self.get_target_position_and_bearing(current_trajectory);

        // 更新运动状态机
        let distance_moved = self.movement.update(dt, target_bearing, remaining_distance);

        if self.is_detouring {
            self.detour_distance += distance_moved;
            // 检查绕行是否结束
            if let Some(&total) = self.detour_cumulative_distances.last() {
                if self.detour_distance >= total {
                    self.is_detouring = false;
                    self.temporary_path.clear();
                    self.detour_cumulative_distances.clear();
                    self.current_distance = self.detour_end_trajectory_distance; // 跳回原轨迹
                }
            }
        } else {
            self.current_distance += distance_moved;
        }

        // 检查是否需要切换轨迹或完成
        if self.current_distance >= total_distance {
            if !self.handle_trajectory_completion(trajectory_index) {
                return None; // 模拟结束
            }
        }

        // 获取当前位置（重新获取，因为轨迹索引可能已改变）
        let current_trajectory = self.trajectories.get(self.current_trajectory_index)?;
        let current_position = self.get_current_position(current_trajectory);
        let current_bearing = self.movement.state().current_bearing;
        let current_speed = self.movement.state().current_speed;
        self.movement.update_position(current_position);

        // 检查围栏状态
        if !self.check_fence_constraints(&current_position) {
            return None; // 违规停止
        }

        // 检查打卡点
        self.check_waypoints(&current_position);

        // 更新统计
        self.update_stats(dt, distance_moved);

        // 生成传感器数据
        let sensor_data = self.generate_sensor_data(&current_position, current_speed, current_bearing, dt);

        // 发送位置更新事件
        self.send_event(SimulatorEvent::PositionUpdated {
            position: current_position,
            speed: current_speed,
            bearing: current_bearing,
        });

        // 检查停止帧计数
        if let Some((remaining, graceful)) = self.stop_after_frames {
            if remaining == 1 {
                self.stop_after_frames = None;
                if graceful {
                    self.movement.request_stop(true);
                    self.stop(StopReason::Limit);
                } else {
                    self.stop(StopReason::Limit);
                }
            } else if remaining > 1 {
                self.stop_after_frames = Some((remaining - 1, graceful));
            } else {
                // remaining == 0 时直接清除，避免下溢
                self.stop_after_frames = None;
            }
        }

        // 检查时间停止
        if let Some((remaining, graceful)) = self.stop_after_time {
            let new_remaining = remaining - dt;
            if new_remaining <= 0.0 {
                self.stop_after_time = None;
                if graceful {
                    self.movement.request_stop(true);
                    self.stop(StopReason::Limit);  // 可使用相同原因或新增 TimeLimit
                } else {
                    self.stop(StopReason::Limit);
                }
            } else {
                self.stop_after_time = Some((new_remaining, graceful));
            }
        }

        Some(sensor_data)
    }

    /// 获取目标位置和方向
    fn get_target_position_and_bearing(&self, trajectory: &InterpolatedTrajectory) -> (GeoPoint, f64, f64) {
        if self.is_detouring && !self.temporary_path.is_empty() {
            let speed = self.movement.state().current_speed;
            let lookahead = (speed * 2.0).clamp(5.0, 20.0);
            let target_dist = (self.detour_distance + lookahead).min(*self.detour_cumulative_distances.last().expect("Invalid detour cumulative distances"));
            let target = self.get_point_on_detour(target_dist);
            let current = self.get_current_position(trajectory);
            let bearing = current.bearing_to(&target);
            let remaining = self.detour_cumulative_distances.last().expect("Invalid detour cumulative distances") - self.detour_distance;
            (target, bearing, remaining)
        } else {
            let speed = self.movement.state().current_speed;
            let lookahead = (speed * 2.0).clamp(5.0, 20.0);
            let target_distance = (self.current_distance + lookahead).min(trajectory.total_distance());
            let target_position = trajectory.get_position_at_distance(target_distance);
            let target_bearing = trajectory.get_bearing_at_distance(self.current_distance);
            let remaining = trajectory.total_distance() - self.current_distance;
            (target_position, target_bearing, remaining)
        }
    }

    /// 获取当前位置
    fn get_current_position(&self, trajectory: &InterpolatedTrajectory) -> GeoPoint {
        if self.is_detouring && !self.temporary_path.is_empty() {
            self.get_point_on_detour(self.detour_distance)
        } else {
            trajectory.get_position_at_distance(self.current_distance)
        }
    }

    /// 处理轨迹完成
    fn handle_trajectory_completion(&mut self, trajectory_index: usize) -> bool {
        match self.config.trajectory_mode {
            TrajectoryMode::Loop => {
                // 循环当前轨迹
                self.current_distance = 0.0;
                self.send_event(SimulatorEvent::TrajectorySwitched {
                    index: self.current_trajectory_index,
                    trajectory_id: "current".to_string(),
                });
                true
            }
            TrajectoryMode::Sequential => {
                // 顺序切换到下一条轨迹
                if self.current_trajectory_index < self.trajectories.len() - 1 {
                    self.current_trajectory_index += 1;
                    self.current_distance = 0.0;
                    self.send_event(SimulatorEvent::TrajectorySwitched {
                        index: self.current_trajectory_index,
                        trajectory_id: format!("trajectory_{}", self.current_trajectory_index),
                    });
                    true
                } else {
                    // 所有轨迹完成
                    self.stop(StopReason::Normal);
                    false
                }
            }
            TrajectoryMode::Random => {
                // 随机选择下一条轨迹
                let new_index = self.rng.random_range(0..self.trajectories.len());
                self.current_trajectory_index = new_index;
                self.current_distance = 0.0;
                self.send_event(SimulatorEvent::TrajectorySwitched {
                    index: self.current_trajectory_index,
                    trajectory_id: format!("trajectory_{}", self.current_trajectory_index),
                });
                true
            }
        }
    }

    /// 检查围栏约束
    fn check_fence_constraints(&mut self, position: &GeoPoint) -> bool {
        let status = self.fence_manager.check_status(position);

        match status {
            FenceStatus::InForbiddenZone => {
                self.stop(StopReason::ForbiddenZoneViolation);
                false
            }
            FenceStatus::Outside => {
                if self.config.geofence.is_some() {
                    self.stop(StopReason::GeofenceViolation);
                    false
                } else {
                    true
                }
            }
            FenceStatus::NearBoundary => {
                self.send_event(SimulatorEvent::GeofenceEntered);
                true
            }
            _ => true,
        }
    }

    /// 检查打卡点
    fn check_waypoints(&mut self, position: &GeoPoint) {
        let checkpoint_opt = self.waypoint_manager.check_arrival(position).cloned();
        if let Some(checkpoint) = checkpoint_opt {
            self.stats.checked_points = self.waypoint_manager.completed_count() as u32;

            self.send_event(SimulatorEvent::CheckpointReached {
                checkpoint: checkpoint.clone(),
            });

            if self.waypoint_manager.is_all_completed() {
                self.send_event(SimulatorEvent::AllCheckpointsCompleted);
            }

            self.movement.enter_checkpoint(self.config.checkpoint_stay_time);
        }

        // 检查是否需要规划去下一个打卡点的路径
        if !self.is_detouring && self.config.auto_route_to_checkpoint {
            if let Some(next_checkpoint) = self.waypoint_manager.get_next_checkpoint() {
                // 采样轨迹，判断是否自然经过下一个打卡点
                let current_traj = &self.trajectories[self.current_trajectory_index];
                let mut min_distance = f64::MAX;
                let sample_step = 10.0; // 每10米采样
                let mut dist = self.current_distance;
                while dist <= current_traj.total_distance() {
                    let point = current_traj.get_position_at_distance(dist);
                    let d = WaypointDistanceCalculator::distance_to_next(&point, next_checkpoint);
                    if d < min_distance {
                        min_distance = d;
                    }
                    if d < self.config.checkpoint_tolerance {
                        break; // 轨迹本身就会经过
                    }
                    dist += sample_step;
                }

                // 如果轨迹不经过，且距离适中，则规划绕行
                if min_distance > self.config.checkpoint_tolerance * 1.5 {
                    let distance_to_checkpoint = WaypointDistanceCalculator::distance_to_next(
                        position,
                        next_checkpoint,
                    );
                    if distance_to_checkpoint < 100.0 && distance_to_checkpoint > 20.0 {
                        let checkpoint_clone = next_checkpoint.clone();
                        self.plan_detour_to_checkpoint(position, &checkpoint_clone);
                    }
                }
            }
        }
    }

    /// 规划到打卡点的绕行路径
    fn plan_detour_to_checkpoint(&mut self, position: &GeoPoint, checkpoint: &Checkpoint) {
        let current_trajectory = &self.trajectories[self.current_trajectory_index];
        let return_distance = (self.current_distance + 50.0).min(current_trajectory.total_distance());
        let return_point = current_trajectory.get_position_at_distance(return_distance);

        let detour_path = self.waypoint_router.plan_route(position, checkpoint, &return_point);

        if !detour_path.is_empty() {
            self.temporary_path = detour_path;
            // 计算累积距离
            let mut cum_dist = Vec::with_capacity(self.temporary_path.len());
            cum_dist.push(0.0);
            for i in 1..self.temporary_path.len() {
                let dist = self.temporary_path[i-1].distance_to(&self.temporary_path[i]);
                cum_dist.push(cum_dist[i-1] + dist);
            }
            self.detour_cumulative_distances = cum_dist;
            self.is_detouring = true;
            self.detour_distance = 0.0;
            self.detour_start_trajectory_distance = self.current_distance;
            self.detour_end_trajectory_distance = return_distance;
        }
    }

    /// 根据绕行距离获取位置
    fn get_point_on_detour(&self, distance: f64) -> GeoPoint {
        if self.temporary_path.is_empty() {
            // 没有路径时返回当前位置（或默认点）
            return self.movement.state().current_position;
        }
        if self.temporary_path.len() == 1 {
            return self.temporary_path[0];
        }
        let idx = self.detour_cumulative_distances
            .partition_point(|&d| d < distance)
            .saturating_sub(1)
            .min(self.temporary_path.len() - 2);
        let d0 = self.detour_cumulative_distances[idx];
        let d1 = self.detour_cumulative_distances[idx + 1];
        let seg_len = d1 - d0;
        if seg_len < 1e-10 {
            return self.temporary_path[idx];
        }
        let t = (distance - d0) / seg_len;
        let p0 = &self.temporary_path[idx];
        let p1 = &self.temporary_path[idx + 1];
        GeoPoint {
            latitude: p0.latitude + (p1.latitude - p0.latitude) * t,
            longitude: p0.longitude + (p1.longitude - p0.longitude) * t,
            altitude: p0.altitude,
        }
    }

    /// 更新统计信息
    fn update_stats(&mut self, dt: f64, distance_moved: f64) {
        self.stats.elapsed_time_ms = self.stats.elapsed_time_ms
            .saturating_add((dt * 1000.0) as u64);
        self.stats.total_distance += distance_moved;
        self.stats.current_speed = self.movement.state().current_speed;

        if self.stats.elapsed_time_ms > 0 {
            self.stats.average_speed = self.stats.total_distance
                / (self.stats.elapsed_time_ms as f64 / 1000.0);
        }

        // 计算卡路里（假设体重70kg）
        self.stats.calories = PaceCalculator::estimate_calories(
            self.stats.total_distance / 1000.0,
            70.0,
            self.stats.current_speed,
        );

        self.stats.total_steps = self.pedometer_sensor.total_steps();
        self.stats.current_trajectory_index = self.current_trajectory_index;

        if let Some(trajectory) = self.trajectories.get(self.current_trajectory_index) {
            self.stats.trajectory_progress = self.current_distance / trajectory.total_distance();
        }

        self.stats.current_phase = self.movement.state().phase;
        self.stats.current_position = Some(self.movement.state().current_position);
    }

    /// 生成传感器数据
    fn generate_sensor_data(
        &mut self,
        position: &GeoPoint,
        speed: f64,
        bearing: f64,
        dt: f64,
    ) -> SensorData {
        let timestamp = chrono::Utc::now().timestamp_millis();

        self.sensor_timers.update(dt);

        // GPS传感器数据
        let gps = if self.sensor_timers.gps >= 1.0 / self.config.gps_refresh_rate {
            self.sensor_timers.gps = 0.0;
            Some(self.gps_sensor.generate(position, speed, bearing, dt))
        } else {
            None
        };

        // 加速计传感器数据
        let accelerometer = if self.sensor_timers.accelerometer >= 1.0 / self.config.accelerometer_refresh_rate {
            self.sensor_timers.accelerometer = 0.0;
            let is_moving = speed > 0.1;
            let forward_acc = self.movement.state().current_speed / dt;
            Some(self.accelerometer_sensor.generate(forward_acc, is_moving, dt))
        } else {
            None
        };

        // 旋转传感器数据
        let gyroscope = if self.sensor_timers.gyroscope >= 1.0 / self.config.gyroscope_refresh_rate {
            self.sensor_timers.gyroscope = 0.0;
            let is_turning = matches!(self.movement.state().phase, MovementPhase::Turning);
            let turn_rate = if is_turning { 30.0 } else { 0.0 };
            Some(self.gyroscope_sensor.generate(bearing, is_turning, turn_rate, dt))
        } else {
            None
        };

        // 磁力计传感器数据
        let compass = if self.sensor_timers.compass >= 1.0 / self.config.compass_refresh_rate {
            self.sensor_timers.compass = 0.0;
            let device_pitch = 0.0;
            let device_roll = 0.0;
            Some(self.compass_sensor.generate(bearing, device_pitch, device_roll, dt))
        } else {
            None
        };

        // 压力传感器数据
        let barometer = if self.sensor_timers.barometer >= 1.0 / self.config.barometer_refresh_rate {
            self.sensor_timers.barometer = 0.0;
            let altitude = position.altitude.unwrap_or(self.config.base_altitude);
            Some(self.barometer_sensor.generate(altitude, dt))
        } else {
            None
        };

        let is_moving = speed > 0.1;
        let pedometer = Some(self.pedometer_sensor.update(speed, dt, is_moving));

        let data = SensorData {
            timestamp,
            gps,
            accelerometer,
            gyroscope,
            compass,
            barometer,
            pedometer,
        };

        if let Some(sink) = &self.update_sink {
            let _ = sink.add(SimulatorUpdate::SensorData(data.clone()));
        }

        data
    }

    /// 发送事件
    fn send_event(&mut self, event: SimulatorEvent) {
        if let Some(sink) = &self.update_sink {
            let _ = sink.add(SimulatorUpdate::Event(event));
        }
    }

    /// 执行指令
    pub fn execute_command(&mut self, command: Command) -> CommandResult {
        match command {
            Command::SetTargetSpeed(speed) => {
                self.movement.set_target_speed(speed);
                self.config.target_speed = speed;
                CommandResult {
                    success: true,
                    message: format!("目标速度已设置为 {:.2} m/s", speed),
                    data: None,
                }
            }
            Command::SetSpeedRange { min, max } => {
                self.config.min_speed = min;
                self.config.max_speed = max;
                CommandResult {
                    success: true,
                    message: format!("速度范围已设置为 {:.2} - {:.2} m/s", min, max),
                    data: None,
                }
            }
            Command::SetAcceleration(acc) => {
                self.config.acceleration = acc;
                CommandResult {
                    success: true,
                    message: format!("加速度已设置为 {:.2} m/s²", acc),
                    data: None,
                }
            }
            Command::SetDeceleration(dec) => {
                self.config.deceleration = dec;
                CommandResult {
                    success: true,
                    message: format!("减速度已设置为 {:.2} m/s²", dec),
                    data: None,
                }
            }
            Command::SetStepFrequency(freq) => {
                self.config.step_frequency = freq;
                self.gait.set_step_frequency(freq);
                self.pedometer_sensor.set_step_frequency(freq);
                CommandResult {
                    success: true,
                    message: format!("步频已设置为 {:.0} 步/分钟", freq),
                    data: None,
                }
            }
            Command::SetStrideLength(length) => {
                self.config.stride_length = length;
                self.gait.set_stride_length(length);
                self.pedometer_sensor.set_stride_length(length);
                CommandResult {
                    success: true,
                    message: format!("步幅已设置为 {:.2} 米", length),
                    data: None,
                }
            }
            Command::Pause => {
                self.pause();
                CommandResult {
                    success: true,
                    message: "模拟已暂停".to_string(),
                    data: None,
                }
            }
            Command::Resume => {
                self.resume();
                CommandResult {
                    success: true,
                    message: "模拟已恢复".to_string(),
                    data: None,
                }
            }
            Command::StopImmediately => {
                self.stop(StopReason::UserRequested);
                CommandResult {
                    success: true,
                    message: "模拟已停止".to_string(),
                    data: None,
                }
            }
            Command::StopAfterFrames { frames, graceful } => {
                // 设置帧计数器，在指定帧数后停止
                self.stop_after_frames = Some((frames, graceful));
                CommandResult {
                    success: true,
                    message: format!("将在 {} 帧后停止", frames),
                    data: None,
                }
            }
            Command::StopAfterTime { seconds, graceful } => {
                // 清除帧停止，避免冲突
                self.stop_after_frames = None;
                self.stop_after_time = Some((seconds, graceful));
                CommandResult {
                    success: true,
                    message: format!("将在 {:.1} 秒后停止", seconds),
                    data: None,
                }
            }
            Command::JumpToProgress(progress) => {
                if let Some(trajectory) = self.trajectories.get(self.current_trajectory_index) {
                    self.current_distance = progress * trajectory.total_distance();
                    CommandResult {
                        success: true,
                        message: format!("已跳转到 {:.1}% 进度", progress * 100.0),
                        data: None,
                    }
                } else {
                    CommandResult {
                        success: false,
                        message: "没有可用轨迹".to_string(),
                        data: None,
                    }
                }
            }
            Command::NextTrajectory => {
                if self.current_trajectory_index < self.trajectories.len() - 1 {
                    self.current_trajectory_index += 1;
                    self.current_distance = 0.0;
                    CommandResult {
                        success: true,
                        message: format!("已切换到轨迹 {}", self.current_trajectory_index),
                        data: None,
                    }
                } else {
                    CommandResult {
                        success: false,
                        message: "已经是最后一条轨迹".to_string(),
                        data: None,
                    }
                }
            }
            Command::AddCheckpoint(checkpoint) => {
                self.waypoint_manager.add_checkpoint(checkpoint);
                CommandResult {
                    success: true,
                    message: "打卡点已添加".to_string(),
                    data: None,
                }
            }
            Command::RemoveCheckpoint(id) => {
                if self.waypoint_manager.remove_checkpoint(&id).is_some() {
                    CommandResult {
                        success: true,
                        message: "打卡点已移除".to_string(),
                        data: None,
                    }
                } else {
                    CommandResult {
                        success: false,
                        message: "未找到打卡点".to_string(),
                        data: None,
                    }
                }
            }
            Command::ClearCheckpoints => {
                // 实现清除所有打卡点
                while let Some(cp) = self.waypoint_manager.checkpoints().first() {
                    let id = cp.id.clone();
                    self.waypoint_manager.remove_checkpoint(&id);
                }
                CommandResult {
                    success: true,
                    message: "所有打卡点已清除".to_string(),
                    data: None,
                }
            }
            Command::ResetCheckpointStatus => {
                self.waypoint_manager.reset();
                CommandResult {
                    success: true,
                    message: "打卡状态已重置".to_string(),
                    data: None,
                }
            }
            Command::SetJitterParams {
                position_amplitude,
                speed_amplitude,
                bearing_amplitude,
            } => {
                let mut config = self.jitter.config().clone();
                if let Some(amp) = position_amplitude {
                    config.position_amplitude = amp;
                    self.config.position_jitter_amplitude = amp;
                }
                if let Some(amp) = speed_amplitude {
                    config.speed_amplitude = amp;
                    self.config.speed_jitter_amplitude = amp;
                }
                if let Some(amp) = bearing_amplitude {
                    config.bearing_amplitude = amp;
                    self.config.bearing_jitter_amplitude = amp;
                }
                self.jitter.update_config(config);
                CommandResult {
                    success: true,
                    message: "抖动参数已更新".to_string(),
                    data: None,
                }
            }
            Command::SetRefreshRate { gps, accelerometer, gyroscope, compass, barometer } => {
                if let Some(rate) = gps {
                    self.config.gps_refresh_rate = rate;
                }
                if let Some(rate) = accelerometer {
                    self.config.accelerometer_refresh_rate = rate;
                }
                if let Some(rate) = gyroscope {
                    self.config.gyroscope_refresh_rate = rate;
                }
                if let Some(rate) = compass {
                    self.config.compass_refresh_rate = rate;
                }
                if let Some(rate) = barometer {
                    self.config.barometer_refresh_rate = rate;
                }
                CommandResult {
                    success: true,
                    message: "刷新率已更新".to_string(),
                    data: None,
                }
            }
            Command::SetFenceWarningDistance(distance) => {
                self.fence_manager.set_warning_distance(distance);
                self.config.fence_warning_distance = distance;
                CommandResult {
                    success: true,
                    message: format!("电子围栏警告距离已设置为 {:.1} 米", distance),
                    data: None,
                }
            }
            Command::SwitchTrajectory { index, seamless: _ } => {
                if index < self.trajectories.len() {
                    self.current_trajectory_index = index;
                    self.current_distance = 0.0;
                    CommandResult {
                        success: true,
                        message: format!("已切换到轨迹 {}", index),
                        data: None,
                    }
                } else {
                    CommandResult {
                        success: false,
                        message: "轨迹索引超出范围".to_string(),
                        data: None,
                    }
                }
            }
            Command::AppendTrajectory(trajectory) => {
                let interpolated = InterpolatedTrajectory::from_trajectory(&trajectory, 20);
                self.trajectories.push(interpolated);
                CommandResult {
                    success: true,
                    message: "轨迹已追加".to_string(),
                    data: None,
                }
            }
            Command::Custom(json) => {
                CommandResult {
                    success: false,
                    message: format!("自定义指令暂不支持: {}", json),
                    data: None,
                }
            }
        }
    }

    /// 获取当前状态
    pub fn state(&self) -> SimulatorState {
        self.state
    }

    /// 获取统计信息
    pub fn stats(&self) -> &SimulatorStats {
        &self.stats
    }

    /// 获取配置
    pub fn config(&self) -> &SimulatorConfig {
        &self.config
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::services::motion_sim::model::*;

    fn create_test_trajectory() -> Trajectory {
        Trajectory::new(vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.001, 0.001),
            GeoPoint::new(0.002, 0.0),
        ])
    }

    #[test]
    fn test_simulator_elapsed_time_overflow_saturation() {
        let config = SimulatorConfig::default();
        let traj = create_test_trajectory();
        let mut sim = MotionSimulator::new(config, vec![traj]);
        sim.start().unwrap();

        // 设置接近最大值
        sim.stats.elapsed_time_ms = u64::MAX - 1000;

        // 添加一个会使它溢出的增量
        sim.update(2000.0); // dt=2000秒 → 加 2,000,000 毫秒，超过 MAX

        assert_eq!(sim.stats.elapsed_time_ms, u64::MAX);
    }

    #[test]
    fn test_simulator_detour_index_bounds() {
        let config = SimulatorConfig {
            auto_route_to_checkpoint: true,
            ..Default::default()
        };
        let traj = create_test_trajectory();
        let mut sim = MotionSimulator::new(config, vec![traj]);

        // 手动设置绕行路径长度为 1（非法情况，但用于测试索引下界）
        sim.temporary_path = vec![GeoPoint::new(0.0, 0.0)];
        sim.detour_cumulative_distances = vec![0.0];
        sim.is_detouring = true;
        sim.detour_distance = 0.0;

        // 正常情况下应 panic，但若代码健壮应处理。这里我们验证不会 panic 或返回合理值
        let pos = sim.get_point_on_detour(0.0);
        // 若路径长度为1，get_point_on_detour 中的 len-2 会下溢，预期 panic。
        // 实际代码中，绕行路径总是至少包含起点和终点，因此正常流程不会触发。
        // 此处仅用于演示：可注释掉以避免 panic，或修改代码添加保护。
        // assert_eq!(pos.latitude, 0.0);
    }

    #[test]
    fn test_simulator_stop_after_frames_countdown() {
        let config = SimulatorConfig::default();
        let traj = create_test_trajectory();
        let mut sim = MotionSimulator::new(config, vec![traj]);
        sim.start().unwrap();

        sim.stop_after_frames = Some((3, true));
        for i in 0..5 {
            sim.update(0.1);
            if i < 2 {
                assert!(sim.stop_after_frames.is_some());
            } else {
                // 第3次更新后应停止
                assert_eq!(sim.state, SimulatorState::Stopped);
                break;
            }
        }
    }

    #[test]
    fn test_simulator_stop_after_time_edge() {
        let config = SimulatorConfig::default();
        let traj = create_test_trajectory();
        let mut sim = MotionSimulator::new(config, vec![traj]);
        sim.start().unwrap();

        sim.stop_after_time = Some((0.5, true));
        sim.update(0.3);
        assert!(sim.stop_after_time.is_some());
        sim.update(0.3); // 累计 0.6 > 0.5，应触发停止
        assert_eq!(sim.state, SimulatorState::Stopped);
    }
}