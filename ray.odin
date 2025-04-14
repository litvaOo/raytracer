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

ray_color :: proc(ray: ^Ray, world: ^[2]Hittable, depth: u32) -> Vector {
  if depth <= 0 {
    return Vector{0, 0, 0}
  }
  hit_rec := HitRecord{}
  new_ray_color: Vector
  if hittable_list_hit(world, ray, 0.001, math.F64_MAX, &hit_rec) == true {
    direction := random_on_hemisphere(&hit_rec.normal)
    new_ray := Ray{&hit_rec.p, &direction}
    new_ray_color = 0.5 * ray_color(&new_ray, world, depth-1)
  } else {
    unit_direction := unit_vector(ray.direction)
    a := 0.5*(unit_direction.y + 1.0)
    new_ray_color = (1.0-a)*Vector{1.0, 1.0, 1.0} + a*Vector{0.5, 0.7, 1.0}
  }
  new_ray_color.r = clamp(new_ray_color.r, 0.000, 0.999)
  new_ray_color.g = clamp(new_ray_color.g, 0.000, 0.999)
  new_ray_color.b = clamp(new_ray_color.b, 0.000, 0.999)
  return new_ray_color
}

