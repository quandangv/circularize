extends Node

export var step = 0.01
const min_side_count = 3
const max_side_count = 4
var step_count:int
var templates = []

func _ready():
  step_count = ceil(1/step)
  templates.resize(step_count * (max_side_count - min_side_count + 1))

func power2sharpness(value:float):
  value = exp((1-value)/5)
  return -2*(value-1)/(value+1)
func sharpness2power(value:float):
  return -log((2-value)/(value+2))*5+1

func get_shape(size, sharpness:float, side_count, resolution = 1):
  assert(side_count >= min_side_count)
  assert(side_count <= max_side_count)
  sharpness = clamp(sharpness, 0, 0.99999)
  var sharpness_index = floor(sharpness/step)
  sharpness = step * sharpness_index
  sharpness_index += (side_count - min_side_count) * step_count
  var vertex_count = max(ceil(size*resolution/2/sqrt(side_count))*2, 1)
  var sharpness_arr = templates[sharpness_index]
  if sharpness_arr == null:
    sharpness_arr = []
    templates[sharpness_index] = sharpness_arr
  if len(sharpness_arr) < vertex_count:
    sharpness_arr.resize(vertex_count)
  var template = sharpness_arr[vertex_count-1]
  if template == null:
    template = get_unit_shape(sharpness, side_count, vertex_count)
    sharpness_arr[vertex_count-1] = template
  var points = template.duplicate()
  for i in range(len(points)):
    points[i] *= size
  return points

func signed_pow(a, b):
  if a < 0:
    return -pow(-a, b)
  return pow(a, b)

func smooth_step(x:float, power:float):
  var constant = 1
  if power < 2:
    power = 4/power
    x+=1
    constant = 0
  return signed_pow(2*asin(fmod(x, 2) - 1)/PI, sqrt(power)/2) + floor(x/2)*2 + constant

const sin30 = sqrt(3)/2
func get_unit_shape(sharpness:float, side_count:int, vertex_count:int):
  var power = sharpness2power(sharpness)
  var step_count = vertex_count*side_count
  var step = float(side_count*2)/step_count
  var points = []
  match side_count:
    3:
      power = 1+(power-1)*0.75
      for i in range(step_count):
        var theta = smooth_step(i*step, power)/side_count*PI
        var floored = theta - fmod(theta, PI*2/3) - PI*2/3
        theta = theta - fmod(theta, PI*2/3)/2 + PI/6
        var c = cos(theta)
        var s = sin(theta) * sin30
        var coord1 = max(c, 0)
        var coord2 = max(-c/2 - s, 0)
        var coord3 = max(-c/2 + s, 0)
        var length = 1/pow(pow(abs(coord1), power) + pow(abs(coord2), power) + pow(abs(coord3), power), 1/power)
        points.append(Vector2(length, 0).rotated(theta) + Vector2(2.0/3, 0).rotated(floored))
    4:
      for i in range(step_count):
        var theta = smooth_step(i*step, power)/side_count*PI
        var length = 1/pow(pow(abs(sin(theta)), power) + pow(abs(cos(theta)), power), 1/power)
        points.append(Vector2(length, 0).rotated(theta))
  return points
