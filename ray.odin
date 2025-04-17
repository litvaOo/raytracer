package raytracer

import "core:fmt"
import "core:math"
import "base:runtime"

Ray :: struct {
  origin: ^Vector,
  direction: ^Vector,
}

ray_at :: proc(r: ^Ray, t: f64) -> Vector {
  return r.origin^ + t*r.direction^
}

get_ray :: proc(
    i, j, defocus_angle: f64,
    pixel_xy_loc, pixel_delta_v, pixel_delta_u,
    center, defocus_disk_v, defocus_disk_u: ^Vector,
    arena_alloc: runtime.Allocator) -> Ray {
  offset := sample_square()
  pixel_sample := pixel_xy_loc^ + ((j + offset.x) * pixel_delta_u^) + ((i + offset.y) * pixel_delta_v^)
  ray_origin := new(Vector, arena_alloc)
  ray_origin^ = (defocus_angle <= 0) ? center^ : defocus_disk_sample(center, defocus_disk_v, defocus_disk_u)
  ray_direction := new(Vector, arena_alloc)
  ray_direction^ = pixel_sample - ray_origin^
  return Ray{ray_origin, ray_direction} 
}

ray_color :: proc(ray: ^Ray, world: [dynamic]Hittable, depth: u32, arena_alloc: runtime.Allocator) -> Vector {
  if depth <= 0 {
    return Vector{0, 0, 0}
  }
  hit_rec := HitRecord{}
  new_ray_color: Vector
  if hittable_list_hit(world, ray, 0.001, math.F64_MAX, &hit_rec) == true {
    scattered := Ray{}
    attenuation := Vector{}
    switch &mat in hit_rec.material {
      case Metal:
        if metal_scatter(ray, &hit_rec, &attenuation, &scattered, &mat, arena_alloc) == true
          { return attenuation * ray_color(&scattered, world, depth-1, arena_alloc) }
        return Vector{0,0,0}
      case Lambertian:
        if lambertian_scatter(ray, &hit_rec, &attenuation, &scattered, &mat, arena_alloc) == true
          { return attenuation * ray_color(&scattered, world, depth-1, arena_alloc) }
        return Vector{0,0,0}
      case Dielectric:
        if dielectric_scatter(ray, &hit_rec, &attenuation, &scattered, &mat, arena_alloc) == true
          { 
            return attenuation * ray_color(&scattered, world, depth-1, arena_alloc) }
        return Vector{0,0,0}
    }
  }
  unit_direction := unit_vector(ray.direction)
  a := 0.5*(unit_direction.y + 1.0)
  return (1.0-a)*Vector{1.0, 1.0, 1.0} + a*Vector{0.5, 0.7, 1.0}
}

