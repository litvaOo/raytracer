package raytracer

import "core:fmt"
import "core:math"

Ray :: struct {
  origin: ^Vector,
  direction: ^Vector,
}

ray_at :: proc(r: ^Ray, t: f64) -> Vector {
  return r.origin^ + t*r.direction^
}

get_ray :: proc(i, j: f64, pixel_xy_loc, pixel_delta_v, pixel_delta_u: Vector, center: ^Vector) -> Ray {
  offset := sample_square()
  pixel_sample := pixel_xy_loc + ((j + offset.x) * pixel_delta_u) + ((i + offset.y) * pixel_delta_v)
  ray_direction := new(Vector)

  ray_direction^ = pixel_sample - center^
  return Ray{center, ray_direction} 
}

ray_color :: proc(ray: ^Ray, world: ^[2]Hittable) -> Vector {
  hit_rec := HitRecord{}
  ray_color: Vector
  if hittable_list_hit(world, ray, 0, math.F64_MAX, &hit_rec) == true {
    ray_color = 0.5 * (hit_rec.normal + Vector{1, 1, 1}) 
  } else {
    unit_direction := unit_vector(ray.direction)
    a := 0.5*(unit_direction.y + 1.0)
    ray_color = (1.0-a)*Vector{1.0, 1.0, 1.0} + a*Vector{0.5, 0.7, 1.0}
  }
  ray_color.r = clamp(ray_color.r, 0.000, 0.999)
  ray_color.g = clamp(ray_color.g, 0.000, 0.999)
  ray_color.b = clamp(ray_color.b, 0.000, 0.999)
  return ray_color
}

