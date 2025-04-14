package raytracer

import "core:fmt"
import "core:strings"
import "vendor:sdl3"

ASPECT_RATIO :: 16.0 / 9.0

WINDOW_WIDTH :: 800.0
WINDOW_HEIGHT :: WINDOW_WIDTH/ASPECT_RATIO

VIEWPORT_HEIGHT :: 2.0
VIEWPORT_WIDTH :: VIEWPORT_HEIGHT * (WINDOW_WIDTH/WINDOW_HEIGHT)

FOCAL_LENGTH :: 1.0

main :: proc() {
  // SDL_INIT
  assert(sdl3.Init(sdl3.INIT_VIDEO) == true, strings.clone_from_cstring(sdl3.GetError()))
  defer sdl3.Quit()

  window := sdl3.CreateWindow("raytracer", WINDOW_WIDTH, WINDOW_HEIGHT, sdl3.WINDOW_BORDERLESS);
  defer sdl3.DestroyWindow(window);

  renderer := sdl3.CreateRenderer(window, nil)
  assert(renderer != nil, strings.clone_from_cstring(sdl3.GetError()))
  defer sdl3.DestroyRenderer(renderer)

  assert(sdl3.SetRenderDrawBlendMode(renderer, sdl3.BlendMode{.BLEND}) == true, strings.clone_from_cstring(sdl3.GetError()))

  color_buffer := [u32(WINDOW_WIDTH*WINDOW_HEIGHT)]u32{}
  texture := sdl3.CreateTexture(renderer, sdl3.PixelFormat.RGBA8888, sdl3.TextureAccess.STREAMING, WINDOW_WIDTH, WINDOW_HEIGHT)
  
  // CAMERA
  camera_center := Vector{0, 0, 0}

  viewport_u := Vector{VIEWPORT_WIDTH, 0, 0}   // left to right
  viewport_v := Vector{0, -VIEWPORT_HEIGHT, 0} // top to bottom

  // pixel-to-pixel distance
  pixel_delta_u := viewport_u/WINDOW_WIDTH
  pixel_delta_v := viewport_v/WINDOW_HEIGHT

  // calculate top-left pixel position
  viewport_upper_left := camera_center - Vector{0, 0, FOCAL_LENGTH} - viewport_u/2 - viewport_v/2 
  pixel_xy_loc := viewport_upper_left + 0.5*(pixel_delta_u+pixel_delta_v)

  world := [2]Hittable{
    Sphere{Vector{0, 0, -1}, 0.5},
    Sphere{Vector{0, -100.5, -1}, 100}
  }

  for j := 0; j < WINDOW_HEIGHT; j += 1 {
    for i := 0; i < WINDOW_WIDTH; i += 1 {
      pixel_center := pixel_xy_loc + (f64(i) * pixel_delta_u) + (f64(j) * pixel_delta_v)
      ray_direction := pixel_center - camera_center
      r := Ray{&camera_center, &ray_direction}
      
      pixel_color := ray_color(&r, &world)
      color_buffer[WINDOW_WIDTH*j+i] = pixel_color
    }
    sdl3.UpdateTexture(texture, nil, &color_buffer, WINDOW_WIDTH*size_of(u32))
    sdl3.RenderTexture(renderer, texture, nil, nil)
    sdl3.RenderPresent(renderer)
  }
  sdl3.RenderPresent(renderer)
  
  sdl3.Delay(1000)
}
