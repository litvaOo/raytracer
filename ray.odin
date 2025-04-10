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

ray_color :: proc(r: ^Ray) -> u32 {
  sphere_center := Vector{0, 0, -1}
  t := sphere_hit(&sphere_center, 0.5, r)
  ray_color: Vector
  if ( t > 0.0) {
    normal := (ray_at(r, t) - Vector{0, 0, -1}) 
    normal = unit_vector(&normal)
    ray_color = 0.5*Vector{normal.x+1, normal.y+1, normal.z+1}
  } else {
    unit_direction := unit_vector(r.direction)
    a := 0.5*(unit_direction.y + 1.0)
    ray_color = (1.0-a)*Vector{1.0, 1.0, 1.0} + a*Vector{0.5, 0.7, 1.0}
  }
  ray_color *= 255.999
  return u32(ray_color.r) << 24 | u32(ray_color.g) << 16 | u32(ray_color.b) << 8 | 255
}

sphere_hit :: proc(center: ^Vector, radius: f64, ray: ^Ray) -> f64 {
  origin_to_center := center^ - ray.origin^
  a := vector_length_squared(ray.direction)
  h := vector_dot(ray.direction, &origin_to_center)
  c := vector_length_squared(&origin_to_center) - radius*radius
  discriminant := h*h - a*c
  if discriminant < 0 {
    return -1.0
  } else {
    return (h - math.sqrt(discriminant))/a
  }
}
