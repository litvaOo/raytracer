package raytracer

import "core:fmt"

Ray :: struct {
  origin: ^Vector,
  direction: ^Vector,
}

ray_at :: proc (r: ^Ray, t: f64) -> Vector {
  return r.origin^ + t*r.direction^
}

ray_color :: proc(r: ^Ray) -> u32 {
  unit_direction := unit_vector(r.direction)
  a := 0.5*(unit_direction.y + 1.0)
  ray_color := (1.0-a)*Vector{1.0, 1.0, 1.0} + a*Vector{0.5, 0.7, 1.0}
  ray_color *= 255.999
  return u32(ray_color.r) << 24 | u32(ray_color.g) << 16 | u32(ray_color.b) << 8 | 255
}
