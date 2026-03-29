//! 路径平滑模块

use crate::services::motion_sim::model::GeoPoint;

/// 路径平滑器配置
#[derive(Debug, Clone)]
pub struct PathSmootherConfig {
    /// 平滑度（0.0-1.0）
    pub smoothness: f64,
    /// 最小路径点间距（米）
    pub min_point_distance: f64,
    /// 最大曲率（度/米）
    pub max_curvature: f64,
}

impl Default for PathSmootherConfig {
    fn default() -> Self {
        Self {
            smoothness: 0.8,
            min_point_distance: 5.0,
            max_curvature: 45.0,
        }
    }
}

/// 路径平滑器
pub struct PathSmoother {
    config: PathSmootherConfig,
}

impl PathSmoother {
    pub fn new(config: PathSmootherConfig) -> Self {
        Self { config }
    }

    /// 平滑路径
    ///
    /// # 参数
    /// * `path` - 原始路径
    ///
    /// # 返回
    /// 平滑后的路径
    pub fn smooth(&self, path: &[GeoPoint]) -> Vec<GeoPoint> {
        if path.len() < 3 {
            return path.to_vec();
        }

        // 第一步：简化路径（移除冗余点）
        let simplified = self.simplify_path(path);

        // 第二步：使用Chaikin算法平滑
        let smoothed = self.chaikin_smooth(&simplified, 3);

        // 第三步：添加转向点（使转弯更自然）
        let with_turns = self.add_turn_points(&smoothed);

        // 第四步：重新采样到均匀间距
        self.resample_path(&with_turns)
    }

    /// 简化路径（使用Douglas-Peucker算法）
    fn simplify_path(&self, path: &[GeoPoint]) -> Vec<GeoPoint> {
        if path.len() < 3 {
            return path.to_vec();
        }

        let epsilon = self.config.min_point_distance * 0.5;
        self.douglas_peucker(path, epsilon)
    }

    /// Douglas-Peucker算法
    fn douglas_peucker(&self, points: &[GeoPoint], epsilon: f64) -> Vec<GeoPoint> {
        if points.len() < 3 {
            return points.to_vec();
        }

        // 找到距离最远的点
        let mut max_dist = 0.0;
        let mut max_index = 0;

        let start = &points[0];
        let end = &points[points.len() - 1];

        for (i, point) in points.iter().enumerate().skip(1).take(points.len() - 2) {
            let dist = self.point_to_line_distance(point, start, end);
            if dist > max_dist {
                max_dist = dist;
                max_index = i;
            }
        }

        // 如果最大距离大于阈值，递归简化
        if max_dist > epsilon {
            let left = self.douglas_peucker(&points[..=max_index], epsilon);
            let right = self.douglas_peucker(&points[max_index..], epsilon);

            let mut result = left;
            result.pop(); // 移除重复的中点
            result.extend(right);
            result
        } else {
            vec![*start, *end]
        }
    }

    /// 点到直线的距离
    fn point_to_line_distance(&self, point: &GeoPoint, line_start: &GeoPoint, line_end: &GeoPoint) -> f64 {
        let line_length = line_start.distance_to(line_end);
        if line_length < 1e-10 {
            return point.distance_to(line_start);
        }

        // 使用叉积计算距离
        let cross = ((line_end.longitude - line_start.longitude) * (point.latitude - line_start.latitude)
            - (line_end.latitude - line_start.latitude) * (point.longitude - line_start.longitude)).abs();

        cross * 111320.0 // 近似转换为米
    }

    /// Chaikin曲线平滑算法
    fn chaikin_smooth(&self, points: &[GeoPoint], iterations: usize) -> Vec<GeoPoint> {
        let mut current = points.to_vec();

        for _ in 0..iterations {
            if current.len() < 3 {
                break;
            }

            let mut next = Vec::with_capacity(current.len() * 2);

            // 保留起点
            next.push(current[0]);

            for i in 0..current.len() - 1 {
                let p0 = &current[i];
                let p1 = &current[i + 1];

                // 生成两个新点：1/4和3/4位置
                let q = GeoPoint {
                    latitude: p0.latitude * 0.75 + p1.latitude * 0.25,
                    longitude: p0.longitude * 0.75 + p1.longitude * 0.25,
                    altitude: p0.altitude,
                };

                let r = GeoPoint {
                    latitude: p0.latitude * 0.25 + p1.latitude * 0.75,
                    longitude: p0.longitude * 0.25 + p1.longitude * 0.75,
                    altitude: p1.altitude,
                };

                next.push(q);
                next.push(r);
            }

            // 保留终点
            next.push(*current.last().expect("Invalid path"));

            current = next;
        }

        current
    }

