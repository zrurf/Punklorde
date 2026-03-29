//! 坐标转换模块

use crate::services::motion_sim::model::GeoPoint;

/// 坐标系类型
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CoordinateSystem {
    /// WGS84坐标系（GPS标准坐标系）
    WGS84,
    /// GCJ02坐标系（火星坐标系，中国标准）
    GCJ02,
    /// BD09坐标系（百度坐标系）
    BD09,
}

/// 坐标转换器
pub struct CoordinateConverter {
    /// 地球半径（米）
    earth_radius: f64,
    /// 偏移参数A
    a: f64,
    /// 偏移参数E
    ee: f64,
}

impl Default for CoordinateConverter {
    fn default() -> Self {
        Self {
            earth_radius: 6378245.0,
            a: 6378245.0,
            ee: 0.00669342162296594323,
        }
    }
}

impl CoordinateConverter {
    pub fn new() -> Self {
        Self::default()
    }

    /// 判断坐标是否在中国境内
    pub fn is_in_china(&self, point: &GeoPoint) -> bool {
        // 简化的中国边界判断
        let lat = point.latitude;
        let lon = point.longitude;

        lon >= 72.004 && lon <= 137.8347 && lat >= 0.8293 && lat <= 55.8271
    }

    /// WGS84 转 GCJ02
    pub fn wgs84_to_gcj02(&self, point: &GeoPoint) -> GeoPoint {
        if !self.is_in_china(point) {
            return *point;
        }

        let dlat = self.transform_lat(point.longitude - 105.0, point.latitude - 35.0);
        let dlon = self.transform_lon(point.longitude - 105.0, point.latitude - 35.0);

        let rad_lat = point.latitude.to_radians();
        let magic = rad_lat.sin() * 0.5 + 1.0;
        let sqrt_magic = (magic * magic).sqrt();

        let lat = point.latitude + (dlat * 180.0) / (self.earth_radius / sqrt_magic * std::f64::consts::PI);
        let lon = point.longitude + (dlon * 180.0) / (self.earth_radius / sqrt_magic * std::f64::consts::PI * rad_lat.cos());

        GeoPoint {
            latitude: lat,
            longitude: lon,
            altitude: point.altitude,
        }
    }

    /// GCJ02 转 WGS84
    pub fn gcj02_to_wgs84(&self, point: &GeoPoint) -> GeoPoint {
        if !self.is_in_china(point) {
            return *point;
        }

        let dlat = self.transform_lat(point.longitude - 105.0, point.latitude - 35.0);
        let dlon = self.transform_lon(point.longitude - 105.0, point.latitude - 35.0);

        let rad_lat = point.latitude.to_radians();
        let magic = rad_lat.sin() * 0.5 + 1.0;
        let sqrt_magic = (magic * magic).sqrt();

        let lat = point.latitude - (dlat * 180.0) / (self.earth_radius / sqrt_magic * std::f64::consts::PI);
        let lon = point.longitude - (dlon * 180.0) / (self.earth_radius / sqrt_magic * std::f64::consts::PI * rad_lat.cos());

        GeoPoint {
            latitude: lat,
            longitude: lon,
            altitude: point.altitude,
        }
    }

    /// GCJ02 转 BD09
    pub fn gcj02_to_bd09(&self, point: &GeoPoint) -> GeoPoint {
        let x = point.longitude;
        let y = point.latitude;
        let z = (x * x + y * y).sqrt() + 0.00002 * (y * std::f64::consts::PI * 3000.0 / 180.0).sin();
        let theta = y.atan2(x) + 0.000003 * (x * std::f64::consts::PI * 3000.0 / 180.0).cos();

        let lon = z * theta.cos() + 0.0065;
        let lat = z * theta.sin() + 0.006;

        GeoPoint {
            latitude: lat,
            longitude: lon,
            altitude: point.altitude,
        }
    }

    /// BD09 转 GCJ02
    pub fn bd09_to_gcj02(&self, point: &GeoPoint) -> GeoPoint {
        let x = point.longitude - 0.0065;
        let y = point.latitude - 0.006;
        let z = (x * x + y * y).sqrt() - 0.00002 * (y * std::f64::consts::PI * 3000.0 / 180.0).sin();
        let theta = y.atan2(x) - 0.000003 * (x * std::f64::consts::PI * 3000.0 / 180.0).cos();

        let lon = z * theta.cos();
        let lat = z * theta.sin();

        GeoPoint {
            latitude: lat,
            longitude: lon,
            altitude: point.altitude,
        }
    }

