//! 电子围栏与禁跑区模块

use std::collections::VecDeque;
use crate::services::motion_sim::model::{GeoPoint, Polygon};

/// 围栏状态
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FenceStatus {
    /// 在围栏内
    Inside,
    /// 在围栏外
    Outside,
    /// 在边界附近
    NearBoundary,
    /// 进入禁跑区
    InForbiddenZone,
}

/// 电子围栏管理器
#[derive(Clone)]
pub struct FenceManager {
    /// 电子围栏（必须在内部）
    geofence: Option<Polygon>,
    /// 禁跑区列表（必须在外部）
    forbidden_zones: Vec<Polygon>,
    /// 边界警告距离（米）
    warning_distance: f64,
    /// 最近的位置历史（用于预测）
    position_history: VecDeque<GeoPoint>,
    /// 历史记录长度
    history_length: usize,
}

impl FenceManager {
    pub fn new(geofence: Option<Polygon>, forbidden_zones: Vec<Polygon>) -> Self {
        Self {
            geofence,
            forbidden_zones,
            warning_distance: 50.0,
            position_history: VecDeque::with_capacity(10),
            history_length: 10,
        }
    }

    /// 检查当前位置的围栏状态
    pub fn check_status(&mut self, position: &GeoPoint) -> FenceStatus {
        // 更新位置历史
        self.position_history.push_back(*position);
        if self.position_history.len() > self.history_length {
            self.position_history.pop_front();
        }

        // 首先检查禁跑区
        for zone in &self.forbidden_zones {
            if zone.contains(position) {
                return FenceStatus::InForbiddenZone;
            }
        }

        // 检查电子围栏
        if let Some(fence) = &self.geofence {
            return if fence.contains(position) {
                // 检查是否接近边界
                let boundary_distance = fence.distance_to_boundary(position);
                if boundary_distance <= self.warning_distance {
                    return FenceStatus::NearBoundary;
                }
                FenceStatus::Inside
            } else {
                FenceStatus::Outside
            }
        }

        // 没有电子围栏限制，只在禁跑区外
        FenceStatus::Inside
    }

    /// 预测是否即将违规
    ///
    /// # 参数
    /// * `position` - 当前位置
    /// * `speed` - 当前速度（米/秒）
    /// * `bearing` - 当前方向（度）
    /// * `prediction_time` - 预测时间（秒）
    pub fn predict_violation(
        &self,
        position: &GeoPoint,
        speed: f64,
        bearing: f64,
        prediction_time: f64,
    ) -> Option<FenceViolation> {
        // 预测位置
        let distance = speed * prediction_time;
        let predicted_position = position.destination_point(bearing, distance);

        // 检查预测位置
        // 检查禁跑区
        for (i, zone) in self.forbidden_zones.iter().enumerate() {
            if zone.contains(&predicted_position) {
                return Some(FenceViolation::ForbiddenZone {
                    zone_index: i,
                    distance_to_boundary: zone.distance_to_boundary(position),
                });
            }
        }

        // 检查电子围栏
        if let Some(fence) = &self.geofence {
            if !fence.contains(&predicted_position) {
                return Some(FenceViolation::GeofenceExit {
                    distance_to_boundary: fence.distance_to_boundary(position),
                });
            }
        }

        None
    }

    /// 计算到最近边界的距离
    pub fn distance_to_boundary(&self, position: &GeoPoint) -> f64 {
        let mut min_distance = f64::MAX;

        // 电子围栏边界
        if let Some(fence) = &self.geofence {
            let dist = fence.distance_to_boundary(position);
            min_distance = min_distance.min(dist);
        }

        // 禁跑区边界
        for zone in &self.forbidden_zones {
            let dist = zone.distance_to_boundary(position);
            min_distance = min_distance.min(dist);
        }

        min_distance
    }

    /// 获取推荐的安全方向
    ///
    /// 当接近边界或禁跑区时，返回远离的方向
    pub fn get_safe_direction(&self, position: &GeoPoint) -> Option<f64> {
        // 检查禁跑区
        for zone in &self.forbidden_zones {
            if zone.contains(position) {
                // 在禁跑区内，返回朝向最近边界的方向
                return self.get_direction_to_boundary(position, zone);
            }
        }

        // 检查电子围栏
        if let Some(fence) = &self.geofence {
            let boundary_dist = fence.distance_to_boundary(position);
            if boundary_dist <= self.warning_distance {
                // 接近边界，返回朝向围栏中心的方向
                if let Some(centroid) = fence.centroid() {
                    return Some(position.bearing_to(&centroid));
                }
            }
        }

        None
    }

    /// 获取朝向最近边界的方向
    fn get_direction_to_boundary(&self, position: &GeoPoint, polygon: &Polygon) -> Option<f64> {
        let n = polygon.points.len();
        let mut min_dist = f64::MAX;
        let mut nearest_direction = 0.0;

        for i in 0..n {
            let p1 = &polygon.points[i];
            let p2 = &polygon.points[(i + 1) % n];

            // 计算到线段的方向
            let dist = Self::point_to_segment_distance_simple(position, p1, p2);
            if dist < min_dist {
                min_dist = dist;
                // 近似方向
                nearest_direction = position.bearing_to(p1);
            }
        }

        Some(nearest_direction)
    }

    /// 简化的点到线段距离
    fn point_to_segment_distance_simple(point: &GeoPoint, p1: &GeoPoint, p2: &GeoPoint) -> f64 {
        // 使用GeoPoint的distance_to方法简化计算
        point.distance_to(p1).min(point.distance_to(p2))
    }

    /// 设置警告距离
    pub fn set_warning_distance(&mut self, distance: f64) {
        self.warning_distance = distance;
    }

