package raytracer

import "core:fmt"
import "core:math"
import "core:strings"
import "vendor:sdl3"

ASPECT_RATIO :: 16.0 / 9.0

WINDOW_WIDTH :: 1600.0
WINDOW_HEIGHT :: WINDOW_WIDTH/ASPECT_RATIO

SAMPLES_PER_PIXEL :: 10
PIXEL_SAMPLE_SCALE :: 1.0/SAMPLES_PER_PIXEL

MAX_DEPTH :: 50

VERTICAL_FOV :: 90.0

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
  look_from := Vector{-2, 2, 1}
  look_at := Vector{0, 0, -1}
  v_up := Vector{0, 1, 0}

  look_vector := look_from - look_at

  focal_length := vector_length(&look_vector)

  theta := math.to_radians_f64(VERTICAL_FOV)
  h := math.tan_f64(theta/2)
  viewport_height := 2 * h * focal_length
  viewport_width := viewport_height * (WINDOW_WIDTH/WINDOW_HEIGHT)

  camera_center := look_from
  w := unit_vector(&look_vector)
  w_v_up_cross := vector_cross(&v_up, &w)
  u := unit_vector(&w_v_up_cross)
  v := vector_cross(&w, &u)

  viewport_u := viewport_width * u   // left to right
  viewport_v := viewport_height * -v // top to bottom

  // pixel-to-pixel distance
  pixel_delta_u := viewport_u/WINDOW_WIDTH
  pixel_delta_v := viewport_v/WINDOW_HEIGHT

  // calculate top-left pixel position
  //viewport_upper_left := camera_center - Vector{0, 0, FOCAL_LENGTH} - viewport_u/2 - viewport_v/2 
  viewport_upper_left := camera_center - (focal_length * w) - viewport_u/2 - viewport_v/2
  pixel_xy_loc := viewport_upper_left + 0.5*(pixel_delta_u+pixel_delta_v)



  material_ground, material_center, material_left, material_right, material_bubble : Material
  material_ground = Lambertian{Vector{0.8, 0.8, 0.0}}
  material_center = Lambertian{Vector{0.1, 0.2, 0.5}}
  material_left = Dielectric{1.50}
  material_bubble = Dielectric{1.00/1.50}
  material_right = Metal{Vector{0.8, 0.6, 0.2}, 1.0}

  world := []Hittable{
    Sphere{Vector{0, -100.5, -1}, 100, &material_ground},
    Sphere{Vector{0, 0, -1.2}, 0.5, &material_center},
    Sphere{Vector{-1.0, 0.0, -1.0}, 0.5, &material_left},
    Sphere{Vector{-1.0, 0.0, -1.0}, 0.4, &material_bubble},
    Sphere{Vector{1.0, 0.0, -1.0}, 0.5, &material_right},
  }

  //R := math.cos_f64(math.PI/4)
  //material_left, material_right : Material
  //material_left = Lambertian{Vector{0, 0, 1}}
  //material_right = Lambertian{Vector{1, 0, 0}}
  //
  //world := []Hittable{
  //  Sphere{Vector{-R, 0, -1}, R, &material_left},
  //  Sphere{Vector{R, 0, -1}, R, &material_right}
  //}

  for j := 0; j < WINDOW_HEIGHT; j += 1 {
    for i := 0; i < WINDOW_WIDTH; i += 1 {
      pixel_color_vector := Vector{0, 0, 0}
      for sample := 0; sample < SAMPLES_PER_PIXEL; sample += 1 {
        ray := get_ray(f64(i), f64(j), pixel_xy_loc, pixel_delta_u, pixel_delta_v, &camera_center)
        pixel_color_vector += ray_color(&ray, world, MAX_DEPTH)
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
