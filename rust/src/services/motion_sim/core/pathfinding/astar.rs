//! A*寻路算法实现

use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
use crate::services::motion_sim::model::{GeoPoint, Polygon};

/// 路径节点
#[derive(Debug, Clone)]
struct PathNode {
    /// 位置
    position: GeoPoint,
    /// 从起点到该节点的实际代价
    g_cost: f64,
    /// 从该节点到目标的估计代价
    h_cost: f64,
    /// 总代价 = g + h
    f_cost: f64,
    /// 父节点索引
    parent: Option<usize>,
    /// 节点索引
    index: usize,
}

impl PartialEq for PathNode {
    fn eq(&self, other: &Self) -> bool {
        self.f_cost == other.f_cost
    }
}

impl Eq for PathNode {}

impl PartialOrd for PathNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        // 最小堆（代价小的优先）
        other.f_cost.partial_cmp(&self.f_cost)
    }
}

impl Ord for PathNode {
    fn cmp(&self, other: &Self) -> Ordering {
        self.partial_cmp(other).unwrap_or(Ordering::Equal)
    }
}

/// A*寻路器
pub struct AStarPathfinder {
    /// 电子围栏
    geofence: Option<Polygon>,
    /// 禁跑区列表
    forbidden_zones: Vec<Polygon>,
    /// 网格分辨率（米）
    grid_resolution: f64,
    /// 最大搜索节点数
    max_nodes: usize,
}

impl AStarPathfinder {
    pub fn new(
        geofence: Option<Polygon>,
        forbidden_zones: Vec<Polygon>,
        grid_resolution: f64,
    ) -> Self {
        Self {
            geofence,
            forbidden_zones,
            grid_resolution,
            max_nodes: 10000,
        }
    }

    /// 寻找从起点到终点的路径
    ///
    /// # 参数
    /// * `start` - 起点
    /// * `goal` - 终点
    ///
    /// # 返回
    /// 路径点列表（包含起点和终点），如果找不到路径则返回None
    pub fn find_path(&self, start: &GeoPoint, goal: &GeoPoint) -> Option<Vec<GeoPoint>> {
        // 验证起点和终点
        if !self.is_valid_position(start) || !self.is_valid_position(goal) {
            return None;
        }

        // 如果直线可达，直接返回
        if self.is_direct_path_valid(start, goal) {
            return Some(vec![*start, *goal]);
        }

        // 使用A*算法搜索
        self.astar_search(start, goal)
    }

    /// A*算法搜索
    fn astar_search(&self, start: &GeoPoint, goal: &GeoPoint) -> Option<Vec<GeoPoint>> {
        let mut open_set = BinaryHeap::new();
        let mut closed_set = HashMap::new();
        let mut nodes = Vec::new();

        // 创建起始节点
        let start_node = PathNode {
            position: *start,
            g_cost: 0.0,
            h_cost: self.heuristic(start, goal),
            f_cost: 0.0,
            parent: None,
            index: 0,
        };

        let mut start_node = start_node;
        start_node.f_cost = start_node.g_cost + start_node.h_cost;

        open_set.push(start_node.clone());
        nodes.push(start_node);

        let mut iterations = 0;

        while let Some(current) = open_set.pop() {
            iterations += 1;

            // 限制搜索次数
            if iterations > self.max_nodes {
                break;
            }

            // 到达目标
            if current.position.distance_to(goal) < self.grid_resolution {
                return Some(self.reconstruct_path(&nodes, current.index));
            }

            // 已访问过
            let pos_key = self.position_to_key(&current.position);
            if closed_set.contains_key(&pos_key) {
                continue;
            }
            closed_set.insert(pos_key, current.index);

            // 扩展邻居节点
            for neighbor_pos in self.get_neighbors(&current.position) {
                let neighbor_key = self.position_to_key(&neighbor_pos);

                if closed_set.contains_key(&neighbor_key) {
                    continue;
                }

                if !self.is_valid_position(&neighbor_pos) {
                    continue;
                }

                let g_cost = current.g_cost + current.position.distance_to(&neighbor_pos);
                let h_cost = self.heuristic(&neighbor_pos, goal);
                let f_cost = g_cost + h_cost;

                let neighbor_node = PathNode {
                    position: neighbor_pos,
                    g_cost,
                    h_cost,
                    f_cost,
                    parent: Some(current.index),
                    index: nodes.len(),
                };

                nodes.push(neighbor_node.clone());
                open_set.push(neighbor_node.clone());
            }
        }

        None
    }

