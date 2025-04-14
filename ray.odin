package raytracer

import "core:fmt"
import "core:math"

Ray :: struct {
  origin: ^Vector,
  direction: ^Vector,
}

ray_at :: proc (r: ^Ray, t: f64) -> Vector {
  return r.origin^ + t*r.direction^
}

ray_color :: proc(ray: ^Ray, world: ^[2]Hittable) -> u32 {
  hit_rec := HitRecord{}
  ray_color: Vector
  if hittable_list_hit(world, ray, 0, math.F64_MAX, &hit_rec) == true {
    ray_color = 0.5 * (hit_rec.normal + Vector{1, 1, 1}) 
  } else {
    unit_direction := unit_vector(ray.direction)
    a := 0.5*(unit_direction.y + 1.0)
    ray_color = (1.0-a)*Vector{1.0, 1.0, 1.0} + a*Vector{0.5, 0.7, 1.0}
  }
  ray_color *= 255.999
  return u32(ray_color.r) << 24 | u32(ray_color.g) << 16 | u32(ray_color.b) << 8 | 255
}

