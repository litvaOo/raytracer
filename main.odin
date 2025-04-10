package raytracer

import "core:fmt"
import "core:strings"
import "core:math"
import "vendor:sdl3"

WINDOW_WIDTH :: 1024
WINDOW_HEIGHT :: 1024

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

main :: proc() {
  assert(sdl3.Init(sdl3.INIT_VIDEO) == true, strings.clone_from_cstring(sdl3.GetError()))
  defer sdl3.Quit()

  window := sdl3.CreateWindow("raytracer", WINDOW_WIDTH, WINDOW_HEIGHT, sdl3.WINDOW_BORDERLESS);
  defer sdl3.DestroyWindow(window);

  renderer := sdl3.CreateRenderer(window, nil)
  assert(renderer != nil, strings.clone_from_cstring(sdl3.GetError()))
  defer sdl3.DestroyRenderer(renderer)

  assert(sdl3.SetRenderDrawBlendMode(renderer, sdl3.BlendMode{.BLEND}) == true, strings.clone_from_cstring(sdl3.GetError()))

  color_buffer := [WINDOW_WIDTH*WINDOW_HEIGHT]u32{}
  texture := sdl3.CreateTexture(renderer, sdl3.PixelFormat.RGBA8888, sdl3.TextureAccess.STREAMING, WINDOW_WIDTH, WINDOW_HEIGHT)
  
  for j := 0; j < WINDOW_HEIGHT; j += 1 {
    for i := 0; i < WINDOW_WIDTH; i += 1 {
      r := u32(255.999*(f64(i)/(WINDOW_WIDTH-1)))
      g := u32(255.999*(f64(j)/(WINDOW_HEIGHT-1)))
      b := u32(0)
      color: u32 =  r << 24 | g << 16 | b << 8 | 255
      color_buffer[WINDOW_WIDTH*j+i] = color
    }
  }
  
  sdl3.UpdateTexture(texture, nil, &color_buffer, WINDOW_WIDTH*size_of(u32))
  sdl3.RenderTexture(renderer, texture, nil, nil)
  sdl3.RenderPresent(renderer)
  sdl3.Delay(1000)

  v1 := Vector{1, 1, 1}
  v2 := Vector{2, 2, 2}
  fmt.println(vector_length(&v2))
}