    /// 启发式函数（欧几里得距离）
    fn heuristic(&self, a: &GeoPoint, b: &GeoPoint) -> f64 {
        a.distance_to(b)
    }

    /// 获取邻居节点
    fn get_neighbors(&self, position: &GeoPoint) -> Vec<GeoPoint> {
        let mut neighbors = Vec::new();
        // 使用16个方向（22.5°步进）
        let num_directions = 16;
        for i in 0..num_directions {
            let angle = i as f64 * (360.0 / num_directions as f64);
            let neighbor = position.destination_point(angle, self.grid_resolution);
            neighbors.push(neighbor);
        }
        neighbors
    }

    /// 检查位置是否有效（在围栏内，不在禁跑区）
    fn is_valid_position(&self, position: &GeoPoint) -> bool {
        // 检查电子围栏
        if let Some(fence) = &self.geofence {
            if !fence.contains(position) {
                return false;
            }
        }

        // 检查禁跑区
        for zone in &self.forbidden_zones {
            if zone.contains(position) {
                return false;
            }
        }

        true
    }

    /// 检查直线路径是否有效
    fn is_direct_path_valid(&self, start: &GeoPoint, end: &GeoPoint) -> bool {
        let distance = start.distance_to(end);
        let steps = (distance / self.grid_resolution).ceil() as usize;

        for i in 1..steps {
            let t = i as f64 / steps as f64;
            let check_point = GeoPoint {
                latitude: start.latitude + (end.latitude - start.latitude) * t,
                longitude: start.longitude + (end.longitude - start.longitude) * t,
                altitude: start.altitude,
            };

            if !self.is_valid_position(&check_point) {
                return false;
            }
        }

        true
    }

    /// 位置转换为键（用于去重）
    fn position_to_key(&self, position: &GeoPoint) -> String {
        let lat_grid = (position.latitude * 10000.0).round() as i64;
        let lon_grid = (position.longitude * 10000.0).round() as i64;
        format!("{},{}", lat_grid, lon_grid)
    }

    /// 重建路径
    fn reconstruct_path(&self, nodes: &[PathNode], end_index: usize) -> Vec<GeoPoint> {
        let mut path = Vec::new();
        let mut current_index = Some(end_index);

        while let Some(index) = current_index {
            let node = &nodes[index];
            path.push(node.position);
            current_index = node.parent;
        }

        path.reverse();
        path
    }

    /// 设置网格分辨率
    pub fn set_grid_resolution(&mut self, resolution: f64) {
        self.grid_resolution = resolution;
    }

    /// 设置最大搜索节点数
    pub fn set_max_nodes(&mut self, max_nodes: usize) {
        self.max_nodes = max_nodes;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_direct_path() {
        let start = GeoPoint::new(0.0, 0.0);
        let end = GeoPoint::new(0.001, 0.001);

        let pathfinder = AStarPathfinder::new(None, vec![], 10.0);
        let path = pathfinder.find_path(&start, &end);

        assert!(path.is_some());
        let path = path.expect("Expected a path");
        assert_eq!(path.len(), 2);
    }

    #[test]
    fn test_path_with_obstacle() {
        // 创建一个禁跑区
        let forbidden = Polygon::new(vec![
            GeoPoint::new(0.0, 0.0005),
            GeoPoint::new(0.001, 0.0005),
            GeoPoint::new(0.001, 0.0015),
            GeoPoint::new(0.0, 0.0015),
        ]);

        let start = GeoPoint::new(0.0, 0.0);
        let end = GeoPoint::new(0.002, 0.0);

        let pathfinder = AStarPathfinder::new(None, vec![forbidden], 10.0);
        let path = pathfinder.find_path(&start, &end);

        // 应该找到绕过障碍物的路径
        assert!(path.is_some());
    }
}
