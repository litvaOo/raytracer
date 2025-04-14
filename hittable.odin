package raytracer

import "core:math"

HitRecord :: struct {
  p: Vector,
  normal: Vector,
  t: f64,
  front_face: bool,
  material: ^Material,
}

set_face_normal :: proc(hit_rec: ^HitRecord, ray: ^Ray, outward_normal: ^Vector) {
  hit_rec.front_face = vector_dot(ray.direction, outward_normal) < 0
  hit_rec.normal = hit_rec.front_face ? outward_normal^ : -outward_normal^
}


Sphere :: struct {
  center: Vector,
  radius: f64,
  material: ^Material,
}

sphere_hit :: proc (sphere: ^Sphere, ray: ^Ray, ray_t_min: f64, ray_t_max: f64, rec: ^HitRecord) -> bool {
  origin_to_center := sphere.center - ray.origin^
  a := vector_length_squared(ray.direction)
  h := vector_dot(ray.direction, &origin_to_center)
  c := vector_length_squared(&origin_to_center) - sphere.radius*sphere.radius
  discriminant := h*h - a*c
  if discriminant < 0 {
    return false
  }
  sqrtd := math.sqrt(discriminant)

  root := (h - sqrtd) / a
  if root <= ray_t_min || ray_t_max <= root {
    root = (h+sqrtd)/a
    if root <= ray_t_min || ray_t_max <= root {
      return false
    }
  }

  rec.t = root
  rec.p = ray_at(ray, rec.t)
  rec.normal = (rec.p - sphere.center) / sphere.radius
  rec.material = sphere.material
  outward_normal := (rec.p - sphere.center) / sphere.radius
  set_face_normal(rec, ray, &outward_normal)

  return true
}

Hittable :: union {
  Sphere,
}

hittable_list_hit :: proc (hittable_list: ^[4]Hittable, ray: ^Ray, ray_t_min: f64, ray_t_max: f64, rec: ^HitRecord) -> bool {
  temp_rec := HitRecord{}
  hit_anything := false
  closest_hit := ray_t_max

  for hittable in hittable_list {
    switch &hit in hittable {
      case Sphere:
        if sphere_hit(&hit, ray, ray_t_min, closest_hit, &temp_rec) {
          hit_anything = true
          closest_hit = temp_rec.t
          rec.p = temp_rec.p
          rec.normal = temp_rec.normal
          rec.t = temp_rec.t
          rec.front_face = temp_rec.front_face
          rec.material = temp_rec.material
        }
    }
  }
  return hit_anything
}
