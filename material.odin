package raytracer

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
  unit_direction^ = unit_vector(ray_in.direction)
  refracted := new(Vector)
  refracted^ = refract(unit_direction, &hit_rec.normal, ri)
  scattered := new(Ray)
  scattered^ = Ray{&hit_rec.p, refracted}
  return true
}

Material :: union {
 Lambertian,
 Metal,
 Dielectric,
}