    /// 在转弯处添加额外点，使转弯更自然
    fn add_turn_points(&self, points: &[GeoPoint]) -> Vec<GeoPoint> {
        if points.len() < 3 {
            return points.to_vec();
        }

        let mut result = Vec::with_capacity(points.len() + points.len() / 2);
        result.push(points[0]);

        for i in 1..points.len() - 1 {
            let prev = &points[i - 1];
            let curr = &points[i];
            let next = &points[i + 1];

            // 计算转角
            let angle1 = prev.bearing_to(curr);
            let angle2 = curr.bearing_to(next);

            let mut angle_diff = (angle2 - angle1).abs();
            if angle_diff > 180.0 {
                angle_diff = 360.0 - angle_diff;
            }

            // 如果转角较大，添加额外的点
            if angle_diff > 15.0 {
                // 在转角前后添加点
                let dist_before = prev.distance_to(curr);
                let dist_after = curr.distance_to(next);

                if dist_before > self.config.min_point_distance * 2.0 {
                    let before = GeoPoint {
                        latitude: prev.latitude + (curr.latitude - prev.latitude) * 0.7,
                        longitude: prev.longitude + (curr.longitude - prev.longitude) * 0.7,
                        altitude: prev.altitude,
                    };
                    result.push(before);
                }

                result.push(*curr);

                if dist_after > self.config.min_point_distance * 2.0 {
                    let after = GeoPoint {
                        latitude: curr.latitude + (next.latitude - curr.latitude) * 0.3,
                        longitude: curr.longitude + (next.longitude - curr.longitude) * 0.3,
                        altitude: curr.altitude,
                    };
                    result.push(after);
                }
            } else {
                result.push(*curr);
            }
        }

        result.push(*points.last().expect("Invalid path"));
        result
    }

    /// 重新采样路径到均匀间距
    fn resample_path(&self, points: &[GeoPoint]) -> Vec<GeoPoint> {
        if points.len() < 2 {
            return points.to_vec();
        }

        // 计算总长度
        let total_length: f64 = points.windows(2)
            .map(|w| w[0].distance_to(&w[1]))
            .sum();

        let num_points = (total_length / self.config.min_point_distance).ceil() as usize;
        let segment_length = total_length / num_points as f64;

        let mut result = Vec::with_capacity(num_points + 1);
        result.push(points[0]);

        let mut accumulated = 0.0;
        let mut current_segment = 0;

        for target_distance in (1..num_points).map(|i| i as f64 * segment_length) {
            // 找到对应的原始路径段
            while current_segment < points.len() - 1 {
                let segment_dist = points[current_segment].distance_to(&points[current_segment + 1]);

                if accumulated + segment_dist >= target_distance {
                    // 在这个段内插值
                    let t = (target_distance - accumulated) / segment_dist;
                    let interpolated = GeoPoint {
                        latitude: points[current_segment].latitude
                            + (points[current_segment + 1].latitude - points[current_segment].latitude) * t,
                        longitude: points[current_segment].longitude
                            + (points[current_segment + 1].longitude - points[current_segment].longitude) * t,
                        altitude: points[current_segment].altitude,
                    };
                    result.push(interpolated);
                    break;
                }

                accumulated += segment_dist;
                current_segment += 1;
            }
        }

        result.push(*points.last().expect("Invalid path"));
        result
    }

    /// 计算路径的曲率
    pub fn calculate_curvature(&self, path: &[GeoPoint]) -> Vec<f64> {
        if path.len() < 3 {
            return vec![0.0; path.len()];
        }

        let mut curvatures = vec![0.0];

        for i in 1..path.len() - 1 {
            let p0 = &path[i - 1];
            let p1 = &path[i];
            let p2 = &path[i + 1];

            // 使用三点计算曲率
            let a = p0.distance_to(p1);
            let b = p1.distance_to(p2);
            let c = p0.distance_to(p2);

            if a < 1e-10 || b < 1e-10 {
                curvatures.push(0.0);
                continue;
            }

            // 使用Menger曲率公式
            let s = (a + b + c) / 2.0;
            let area = (s * (s - a) * (s - b) * (s - c)).max(0.0).sqrt();

            let curvature = 4.0 * area / (a * b * c);
            curvatures.push(curvature);
        }

        curvatures.push(0.0);
        curvatures
    }

    /// 设置配置
    pub fn set_config(&mut self, config: PathSmootherConfig) {
        self.config = config;
    }
}

impl Default for PathSmoother {
    fn default() -> Self {
        Self::new(PathSmootherConfig::default())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_path_smoother() {
        let smoother = PathSmoother::default();

        // 创建一个锯齿形路径
        let path = vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.001, 0.0),
            GeoPoint::new(0.001, 0.001),
            GeoPoint::new(0.0, 0.001),
            GeoPoint::new(0.0, 0.0),
        ];

        let smoothed = smoother.smooth(&path);

        // 平滑后的路径应该有更多的点
        assert!(smoothed.len() >= path.len());
    }

    #[test]
    fn test_curvature_calculation() {
        let smoother = PathSmoother::default();

        // 直线路径
        let straight = vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.001, 0.0),
            GeoPoint::new(0.002, 0.0),
        ];

        let curvatures = smoother.calculate_curvature(&straight);

        // 直线的曲率应该接近0
        assert!(curvatures[1] < 0.01);
    }
}
