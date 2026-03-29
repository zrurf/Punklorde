//! 打卡点模块

use crate::services::core::pathfinding::astar::AStarPathfinder;
use crate::services::core::pathfinding::smoother::PathSmoother;
use crate::services::motion_sim::core::geo::fence::FenceManager;
use crate::services::motion_sim::model::{Checkpoint, GeoPoint};

/// 打卡点管理器
#[derive(Clone)]
pub struct WaypointManager {
    /// 打卡点列表（按顺序）
    checkpoints: Vec<Checkpoint>,
    /// 当前打卡点索引
    current_index: usize,
    /// 容忍距离（米）
    tolerance: f64,
    /// 是否自动规划路径
    auto_route: bool,
    /// 所有打卡是否完成
    all_completed: bool,
}

impl WaypointManager {
    pub fn new(checkpoints: Vec<Checkpoint>, tolerance: f64, auto_route: bool) -> Self {
        Self {
            checkpoints,
            current_index: 0,
            tolerance,
            auto_route,
            all_completed: false,
        }
    }

    /// 检查当前位置是否到达打卡点
    ///
    /// # 返回
    /// 如果到达打卡点，返回该打卡点；否则返回None
    pub fn check_arrival(&mut self, position: &GeoPoint) -> Option<&Checkpoint> {
        if self.all_completed || self.current_index >= self.checkpoints.len() {
            return None;
        }

        let checkpoint = &self.checkpoints[self.current_index];
        if checkpoint.is_in_range(position) {
            // 标记已打卡
            self.checkpoints[self.current_index].checked = true;
            let result = &self.checkpoints[self.current_index];

            // 移动到下一个打卡点
            self.current_index += 1;

            // 检查是否全部完成
            if self.current_index >= self.checkpoints.len() {
                self.all_completed = true;
            }

            return Some(result);
        }

        None
    }

    /// 获取下一个需要打卡的点
    pub fn get_next_checkpoint(&self) -> Option<&Checkpoint> {
        self.checkpoints.get(self.current_index)
    }

    /// 获取当前打卡点索引
    pub fn current_index(&self) -> usize {
        self.current_index
    }

    /// 获取打卡进度（0.0-1.0）
    pub fn progress(&self) -> f64 {
        if self.checkpoints.is_empty() {
            return 1.0;
        }
        self.current_index as f64 / self.checkpoints.len() as f64
    }

    /// 是否全部完成
    pub fn is_all_completed(&self) -> bool {
        self.all_completed
    }

    /// 添加打卡点
    pub fn add_checkpoint(&mut self, checkpoint: Checkpoint) {
        // 根据顺序插入到正确位置
        let pos = self.checkpoints.iter()
            .position(|c| c.sequence > checkpoint.sequence)
            .unwrap_or(self.checkpoints.len());
        self.checkpoints.insert(pos, checkpoint);
    }

    /// 移除打卡点
    pub fn remove_checkpoint(&mut self, id: &str) -> Option<Checkpoint> {
        if let Some(pos) = self.checkpoints.iter().position(|c| c.id == id) {
            if pos < self.current_index {
                self.current_index -= 1;
            }
            Some(self.checkpoints.remove(pos))
        } else {
            None
        }
    }

    /// 重置所有打卡状态
    pub fn reset(&mut self) {
        for checkpoint in &mut self.checkpoints {
            checkpoint.checked = false;
        }
        self.current_index = 0;
        self.all_completed = false;
    }

    /// 获取所有打卡点
    pub fn checkpoints(&self) -> &[Checkpoint] {
        &self.checkpoints
    }

    /// 获取未打卡的点
    pub fn get_remaining_checkpoints(&self) -> Vec<&Checkpoint> {
        self.checkpoints[self.current_index..].iter().collect()
    }

    /// 获取已完成的打卡数量
    pub fn completed_count(&self) -> usize {
        self.current_index
    }

    /// 获取总打卡点数量
    pub fn total_count(&self) -> usize {
        self.checkpoints.len()
    }
}

/// 打卡点路径规划器
pub struct WaypointRouter {
    /// 围栏管理器（用于避障）
    fence_manager: Option<FenceManager>,
    /// 路径平滑器
    smoother: PathSmoother,
    /// 平滑因子
    smooth_factor: f64,
    grid_resolution: f64,
}

impl WaypointRouter {
    pub fn new(
        fence_manager: Option<FenceManager>,
        smooth_factor: f64,
        grid_resolution: f64,
    ) -> Self {
        Self {
            fence_manager,
            smoother: PathSmoother::default(),
            smooth_factor,
            grid_resolution,
        }
    }

