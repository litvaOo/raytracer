package raytracer

import "core:fmt"
import "core:strings"
import "vendor:sdl3"

ASPECT_RATIO :: 16.0 / 9.0

WINDOW_WIDTH :: 1600.0
WINDOW_HEIGHT :: WINDOW_WIDTH/ASPECT_RATIO

VIEWPORT_HEIGHT :: 2.0
VIEWPORT_WIDTH :: VIEWPORT_HEIGHT * (WINDOW_WIDTH/WINDOW_HEIGHT)

FOCAL_LENGTH :: 1.0

SAMPLES_PER_PIXEL :: 10
PIXEL_SAMPLE_SCALE :: 1.0/SAMPLES_PER_PIXEL

MAX_DEPTH :: 50

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

  color_buffer := make([dynamic]u32, u32(WINDOW_HEIGHT*WINDOW_WIDTH), context.allocator)
  texture := sdl3.CreateTexture(
    renderer,
    sdl3.PixelFormat.RGBA8888,
    sdl3.TextureAccess.STREAMING,
    WINDOW_WIDTH,
    WINDOW_HEIGHT) 

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

  material_ground, material_center, material_left, material_right : Material
  material_ground = Lambertian{Vector{0.8, 0.8, 0.0}}
  material_center = Lambertian{Vector{0.1, 0.2, 0.5}}
  material_left = Metal{Vector{0.8, 0.8, 0.8}, 0.3}
  material_right = Metal{Vector{0.8, 0.6, 0.2}, 1.0}

  world := [4]Hittable{
    Sphere{Vector{0, -100.5, -1}, 100, &material_ground},
    Sphere{Vector{0, 0, -1.2}, 0.5, &material_center},
    Sphere{Vector{-1.0, 0.0, -1.0}, 0.5, &material_left},
    Sphere{Vector{1.0, 0.0, -1.0}, 0.5, &material_right},
  }

  for j := 0; j < WINDOW_HEIGHT; j += 1 {
    for i := 0; i < WINDOW_WIDTH; i += 1 {
      pixel_color_vector := Vector{0, 0, 0}
      for sample := 0; sample < SAMPLES_PER_PIXEL; sample += 1 {
        ray := get_ray(f64(i), f64(j), pixel_xy_loc, pixel_delta_u, pixel_delta_v, &camera_center)
        pixel_color_vector += ray_color(&ray, &world, MAX_DEPTH)
      }
      pixel_color_vector *= PIXEL_SAMPLE_SCALE
      pixel_color := convert_vector_to_color(&pixel_color_vector)
      color_buffer[WINDOW_WIDTH*j+i] = pixel_color
    }
    sdl3.UpdateTexture(texture, nil, raw_data(color_buffer), WINDOW_WIDTH*size_of(u32))
    sdl3.RenderTexture(renderer, texture, nil, nil)
    sdl3.RenderPresent(renderer)
  }
  sdl3.RenderPresent(renderer)

  sdl3.Delay(1000)
}