    /// 获取电子围栏
    pub fn geofence(&self) -> Option<&Polygon> {
        self.geofence.as_ref()
    }

    /// 获取禁跑区列表
    pub fn forbidden_zones(&self) -> &[Polygon] {
        &self.forbidden_zones
    }

    /// 添加禁跑区
    pub fn add_forbidden_zone(&mut self, zone: Polygon) {
        self.forbidden_zones.push(zone);
    }

    /// 移除禁跑区
    pub fn remove_forbidden_zone(&mut self, index: usize) -> Option<Polygon> {
        if index < self.forbidden_zones.len() {
            Some(self.forbidden_zones.remove(index))
        } else {
            None
        }
    }
}

/// 围栏违规类型
#[derive(Debug, Clone)]
pub enum FenceViolation {
    /// 离开电子围栏
    GeofenceExit {
        distance_to_boundary: f64,
    },
    /// 进入禁跑区
    ForbiddenZone {
        zone_index: usize,
        distance_to_boundary: f64,
    },
}

/// 避障路径规划器
pub struct ObstacleAvoider {
    /// 围栏管理器引用
    fence_manager: FenceManager,
    /// 避障距离（米）
    avoidance_distance: f64,
}

impl ObstacleAvoider {
    pub fn new(fence_manager: FenceManager) -> Self {
        Self {
            fence_manager,
            avoidance_distance: 30.0,
        }
    }

    /// 规划避障路径
    ///
    /// # 参数
    /// * `current_position` - 当前位置
    /// * `target_position` - 目标位置
    ///
    /// # 返回
    /// 避障后的中间点列表（不包含起点和终点）
    pub fn plan_avoidance_path(
        &self,
        current_position: &GeoPoint,
        target_position: &GeoPoint,
    ) -> Vec<GeoPoint> {
        let mut waypoints = Vec::new();
        let mut current = *current_position;
        let target = *target_position;

        // 简化的避障逻辑：检测路径上的障碍物，绕行
        let direct_distance = current.distance_to(&target);
        let steps = (direct_distance / 10.0).ceil() as usize; // 每10米检查一次

        for i in 1..steps {
            let progress = i as f64 / steps as f64;
            let check_point = self.interpolate_position(&current, &target, progress);

            // 检查这个点是否在禁跑区内
            let mut needs_avoidance = false;
            for zone in self.fence_manager.forbidden_zones() {
                if zone.contains(&check_point) {
                    needs_avoidance = true;

                    // 计算绕行点
                    if let Some(avoid_point) = self.calculate_avoid_point(&check_point, zone) {
                        waypoints.push(avoid_point);
                    }
                    break;
                }
            }

            if !needs_avoidance {
                // 检查电子围栏
                if let Some(fence) = self.fence_manager.geofence() {
                    if !fence.contains(&check_point) {
                        // 需要保持在围栏内
                        if let Some(avoid_point) = self.calculate_geofence_avoid_point(&check_point, fence) {
                            waypoints.push(avoid_point);
                        }
                    }
                }
            }
        }

        waypoints
    }

    /// 插值位置
    fn interpolate_position(&self, p1: &GeoPoint, p2: &GeoPoint, t: f64) -> GeoPoint {
        GeoPoint {
            latitude: p1.latitude + (p2.latitude - p1.latitude) * t,
            longitude: p1.longitude + (p2.longitude - p1.longitude) * t,
            altitude: p1.altitude,
        }
    }

    /// 计算绕过禁跑区的点
    fn calculate_avoid_point(&self, point: &GeoPoint, zone: &Polygon) -> Option<GeoPoint> {
        // 找到最近的边界点
        let centroid = zone.centroid()?;
        let bearing_from_center = centroid.bearing_to(point);

        // 沿该方向向外偏移
        let safe_point = point.destination_point(bearing_from_center, self.avoidance_distance);
        Some(safe_point)
    }

    /// 计算保持在围栏内的点
    fn calculate_geofence_avoid_point(&self, point: &GeoPoint, fence: &Polygon) -> Option<GeoPoint> {
        // 找到围栏中心，返回朝向中心的点
        let centroid = fence.centroid()?;
        let bearing_to_center = point.bearing_to(&centroid);
        let safe_point = point.destination_point(bearing_to_center, self.avoidance_distance);
        Some(safe_point)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fence_status() {
        // 创建一个简单的正方形围栏
        let fence = Polygon::new(vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.0, 0.01),
            GeoPoint::new(0.01, 0.01),
            GeoPoint::new(0.01, 0.0),
        ]);

        let mut manager = FenceManager::new(Some(fence), vec![]);

        // 内部点
        let inside = GeoPoint::new(0.005, 0.005);
        assert_eq!(manager.check_status(&inside), FenceStatus::Inside);

        // 外部点
        let outside = GeoPoint::new(0.02, 0.02);
        assert_eq!(manager.check_status(&outside), FenceStatus::Outside);
    }

    #[test]
    fn test_forbidden_zone() {
        let forbidden = Polygon::new(vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.0, 0.005),
            GeoPoint::new(0.005, 0.005),
            GeoPoint::new(0.005, 0.0),
        ]);

        let mut manager = FenceManager::new(None, vec![forbidden]);

        // 在禁跑区内
        let inside_forbidden = GeoPoint::new(0.002, 0.002);
        assert_eq!(manager.check_status(&inside_forbidden), FenceStatus::InForbiddenZone);

        // 在禁跑区外
        let outside = GeoPoint::new(0.01, 0.01);
        assert_eq!(manager.check_status(&outside), FenceStatus::Inside);
    }
}