    /// WGS84 转 BD09
    pub fn wgs84_to_bd09(&self, point: &GeoPoint) -> GeoPoint {
        let gcj02 = self.wgs84_to_gcj02(point);
        self.gcj02_to_bd09(&gcj02)
    }

    /// BD09 转 WGS84
    pub fn bd09_to_wgs84(&self, point: &GeoPoint) -> GeoPoint {
        let gcj02 = self.bd09_to_gcj02(point);
        self.gcj02_to_wgs84(&gcj02)
    }

    /// 通用转换方法
    pub fn convert(&self, point: &GeoPoint, from: CoordinateSystem, to: CoordinateSystem) -> GeoPoint {
        if from == to {
            return *point;
        }

        match (from, to) {
            (CoordinateSystem::WGS84, CoordinateSystem::GCJ02) => self.wgs84_to_gcj02(point),
            (CoordinateSystem::WGS84, CoordinateSystem::BD09) => self.wgs84_to_bd09(point),
            (CoordinateSystem::GCJ02, CoordinateSystem::WGS84) => self.gcj02_to_wgs84(point),
            (CoordinateSystem::GCJ02, CoordinateSystem::BD09) => self.gcj02_to_bd09(point),
            (CoordinateSystem::BD09, CoordinateSystem::WGS84) => self.bd09_to_wgs84(point),
            (CoordinateSystem::BD09, CoordinateSystem::GCJ02) => self.bd09_to_gcj02(point),
            _ => *point,
        }
    }

    /// 纬度偏移计算
    fn transform_lat(&self, x: f64, y: f64) -> f64 {
        let mut ret = -100.0
            + 2.0 * x + 3.0 * y + 0.2 * y * y
            + 0.1 * x * y + 0.2 * (x.abs()).sqrt();
        ret += (20.0 * (6.0 * x * std::f64::consts::PI).sin()
            + 20.0 * (2.0 * x * std::f64::consts::PI).sin()
            + 20.0 * (y * std::f64::consts::PI).sin()
            + 40.0 * (y / 3.0 * std::f64::consts::PI).sin()
            + 160.0 * (y / 12.0 * std::f64::consts::PI).sin()
            + 320.0 * (y / 30.0 * std::f64::consts::PI).sin()) * 2.0 / 3.0;
        ret
    }

    /// 经度偏移计算
    fn transform_lon(&self, x: f64, y: f64) -> f64 {
        let mut ret = 300.0 + x + 2.0 * y + 0.1 * x * x
            + 0.1 * x * y + 0.1 * (x.abs()).sqrt();
        ret += (20.0 * (6.0 * x * std::f64::consts::PI).sin()
            + 20.0 * (2.0 * x * std::f64::consts::PI).sin()
            + 20.0 * (x * std::f64::consts::PI).sin()
            + 40.0 * (x / 3.0 * std::f64::consts::PI).sin()
            + 160.0 * (x / 12.0 * std::f64::consts::PI).sin()
            + 320.0 * (x / 30.0 * std::f64::consts::PI).sin()) * 2.0 / 3.0;
        ret
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_coordinate_conversion() {
        let converter = CoordinateConverter::new();

        // 北京天安门 WGS84坐标
        let wgs84 = GeoPoint::new(39.908722, 116.397499);

        // 转换到GCJ02
        let gcj02 = converter.wgs84_to_gcj02(&wgs84);

        // 应该有偏移
        assert!((gcj02.latitude - wgs84.latitude).abs() < 0.01);
        assert!((gcj02.longitude - wgs84.longitude).abs() < 0.01);

        // 转回WGS84
        let back = converter.gcj02_to_wgs84(&gcj02);

        // 应该接近原坐标
        assert!((back.latitude - wgs84.latitude).abs() < 0.0001);
        assert!((back.longitude - wgs84.longitude).abs() < 0.0001);
    }

    #[test]
    fn test_outside_china() {
        let converter = CoordinateConverter::new();

        // 纽约坐标（不在中国境内）
        let wgs84 = GeoPoint::new(40.7128, -74.0060);
        let gcj02 = converter.wgs84_to_gcj02(&wgs84);

        // 境外坐标不应有偏移
        assert!((gcj02.latitude - wgs84.latitude).abs() < 1e-10);
        assert!((gcj02.longitude - wgs84.longitude).abs() < 1e-10);
    }

    #[test]
    fn test_is_in_china_boundary() {
        let converter = CoordinateConverter::new();
        // 边界附近
        let inside = GeoPoint::new(0.83, 72.01); // 极小边界
        assert!(converter.is_in_china(&inside));
        let outside = GeoPoint::new(55.83, 137.84); // 略超
        assert!(!converter.is_in_china(&outside));
    }
}
