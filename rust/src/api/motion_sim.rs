use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use anyhow::Result;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use uuid::Uuid;

use crate::frb_generated::StreamSink;
use crate::services::motion_sim::model::*;
use crate::services::simulator::MotionSimulator;

// 重新导出常用类型，方便Flutter导入
pub use crate::services::motion_sim::model::{
    AccelerometerData, BarometerData, Checkpoint, Command, CommandResult, CompassData,
    GeoPoint, GpsData, GyroscopeData, MovementPhase, PedometerData, SensorData,
    SimulatorConfig, SimulatorEvent, SimulatorState, SimulatorStats, StopReason,
    Trajectory, TrajectoryMode,
};
pub use crate::services::motion_sim::model::SimulatorUpdate; // 确保此枚举已定义

// 全局模拟器存储：句柄ID -> 模拟器实例
type SimulatorMap = Arc<Mutex<HashMap<String, Arc<Mutex<MotionSimulator>>>>>;

lazy_static! {
    static ref SIMULATORS: SimulatorMap = Arc::new(Mutex::new(HashMap::new()));
}

/// 创建模拟器，返回句柄ID（字符串）
#[frb(sync)]
pub fn create_simulator(
    config: SimulatorConfig,
    trajectories: Vec<Trajectory>,
) -> Result<String, String> {
    let simulator = MotionSimulator::new(config, trajectories);
    let handle_id = Uuid::new_v4().to_string();
    let mut map = SIMULATORS.lock().map_err(|_| "Mutex poisoned")?;
    map.insert(handle_id.clone(), Arc::new(Mutex::new(simulator)));
    Ok(handle_id)
}

/// 订阅模拟器的数据流，返回 Dart Stream<SimulatorUpdate>
#[frb(stream_dart_await)]
pub fn subscribe_simulator(
    handle_id: String,
    sink: StreamSink<SimulatorUpdate>,
) -> Result<(), String> {
    let map = SIMULATORS.lock().map_err(|_| "Mutex poisoned")?;
    let simulator_arc = map.get(&handle_id).ok_or("Simulator not found")?;
    let mut simulator = simulator_arc.lock().map_err(|_| "Mutex poisoned")?;
    simulator.set_update_sink(sink);
    Ok(())
}

/// 启动模拟器
#[frb(sync)]
pub fn start_simulator(handle_id: String) -> Result<(), String> {
    let map = SIMULATORS.lock().map_err(|_| "Mutex poisoned")?;
    let simulator_arc = map.get(&handle_id).ok_or("Simulator not found")?;
    let mut simulator = simulator_arc.lock().map_err(|_| "Mutex poisoned")?;
    simulator.start()
}

/// 暂停模拟器
#[frb(sync)]
pub fn pause_simulator(handle_id: String) {
    if let Ok(map) = SIMULATORS.lock() {
        if let Some(simulator_arc) = map.get(&handle_id) {
            if let Ok(mut simulator) = simulator_arc.lock() {
                simulator.pause();
            }
        }
    }
}

/// 恢复模拟器
#[frb(sync)]
pub fn resume_simulator(handle_id: String) {
    if let Ok(map) = SIMULATORS.lock() {
        if let Some(simulator_arc) = map.get(&handle_id) {
            if let Ok(mut simulator) = simulator_arc.lock() {
                simulator.resume();
            }
        }
    }
}

/// 停止模拟器
#[frb(sync)]
pub fn stop_simulator(handle_id: String, reason: StopReason) {
    if let Ok(map) = SIMULATORS.lock() {
        if let Some(simulator_arc) = map.get(&handle_id) {
            if let Ok(mut simulator) = simulator_arc.lock() {
                simulator.stop(reason);
            }
        }
    }
}

/// 更新模拟器（每帧调用）
#[frb(sync)]
pub fn update_simulator(handle_id: String, dt: f64) -> Option<SensorData> {
    let map = SIMULATORS.lock().ok()?;
    let simulator_arc = map.get(&handle_id)?;
    let mut simulator = simulator_arc.lock().ok()?;
    simulator.update(dt)
}

/// 执行指令
#[frb(sync)]
pub fn execute_command(handle_id: String, command: Command) -> CommandResult {
    let map = match SIMULATORS.lock() {
        Ok(map) => map,
        Err(_) => {
            return CommandResult {
                success: false,
                message: "Mutex poisoned".to_string(),
                data: None,
            }
        }
    };
    let simulator_arc = match map.get(&handle_id) {
        Some(arc) => arc,
        None => {
            return CommandResult {
                success: false,
                message: "Simulator not found".to_string(),
                data: None,
            }
        }
    };
    let mut simulator = match simulator_arc.lock() {
        Ok(sim) => sim,
        Err(_) => {
            return CommandResult {
                success: false,
                message: "Mutex poisoned".to_string(),
                data: None,
            }
        }
    };
    simulator.execute_command(command)
}

/// 获取模拟器状态
#[frb(sync)]
pub fn get_state(handle_id: String) -> Option<SimulatorState> {
    let map = SIMULATORS.lock().ok()?;
    let simulator_arc = map.get(&handle_id)?;
    let simulator = simulator_arc.lock().ok()?;
    Some(simulator.state())
}

/// 获取统计信息
#[frb(sync)]
pub fn get_stats(handle_id: String) -> Option<SimulatorStats> {
    let map = SIMULATORS.lock().ok()?;
    let simulator_arc = map.get(&handle_id)?;
    let simulator = simulator_arc.lock().ok()?;
    Some(simulator.stats().clone())
}

/// 获取配置
#[frb(sync)]
pub fn get_config(handle_id: String) -> Option<SimulatorConfig> {
    let map = SIMULATORS.lock().ok()?;
    let simulator_arc = map.get(&handle_id)?;
    let simulator = simulator_arc.lock().ok()?;
    Some(simulator.config().clone())
}

/// 释放模拟器（从全局map中移除）
#[frb(sync)]
pub fn dispose_simulator(handle_id: String) -> Result<(), String> {
    let mut map = SIMULATORS.lock().map_err(|_| "Mutex poisoned")?;
    map.remove(&handle_id);
    Ok(())
}