    /// 规划从当前位置经过打卡点再回到原轨迹的路径
    ///
    /// # 参数
    /// * `current_position` - 当前位置
    /// * `checkpoint` - 打卡点
    /// * `original_trajectory_point` - 原轨迹上打卡后要返回的点
    ///
    /// # 返回
    /// 经过打卡点的路径点列表
    pub fn plan_route(
        &self,
        current_position: &GeoPoint,
        checkpoint: &Checkpoint,
        original_trajectory_point: &GeoPoint,
    ) -> Vec<GeoPoint> {
        let mut route = Vec::new();

        let checkpoint_position = match (&checkpoint.point, &checkpoint.area) {
            (Some(point), _) => *point,
            (None, Some(area)) => area.centroid().unwrap_or(*current_position),
            (None, None) => return vec![],
        };

        if let Some(ref fence_manager) = self.fence_manager {
            let pathfinder = AStarPathfinder::new(
                fence_manager.geofence().cloned(),
                fence_manager.forbidden_zones().to_vec(),
                self.grid_resolution,
            );

            let path_to_checkpoint = pathfinder.find_path(current_position, &checkpoint_position);
            let path_from_checkpoint = pathfinder.find_path(&checkpoint_position, original_trajectory_point);

            match (path_to_checkpoint, path_from_checkpoint) {
                (Some(mut to), Some(mut from)) => {
                    to.pop(); // 移除重复的打卡点
                    to.append(&mut from);
                    route = to;
                }
                _ => {
                    route = self.fallback_route(current_position, &checkpoint_position, original_trajectory_point);
                }
            }
        } else {
            route = self.fallback_route(current_position, &checkpoint_position, original_trajectory_point);
        }

        if !route.is_empty() {
            route = self.smoother.smooth(&route);
        }

        // 添加打卡点附近的圆形路径
        if let Some(radius) = checkpoint.radius {
            let circle_points = self.generate_checkpoint_circle(&checkpoint_position, radius);
            if let Some(pos) = route.iter().position(|p| p.distance_to(&checkpoint_position) < radius * 2.0) {
                route.splice(pos..pos, circle_points);
            } else {
                route.extend(circle_points);
            }
        }

        route
    }

    ///  Fallback 路径生成
    fn fallback_route(&self, start: &GeoPoint, checkpoint: &GeoPoint, end: &GeoPoint) -> Vec<GeoPoint> {
        let mut route = Vec::new();
        route.extend(self.generate_smooth_path(start, checkpoint));
        route.extend(self.generate_smooth_path(checkpoint, end));
        route
    }

    /// 生成平滑路径（使用贝塞尔曲线）
    fn generate_smooth_path(&self, start: &GeoPoint, end: &GeoPoint) -> Vec<GeoPoint> {
        let distance = start.distance_to(end);

        // 根据距离决定点数
        let point_count = ((distance / 10.0).ceil() as usize).max(5);

        // 计算中间控制点（添加一些弯曲）
        let bearing = start.bearing_to(end);
        let perpendicular = (bearing + 90.0) % 360.0;

        let mid_distance = distance / 2.0;
        let curve_offset = distance * self.smooth_factor * 0.1;

        let mid_point = start.destination_point(bearing, mid_distance);
        let control_point = mid_point.destination_point(perpendicular, curve_offset);

        let mut path = Vec::with_capacity(point_count);
        path.push(*start);

        // 使用二次贝塞尔曲线
        for i in 1..point_count {
            let t = i as f64 / point_count as f64;
            let point = self.quadratic_bezier(start, &control_point, end, t);
            path.push(point);
        }

        path.push(*end);
        path
    }

    /// 二次贝塞尔曲线插值
    fn quadratic_bezier(&self, p0: &GeoPoint, p1: &GeoPoint, p2: &GeoPoint, t: f64) -> GeoPoint {
        let one_minus_t = 1.0 - t;

        let lat = one_minus_t * one_minus_t * p0.latitude
            + 2.0 * one_minus_t * t * p1.latitude
            + t * t * p2.latitude;

        let lon = one_minus_t * one_minus_t * p0.longitude
            + 2.0 * one_minus_t * t * p1.longitude
            + t * t * p2.longitude;

        GeoPoint {
            latitude: lat,
            longitude: lon,
            altitude: p0.altitude,
        }
    }

    /// 生成打卡点圆形路径
    fn generate_checkpoint_circle(&self, center: &GeoPoint, radius: f64) -> Vec<GeoPoint> {
        let mut points = Vec::new();
        let segment_count = 8;

        for i in 0..segment_count {
            let angle = (i as f64 / segment_count as f64) * 360.0;
            let point = center.destination_point(angle, radius * 0.5);
            points.push(point);
        }

        points
    }

