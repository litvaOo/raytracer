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
  sphere_center := Vector{0, 0, -1}
  if (sphere_hit(&sphere_center, 0.5, r) == true) {
    return u32(255) << 24 | 255
  }
  unit_direction := unit_vector(r.direction)
  a := 0.5*(unit_direction.y + 1.0)
  ray_color := (1.0-a)*Vector{1.0, 1.0, 1.0} + a*Vector{0.5, 0.7, 1.0}
  ray_color *= 255.999
  return u32(ray_color.r) << 24 | u32(ray_color.g) << 16 | u32(ray_color.b) << 8 | 255
}

sphere_hit :: proc(center: ^Vector, radius: f64, ray: ^Ray) -> bool {
  origin_to_center := center^ - ray.origin^
  a := vector_dot(ray.direction, ray.direction)
  b := -2.0 * vector_dot(ray.direction, &origin_to_center)
  c := vector_dot(&origin_to_center, &origin_to_center) - radius*radius
  discriminant := b*b - 4.0*a*c
  return discriminant >= 0
}
