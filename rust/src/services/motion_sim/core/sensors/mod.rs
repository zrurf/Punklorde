pub mod gps;
pub mod accelerometer;
pub mod gyroscope;
pub mod compass;
pub mod barometer;
pub mod pedometer;

pub struct SensorTimers {
    pub(crate) gps: f64,
    pub(crate) accelerometer: f64,
    pub(crate) gyroscope: f64,
    pub(crate) compass: f64,
    pub(crate) barometer: f64,
}

impl SensorTimers {
    pub(crate) fn new() -> Self {
        Self {
            gps: 0.0,
            accelerometer: 0.0,
            gyroscope: 0.0,
            compass: 0.0,
            barometer: 0.0,
        }
    }

    pub(crate) fn update(&mut self, dt: f64) {
        self.gps += dt;
        self.accelerometer += dt;
        self.gyroscope += dt;
        self.compass += dt;
        self.barometer += dt;
    }
}