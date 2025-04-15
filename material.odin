package raytracer

import "core:math"
import "core:math/rand"

Lambertian :: struct {
  albedo: Vector,
}

lambertian_scatter :: proc (ray_in: ^Ray, hit_rec: ^HitRecord, attenuation: ^Vector, scattered: ^Ray, material: ^Lambertian) -> bool{
  scatter_direction := new(Vector)
  scatter_direction^ = hit_rec.normal + random_unit_vector()
  if near_zero(scatter_direction) == true {
    scatter_direction^ = hit_rec.normal
  }
  scattered^ = Ray{&hit_rec.p, scatter_direction}
  attenuation^ = material.albedo
  return true
}

Metal :: struct {
  albedo: Vector,
  fuzz: f64,
}

metal_scatter :: proc (ray_in: ^Ray, hit_rec: ^HitRecord, attenuation: ^Vector, scattered: ^Ray, material: ^Metal) -> bool {
  reflected := new(Vector)
  reflected^ = reflect(ray_in.direction, &hit_rec.normal)
  reflected^ = unit_vector(reflected) + (material.fuzz * random_unit_vector())
  scattered^ = Ray{&hit_rec.p, reflected}
  attenuation^ = material.albedo
  return vector_dot(scattered.direction, &hit_rec.normal) > 0
}

Dielectric :: struct {
  refraction_index: f64,
}

dielectric_scatter :: proc(ray_in: ^Ray, hit_rec: ^HitRecord, attenuation: ^Vector, scattered: ^Ray, material: ^Dielectric) -> bool {
  attenuation^ = Vector{1.0, 1.0, 1.0}
  ri := hit_rec.front_face ? (1.0/material.refraction_index) : material.refraction_index
  unit_direction := new(Vector)
  unit_direction^ = -unit_vector(ray_in.direction)
  
  cos_theta := min(vector_dot(unit_direction, &hit_rec.normal), 1.0)
  sin_theta := math.sqrt(1.0 - cos_theta*cos_theta)
  unit_direction^ = -unit_direction^

  cannot_refract := ri * sin_theta > 1.0
  direction := new(Vector)

  if cannot_refract == true || reflectance(cos_theta, ri) > rand.float64(){
    direction^ = reflect(unit_direction, &hit_rec.normal)
  } else {
    direction^ = refract(unit_direction, &hit_rec.normal, ri)
  }

  scattered^ = Ray{&hit_rec.p, direction}
  return true
}

reflectance :: proc (cosine, refraction_index: f64) -> f64{
  r0 := (1 - refraction_index) / (1 + refraction_index)
  r0 *= r0
  return r0 + (1-r0)*math.pow((1-cosine), 5)
}

Material :: union {
 Lambertian,
 Metal,
 Dielectric,
}


