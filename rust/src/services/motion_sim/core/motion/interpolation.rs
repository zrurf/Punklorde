//! 轨迹插值模块

use crate::services::motion_sim::model::{GeoPoint, Trajectory};

/// Catmull-Rom样条插值器
#[derive(Debug, Clone)]
pub struct CatmullRomInterpolator {
    /// 张力参数（0.0 = 标准Catmull-Rom，0.5 = 更尖锐的曲线）
    tension: f64,
    /// 是否闭合曲线
    closed: bool,
}

impl Default for CatmullRomInterpolator {
    fn default() -> Self {
        Self {
            tension: 0.0,
            closed: false,
        }
    }
}

impl CatmullRomInterpolator {
    /// 创建新的插值器
    pub fn new() -> Self {
        Self::default()
    }

    /// 设置张力参数
    pub fn with_tension(mut self, tension: f64) -> Self {
        self.tension = tension.clamp(-1.0, 1.0);
        self
    }

    /// 设置是否闭合曲线
    pub fn with_closed(mut self, closed: bool) -> Self {
        self.closed = closed;
        self
    }

    /// 对轨迹进行插值，返回插值后的点列表
    ///
    /// # 参数
    /// * `trajectory` - 原始轨迹
    /// * `segment_points` - 每个原始段插入的点数（越大越平滑）
    pub fn interpolate(&self, trajectory: &Trajectory, segment_points: usize) -> Vec<GeoPoint> {
        if trajectory.points.len() < 2 {
            return trajectory.points.clone();
        }

        let n = trajectory.points.len();
        let mut result = Vec::with_capacity(n * (segment_points + 1));

        for i in 0..n - 1 {
            // 获取四个控制点
            let p0 = self.get_control_point(trajectory, i, -1);
            let p1 = &trajectory.points[i];
            let p2 = &trajectory.points[i + 1];
            let p3 = self.get_control_point(trajectory, i, 2);

            // 添加起点
            result.push(*p1);

            // 插值中间点
            for j in 1..=segment_points {
                let t = j as f64 / (segment_points + 1) as f64;
                let point = self.interpolate_point(p0, p1, p2, p3, t);
                result.push(point);
            }
        }

        // 添加最后一个点
        result.push(*trajectory.points.last().expect("Invalid trajectory"));

        // 如果是闭合曲线，添加回到起点的路径
        if self.closed && n >= 3 {
            let p0 = &trajectory.points[n - 2];
            let p1 = trajectory.points.last().expect("Invalid trajectory");
            let p2 = &trajectory.points[0];
            let p3 = &trajectory.points[1];

            for j in 1..=segment_points {
                let t = j as f64 / (segment_points + 1) as f64;
                let point = self.interpolate_point(p0, p1, p2, p3, t);
                result.push(point);
            }
        }

        result
    }

