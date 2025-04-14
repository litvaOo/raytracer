package raytracer

import "core:math/rand"

random_float :: proc(min: f64, max: f64) -> f64 {
  return min + (max-min)*rand.float64()
}

clamp :: proc(x: f64, min: f64, max: f64) -> f64 {
  if x < min {
    return min
  }
  if x > max {
    return max
  }
  return x
}

sample_square :: proc() -> Vector {
  return Vector{
    rand.float64() - 0.5,
    rand.float64() - 0.5,
    0}
}

convert_vector_to_color :: proc(vec: ^Vector) -> u32 {
  vec^ *= 255.999
  return u32(vec.r) << 24 | u32(vec.g) << 16 | u32(vec.b) << 8 | 255
}

