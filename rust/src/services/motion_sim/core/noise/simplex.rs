//! Simplex噪声实现

const SQRT_3: f64 = 1.7320508075688772935274463415059;

/// 2D Simplex噪声生成器
#[derive(Debug, Clone)]
pub struct SimplexNoise {
    /// 排列表（用于哈希）
    perm: Vec<u8>,
    /// 2D偏斜因子
    f2: f64,
    /// 2D反偏斜因子
    g2: f64,
}

impl SimplexNoise {
    /// 使用指定种子创建噪声生成器
    pub fn new(seed: u64) -> Self {
        // 初始化排列表
        let mut perm = Vec::with_capacity(512);
        let mut perm_mod = Vec::with_capacity(256);

        // 使用种子生成基础排列表
        for i in 0..=255u8 {
            perm_mod.push(i);
        }

        // Fisher-Yates洗牌，使用种子
        let mut rng_state = seed;
        for i in (1..256usize).rev() {
            rng_state = xorshift64(rng_state);
            let j = (rng_state % (i as u64 + 1)) as usize;
            perm_mod.swap(i, j);
        }

        // 扩展排列表
        for i in 0..256 {
            perm.push(perm_mod[i]);
            perm.push(perm_mod[i]);
        }

        Self {
            perm,
            f2: 0.5 * (SQRT_3 - 1.0),
            g2: (3.0 - SQRT_3) / 6.0,
        }
    }

    /// 计算2D噪声值
    ///
    /// # 参数
    /// * `x` - X坐标
    /// * `y` - Y坐标
    ///
    /// # 返回
    /// 噪声值，范围 [-1, 1]
    pub fn noise2d(&self, x: f64, y: f64) -> f64 {
        // 偏斜输入坐标
        let s = (x + y) * self.f2;
        let i = (x + s).floor() as i64;
        let j = (y + s).floor() as i64;

        // 反偏斜回输入坐标
        let t = (i + j) as f64 * self.g2;
        let x0 = x - (i as f64 - t);
        let y0 = y - (j as f64 - t);

        // 确定要贡献的单纯形
        let (i1, j1) = if x0 > y0 { (1, 0) } else { (0, 1) };

        let x1 = x0 - i1 as f64 + self.g2;
        let y1 = y0 - j1 as f64 + self.g2;
        let x2 = x0 - 1.0 + 2.0 * self.g2;
        let y2 = y0 - 1.0 + 2.0 * self.g2;

        // 哈希坐标
        let ii = i & 255;
        let jj = j & 255;

        // 计算每个角的贡献
        let mut n0 = 0.0;
        let mut n1 = 0.0;
        let mut n2 = 0.0;

        let t0 = 0.5 - x0 * x0 - y0 * y0;
        if t0 >= 0.0 {
            let gi0 = self.grad(self.perm[ii as usize + self.perm[jj as usize] as usize]);
            n0 = t0 * t0 * t0 * t0 * (gi0.0 * x0 + gi0.1 * y0);
        }

        let t1 = 0.5 - x1 * x1 - y1 * y1;
        if t1 >= 0.0 {
            let gi1 = self.grad(self.perm[(ii + i1) as usize + self.perm[(jj + j1) as usize] as usize]);
            n1 = t1 * t1 * t1 * t1 * (gi1.0 * x1 + gi1.1 * y1);
        }

        let t2 = 0.5 - x2 * x2 - y2 * y2;
        if t2 >= 0.0 {
            let gi2 = self.grad(self.perm[(ii + 1) as usize + self.perm[(jj + 1) as usize] as usize]);
            n2 = t2 * t2 * t2 * t2 * (gi2.0 * x2 + gi2.1 * y2);
        }

        // 将结果缩放到 [-1, 1]
        70.0 * (n0 + n1 + n2)
    }

    /// 计算3D噪声值
    pub fn noise3d(&self, x: f64, y: f64, z: f64) -> f64 {
        // 简化实现：组合多个2D噪声层
        let noise_xy = self.noise2d(x, y);
        let noise_yz = self.noise2d(y, z);
        let noise_xz = self.noise2d(x, z);

        (noise_xy + noise_yz + noise_xz) / 3.0
    }