    /// 获取控制点
    fn get_control_point<'a>(&self, trajectory: &'a Trajectory, current: usize, offset: i32) -> &'a GeoPoint {
        let n = trajectory.points.len() as i32;
        let index = current as i32 + offset;

        if self.closed {
            // 闭合曲线：循环
            let wrapped = ((index % n) + n) % n;
            &trajectory.points[wrapped as usize]
        } else {
            // 非闭合：边界处复制边界点
            let clamped = index.clamp(0, n - 1);
            &trajectory.points[clamped as usize]
        }
    }

    /// 在四个控制点之间插值
    fn interpolate_point(&self, p0: &GeoPoint, p1: &GeoPoint, p2: &GeoPoint, p3: &GeoPoint, t: f64) -> GeoPoint {
        let t2 = t * t;
        let t3 = t2 * t;

        // 将经纬度转换为局部坐标（相对于p1）
        let lat_scale = 111320.0; // 纬度每度约111.32km
        let lon_scale = lat_scale * p1.latitude.to_radians().cos();

        let x0 = (p0.longitude - p1.longitude) * lon_scale;
        let y0 = (p0.latitude - p1.latitude) * lat_scale;
        let x1 = 0.0;
        let y1 = 0.0;
        let x2 = (p2.longitude - p1.longitude) * lon_scale;
        let y2 = (p2.latitude - p1.latitude) * lat_scale;
        let x3 = (p3.longitude - p1.longitude) * lon_scale;
        let y3 = (p3.latitude - p1.latitude) * lat_scale;

        // Catmull-Rom样条公式
        let tension = self.tension;

        // 计算切向量
        let m0x = (1.0 - tension) * (x2 - x0) / 2.0;
        let m0y = (1.0 - tension) * (y2 - y0) / 2.0;
        let m1x = (1.0 - tension) * (x3 - x1) / 2.0;
        let m1y = (1.0 - tension) * (y3 - y1) / 2.0;

        // Hermite基函数
        let h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
        let h10 = t3 - 2.0 * t2 + t;
        let h01 = -2.0 * t3 + 3.0 * t2;
        let h11 = t3 - t2;

        // 计算插值点
        let x = h00 * x1 + h10 * m0x + h01 * x2 + h11 * m1x;
        let y = h00 * y1 + h10 * m0y + h01 * y2 + h11 * m1y;

        // 转换回经纬度
        GeoPoint {
            latitude: p1.latitude + y / lat_scale,
            longitude: p1.longitude + x / lon_scale,
            altitude: self.interpolate_altitude(p0, p1, p2, p3, t),
        }
    }

    /// 插值海拔高度
    fn interpolate_altitude(&self, p0: &GeoPoint, p1: &GeoPoint, p2: &GeoPoint, p3: &GeoPoint, t: f64) -> Option<f64> {
        let altitudes = [p0.altitude, p1.altitude, p2.altitude, p3.altitude];

        // 如果都没有海拔，返回None
        if altitudes.iter().all(|a| a.is_none()) {
            return None;
        }

        // 使用可用的海拔值进行插值
        let valid_altitudes: Vec<(usize, f64)> = altitudes
            .iter()
            .enumerate()
            .filter_map(|(i, a)| a.map(|v| (i, v)))
            .collect();

        if valid_altitudes.is_empty() {
            return None;
        }

        // 简单线性插值
        let alt1 = p1.altitude.unwrap_or_else(|| {
            valid_altitudes.iter().map(|(_, v)| v).sum::<f64>() / valid_altitudes.len() as f64
        });
        let alt2 = p2.altitude.unwrap_or(alt1);

        Some(alt1 + (alt2 - alt1) * t)
    }
}

/// 插值轨迹对象
#[derive(Debug, Clone)]
pub struct InterpolatedTrajectory {
    /// 原始轨迹
    original: Trajectory,
    /// 插值后的点
    points: Vec<GeoPoint>,
    /// 每个原始点对应的插值点索引
    original_indices: Vec<usize>,
    /// 累计距离（用于快速定位）
    cumulative_distances: Vec<f64>,
    /// 总距离
    total_distance: f64,
}

impl InterpolatedTrajectory {
    /// 从原始轨迹创建插值轨迹
    pub fn from_trajectory(trajectory: &Trajectory, points_per_segment: usize) -> Self {
        let interpolator = CatmullRomInterpolator::new();
        let points = interpolator.interpolate(trajectory, points_per_segment);

        // 记录原始点对应的索引
        let mut original_indices = vec![0];
        let step = points_per_segment + 1;
        for i in 1..trajectory.points.len() {
            original_indices.push(i * step);
        }

        // 计算累计距离
        let mut cumulative_distances = Vec::with_capacity(points.len());
        let mut distance = 0.0;
        cumulative_distances.push(0.0);

        for i in 1..points.len() {
            distance += points[i - 1].distance_to(&points[i]);
            cumulative_distances.push(distance);
        }

        Self {
            original: trajectory.clone(),
            points,
            original_indices,
            cumulative_distances,
            total_distance: distance,
        }
    }