    /// 根据围栏调整路径
    fn adjust_for_fence(&self, route: Vec<GeoPoint>, fence_manager: &FenceManager) -> Vec<GeoPoint> {
        let mut adjusted = Vec::new();

        for point in route {
            // 检查是否在禁跑区内
            let mut safe_point = point;
            for zone in fence_manager.forbidden_zones() {
                if zone.contains(&point) {
                    // 计算绕行点
                    if let Some(centroid) = zone.centroid() {
                        let bearing = centroid.bearing_to(&point);
                        safe_point = point.destination_point(bearing, 20.0);
                    }
                }
            }

            // 检查是否在电子围栏外
            if let Some(fence) = fence_manager.geofence() {
                if !fence.contains(&safe_point) {
                    if let Some(centroid) = fence.centroid() {
                        let bearing = safe_point.bearing_to(&centroid);
                        safe_point = safe_point.destination_point(bearing, 20.0);
                    }
                }
            }

            adjusted.push(safe_point);
        }

        adjusted
    }

    /// 设置平滑因子
    pub fn set_smooth_factor(&mut self, factor: f64) {
        self.smooth_factor = factor.clamp(0.0, 1.0);
    }
}

/// 打卡点距离计算
pub struct WaypointDistanceCalculator;

impl WaypointDistanceCalculator {
    /// 计算到下一个打卡点的距离
    pub fn distance_to_next(position: &GeoPoint, checkpoint: &Checkpoint) -> f64 {
        match (&checkpoint.point, &checkpoint.area) {
            (Some(point), _) => position.distance_to(point),
            (None, Some(area)) => {
                // 到区域边界的距离（如果在内部则为0）
                if area.contains(position) {
                    0.0
                } else {
                    area.distance_to_boundary(position)
                }
            }
            (None, None) => f64::MAX,
        }
    }

    /// 计算经过所有剩余打卡点的预估距离
    pub fn estimate_total_distance(
        position: &GeoPoint,
        remaining_checkpoints: &[&Checkpoint],
    ) -> f64 {
        if remaining_checkpoints.is_empty() {
            return 0.0;
        }

        let mut total = 0.0;
        let mut current_pos = *position;

        for checkpoint in remaining_checkpoints {
            if let Some(point) = &checkpoint.point {
                total += current_pos.distance_to(point);
                current_pos = *point;
            } else if let Some(area) = &checkpoint.area {
                if let Some(centroid) = area.centroid() {
                    total += current_pos.distance_to(&centroid);
                    current_pos = centroid;
                }
            }
        }

        total
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_waypoint_manager() {
        let checkpoints = vec![
            Checkpoint::point_checkpoint(0.001, 0.001, 10.0, 1),
            Checkpoint::point_checkpoint(0.002, 0.002, 10.0, 2),
        ];

        let mut manager = WaypointManager::new(checkpoints, 10.0, true);

        // 初始状态
        assert_eq!(manager.current_index(), 0);
        assert!(!manager.is_all_completed());

        // 到达第一个打卡点
        let pos = GeoPoint::new(0.001, 0.001);
        let arrived = manager.check_arrival(&pos);
        assert!(arrived.is_some());
        assert_eq!(manager.current_index(), 1);

        // 到达第二个打卡点
        let pos = GeoPoint::new(0.002, 0.002);
        let arrived = manager.check_arrival(&pos);
        assert!(arrived.is_some());
        assert!(manager.is_all_completed());
    }

    #[test]
    fn test_waypoint_router() {
        let router = WaypointRouter::new(None, 0.5, 10.0);

        let start = GeoPoint::new(0.0, 0.0);
        let checkpoint = Checkpoint::point_checkpoint(0.001, 0.001, 10.0, 1);
        let end = GeoPoint::new(0.002, 0.0);

        let route = router.plan_route(&start, &checkpoint, &end);

        assert!(!route.is_empty());
        // 路径应该经过打卡点附近
        let passes_checkpoint = route.iter().any(|p| {
            p.distance_to(checkpoint.point.as_ref().expect("Point is None")) < 20.0
        });
        assert!(passes_checkpoint);
    }

    #[test]
    fn test_waypoint_router_fallback_route() {
        let router = WaypointRouter::new(None, 0.5, 10.0);
        let start = GeoPoint::new(0.0, 0.0);
        let cp = GeoPoint::new(0.001, 0.001);
        let end = GeoPoint::new(0.002, 0.0);
        let route = router.fallback_route(&start, &cp, &end);
        assert!(route.len() >= 2);
    }
}