    /// 分形布朗运动- 多层噪声叠加
    ///
    /// # 参数
    /// * `x` - X坐标
    /// * `y` - Y坐标
    /// * `octaves` - 叠加层数
    /// * `persistence` - 持久度（每层振幅衰减因子）
    /// * `lacunarity` - 间隙度（每层频率增长因子）
    pub fn fbm(&self, x: f64, y: f64, octaves: u32, persistence: f64, lacunarity: f64) -> f64 {
        let mut total = 0.0;
        let mut frequency = 1.0;
        let mut amplitude = 1.0;
        let mut max_value = 0.0;

        for _ in 0..octaves {
            total += self.noise2d(x * frequency, y * frequency) * amplitude;
            max_value += amplitude;
            amplitude *= persistence;
            frequency *= lacunarity;
        }

        total / max_value
    }

    /// 湍流噪声 - 绝对值噪声叠加
    pub fn turbulence(&self, x: f64, y: f64, octaves: u32) -> f64 {
        let mut total = 0.0;
        let mut frequency = 1.0;
        let mut amplitude = 1.0;
        let mut max_value = 0.0;

        for _ in 0..octaves {
            total += self.noise2d(x * frequency, y * frequency).abs() * amplitude;
            max_value += amplitude;
            amplitude *= 0.5;
            frequency *= 2.0;
        }

        total / max_value
    }

    /// 获取梯度向量
    fn grad(&self, hash: u8) -> (f64, f64) {
        // 8个方向的梯度
        let grad_table: [(f64, f64); 8] = [
            (1.0, 1.0),
            (-1.0, 1.0),
            (1.0, -1.0),
            (-1.0, -1.0),
            (1.0, 0.0),
            (-1.0, 0.0),
            (0.0, 1.0),
            (0.0, -1.0),
        ];
        grad_table[(hash & 7) as usize]
    }
}

/// Xorshift64伪随机数生成器
fn xorshift64(mut state: u64) -> u64 {
    state ^= state << 13;
    state ^= state >> 7;
    state ^= state << 17;
    state
}

/// 多维Simplex噪声生成器（支持时间维度）
#[derive(Debug, Clone)]
pub struct MultiDimensionalNoise {
    /// 基础噪声生成器
    base: SimplexNoise,
    /// 时间种子
    time_offset: f64,
}

impl MultiDimensionalNoise {
    pub fn new(seed: u64) -> Self {
        Self {
            base: SimplexNoise::new(seed),
            time_offset: 0.0,
        }
    }

    /// 设置时间偏移
    pub fn set_time_offset(&mut self, offset: f64) {
        self.time_offset = offset;
    }

    /// 生成时空噪声（x, y, t）
    pub fn noise_spacetime(&self, x: f64, y: f64, time: f64) -> f64 {
        let t = time + self.time_offset;
        self.base.noise3d(x, y, t)
    }

    /// 生成平滑的时间变化噪声
    pub fn smooth_temporal_noise(&self, x: f64, y: f64, time: f64, smoothness: f64) -> f64 {
        let t = time * smoothness;
        self.base.fbm(x, y + t, 4, 0.5, 2.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simplex_noise_range() {
        let noise = SimplexNoise::new(42);
        for i in 0..100 {
            let x = i as f64 * 0.1;
            let y = i as f64 * 0.15;
            let value = noise.noise2d(x, y);
            assert!(value >= -1.0 && value <= 1.0, "Noise value {} out of range", value);
        }
    }

    #[test]
    fn test_fbm_continuity() {
        let noise = SimplexNoise::new(42);
        let v1 = noise.fbm(1.0, 1.0, 4, 0.5, 2.0);
        let v2 = noise.fbm(1.001, 1.0, 4, 0.5, 2.0);
        assert!((v1 - v2).abs() < 0.1, "FBM should be continuous");
    }

    #[test]
    fn test_noise2d_large_input() {
        let noise = SimplexNoise::new(42);
        let huge = 1e18;
        let value = noise.noise2d(huge, huge);
        assert!(value >= -1.0 && value <= 1.0, "Noise value out of range");
    }
}
