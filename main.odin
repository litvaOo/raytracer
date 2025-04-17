package raytracer

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:thread"
import "core:strings"
import "vendor:sdl3"
import vmem "core:mem/virtual"

ASPECT_RATIO :: 16.0 / 9.0

WINDOW_WIDTH :: 1600.0
WINDOW_HEIGHT :: WINDOW_WIDTH/ASPECT_RATIO

SAMPLES_PER_PIXEL :: 500
PIXEL_SAMPLE_SCALE :: 1.0/SAMPLES_PER_PIXEL

MAX_DEPTH :: 50

VERTICAL_FOV :: 20.0

ThreadData :: struct {
  start, end: int,
  defocus_angle: f64,
  pixel_xy_loc, pixel_delta_u, pixel_delta_v,
  camera_center, defocus_disk_v, defocus_disk_u: ^Vector,
  world: [dynamic]Hittable,
  color_buffer: [dynamic]u32,

}

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
  look_from := Vector{13, 2, 3}
  look_at := Vector{0, 0, 0}
  v_up := Vector{0, 1, 0}

  look_vector := look_from - look_at

  defocus_angle := 0.6
  focus_distance := 10.0

  //focal_length := vector_length(&look_vector)

  theta := math.to_radians_f64(VERTICAL_FOV)
  h := math.tan_f64(theta/2)
  viewport_height := 2 * h * focus_distance
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
  viewport_upper_left := camera_center - (focus_distance * w) - viewport_u/2 - viewport_v/2
  pixel_xy_loc := viewport_upper_left + 0.5*(pixel_delta_u+pixel_delta_v)

  defocus_radius := focus_distance * math.tan_f64(math.to_radians_f64(defocus_angle/2))
  defocus_disk_u := u * defocus_radius
  defocus_disk_v := v * defocus_radius

  ground_material : Material
  ground_material = Lambertian{Vector{0.5, 0.5, 0.5}}

  world := make([dynamic]Hittable, 121, context.allocator)
  append(&world, Sphere{Vector{0, -1000, 0}, 1000, &ground_material})

  for a := -11.0; a < 11; a += 1 {
    for b := -11.0; b < 11; b += 1 {
      choose_mat := rand.float64()
      center := Vector{a + 0.9*rand.float64(), 0.2, b + 0.9*rand.float64()}

      test_vector := center - Vector{3, 0.2, 0}
      if (vector_length(&test_vector) > 0.9) {
          sphere_material := new(Material)

          if choose_mat < 0.8 {
            albedo := vector_random() * vector_random()
            sphere_material^ = Lambertian{albedo}
            append(&world, Sphere{center, 0.2, sphere_material})
          } else if choose_mat < 0.95 {
            albedo := vector_random_interval(0.5, 1)
            fuzz := random_float(0, 0.5)
            sphere_material^ = Metal{albedo, fuzz}
            append(&world, Sphere{center, 0.2, sphere_material})
          } else {
            sphere_material^ = Dielectric{1.5}
            append(&world, Sphere{center, 0.2, sphere_material})
          }
      }
    }
  }

  material_1, material_2, material_3 : Material
  material_1 = Dielectric{1.5}
  material_2 = Lambertian{Vector{0.4, 0.2, 0.1}}
  material_3 = Metal{Vector{0.7, 0.6, 0.5}, 0.0}
  append(&world, Sphere{Vector{0, 1, 0}, 1.0, &material_1})
  append(&world, Sphere{Vector{-4, 1, 0}, 1.0, &material_2})
  append(&world, Sphere{Vector{4, 1, 0}, 1.0, &material_3})

  threadPool := make([dynamic]^thread.Thread, 0)
  for i := 0; i < WINDOW_HEIGHT; i += WINDOW_HEIGHT/30 + (16-((int(WINDOW_HEIGHT/30))%16)) {
    thr := thread.create(worker)
    data := new(ThreadData)
    data ^= ThreadData{
      i, i+WINDOW_HEIGHT/30 + (16-((int(WINDOW_HEIGHT/30))%16)), defocus_angle,
      &pixel_xy_loc, &pixel_delta_u, &pixel_delta_v,
      &camera_center, &defocus_disk_v, &defocus_disk_u,
      world, color_buffer,
    }
    if thr != nil {
      thr.init_context = context
      thr.user_index = i
      thr.data = data
      append(&threadPool, thr)

      thread.start(thr)
    }
  }
    for len(threadPool) > 0 {
        for i := 0; i < len(threadPool); {
            t := threadPool[i]
            if thread.is_done(t) {
                thread.destroy(t)
                ordered_remove(&threadPool, i)
            } else {
                i += 1 
            }
        }
    }
  sdl3.UpdateTexture(texture, nil, raw_data(color_buffer), WINDOW_WIDTH*size_of(u32))
  sdl3.RenderTexture(renderer, texture, nil, nil)
  sdl3.RenderPresent(renderer)
  sdl3.Delay(1000)
}

worker :: proc(t: ^thread.Thread) {
  thread_data := (cast(^ThreadData)t.data)
  arena: vmem.Arena
  arena_alloc := vmem.arena_allocator(&arena)
  for j := min(thread_data.start, WINDOW_HEIGHT); j < min(thread_data.end, WINDOW_HEIGHT); j += 1{ 
    for i := 0; i < WINDOW_WIDTH; i += 1 {
      pixel_color_vector := Vector{0, 0, 0}
      for sample := 0; sample < SAMPLES_PER_PIXEL; sample += 1 {
        ray := get_ray(
               f64(i),
               f64(j),
               thread_data.defocus_angle,
               thread_data.pixel_xy_loc,
               thread_data.pixel_delta_u,
               thread_data.pixel_delta_v,
               thread_data.camera_center,
               thread_data.defocus_disk_v,
               thread_data.defocus_disk_u,
               arena_alloc)
        pixel_color_vector += ray_color(&ray, thread_data.world, MAX_DEPTH, arena_alloc)
      }
      pixel_color_vector *= PIXEL_SAMPLE_SCALE
      pixel_color := convert_vector_to_color(&pixel_color_vector)
      thread_data.color_buffer[WINDOW_WIDTH*j+i] = pixel_color
    }
    vmem.arena_free_all(&arena)
  }  
}
