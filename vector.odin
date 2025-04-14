package raytracer

import "core:math/rand"
import "core:math"

Vector :: distinct[3]f64

vector_length :: proc (v: ^Vector) -> f64 {
  return math.sqrt(vector_length_squared(v))
}

vector_length_squared :: proc (v: ^Vector) -> f64 {
  return v.x*v.x + v.y*v.y + v.z*v.z
}

vector_cross :: proc(v1: ^Vector, v2: ^Vector) -> Vector {
  return Vector{
    v1.y*v2.z - v1.z*v2.y,
    v1.z*v2.x - v1.x*v2.z,
    v1.x*v2.y - v1.y*v2.x,
  }
}

unit_vector :: proc(v1: ^Vector) -> Vector {
  return v1^ / vector_length(v1)
}

vector_dot :: proc(v1: ^Vector, v2: ^Vector) -> f64 {
  return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
}

vector_random :: proc() -> Vector {
  return Vector{rand.float64(),rand.float64(),rand.float64()}
}

vector_random_interval :: proc(min, max: f64) -> Vector {
  return Vector{random_float(min, max), random_float(min, max), random_float(min, max)}
}

random_unit_vector :: proc() -> Vector {
  for {
    p := vector_random()
    lensq := vector_length_squared(&p)
    if 1e-160 < lensq && lensq <= 1 {
      return p / math.sqrt(lensq)
    }
  }
}

random_on_hemisphere :: proc(normal: ^Vector) -> Vector {
  on_unit_sphere := random_unit_vector()
  if vector_dot(&on_unit_sphere, normal) > 0.0 {
    return on_unit_sphere
  }
  return -on_unit_sphere
}