    /// 根据进度（0.0-1.0）获取位置
    pub fn get_position_at_progress(&self, progress: f64) -> GeoPoint {
        let clamped_progress = progress.clamp(0.0, 1.0);
        let target_distance = clamped_progress * self.total_distance;
        self.get_position_at_distance(target_distance)
    }

    /// 根据距离获取位置
    pub fn get_position_at_distance(&self, distance: f64) -> GeoPoint {
        if self.points.is_empty() {
            return GeoPoint::new(0.0, 0.0);
        }

        let clamped_distance = distance.clamp(0.0, self.total_distance);

        // 二分查找
        let idx = self.cumulative_distances
            .partition_point(|&d| d < clamped_distance)
            .saturating_sub(1)
            .min(self.points.len() - 2);

        let d0 = self.cumulative_distances[idx];
        let d1 = self.cumulative_distances[idx + 1];
        let segment_length = d1 - d0;

        if segment_length < 1e-10 {
            return self.points[idx];
        }

        // 线性插值
        let t = (clamped_distance - d0) / segment_length;
        let p0 = &self.points[idx];
        let p1 = &self.points[idx + 1];

        GeoPoint {
            latitude: p0.latitude + (p1.latitude - p0.latitude) * t,
            longitude: p0.longitude + (p1.longitude - p0.longitude) * t,
            altitude: match (p0.altitude, p1.altitude) {
                (Some(a0), Some(a1)) => Some(a0 + (a1 - a0) * t),
                (Some(a), None) | (None, Some(a)) => Some(a),
                (None, None) => None,
            },
        }
    }

    /// 根据距离获取方向
    pub fn get_bearing_at_distance(&self, distance: f64) -> f64 {
        let offset = 0.5; // 向前看0.5米
        let p1 = self.get_position_at_distance(distance.max(0.0));
        let p2 = self.get_position_at_distance((distance + offset).min(self.total_distance));
        p1.bearing_to(&p2)
    }

    /// 获取总距离
    pub fn total_distance(&self) -> f64 {
        self.total_distance
    }

    /// 获取插值点数量
    pub fn point_count(&self) -> usize {
        self.points.len()
    }

    /// 获取所有插值点
    pub fn points(&self) -> &[GeoPoint] {
        &self.points
    }

    /// 根据距离获取插值点索引
    pub fn get_index_at_distance(&self, distance: f64) -> usize {
        self.cumulative_distances
            .partition_point(|&d| d < distance)
            .saturating_sub(1)
            .min(self.points.len() - 1)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_catmull_rom_basic() {
        let trajectory = Trajectory::new(vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.0, 0.001),
            GeoPoint::new(0.001, 0.001),
            GeoPoint::new(0.001, 0.0),
        ]);

        let interpolator = CatmullRomInterpolator::new();
        let result = interpolator.interpolate(&trajectory, 5);

        assert!(result.len() > trajectory.points.len());

        // 检查端点保持不变
        assert!((result.first().expect("first point").latitude - 0.0).abs() < 1e-10);
        assert!((result.last().expect("last point").latitude - 0.001).abs() < 1e-10);
    }

    #[test]
    fn test_interpolated_trajectory() {
        let trajectory = Trajectory::new(vec![
            GeoPoint::new(0.0, 0.0),
            GeoPoint::new(0.0, 0.001),
            GeoPoint::new(0.001, 0.001),
        ]);

        let interpolated = InterpolatedTrajectory::from_trajectory(&trajectory, 10);

        assert!(interpolated.total_distance() > 0.0);

        // 检查进度0的位置
        let pos_start = interpolated.get_position_at_progress(0.0);
        assert!((pos_start.latitude - 0.0).abs() < 1e-10);

        // 检查进度1的位置
        let pos_end = interpolated.get_position_at_progress(1.0);
        assert!((pos_end.latitude - 0.001).abs() < 1e-10);
    }
}
