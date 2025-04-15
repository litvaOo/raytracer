package raytracer

import "core:math/rand"
import "core:math"

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

linear_to_gamma :: proc(linear_component: f64) -> f64 {
  if linear_component > 0 {
    return math.sqrt(linear_component)
  }
  return 0
}

convert_vector_to_color :: proc(vec: ^Vector) -> u32 {
  vec.r = linear_to_gamma(vec.r)
  vec.g = linear_to_gamma(vec.g)
  vec.b = linear_to_gamma(vec.b)
  vec.r = clamp(vec.r, 0.000, 0.999)
  vec.g = clamp(vec.g, 0.000, 0.999)
  vec.b = clamp(vec.b, 0.000, 0.999)
  vec^ *= 255.999
  return u32(vec.r) << 24 | u32(vec.g) << 16 | u32(vec.b) << 8 | 255
}

defocus_disk_sample :: proc(camera_center, defocus_disk_v, defocus_disk_u: ^Vector) -> Vector {
  p := random_in_unit_disk()
  return camera_center^ + (p.x * defocus_disk_u^) + (p.y * defocus_disk_v^) 
}
