package raytracer

import "core:math"

Vector :: distinct[3]f64

vector_length :: proc (v: ^Vector) -> f64 {
  return math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
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

