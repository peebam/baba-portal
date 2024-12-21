class_name PostProcess extends CanvasLayer

signal properties_changed

static var _scene : PackedScene = preload("res://scenes/post_process.tscn")

static func new_scene() -> PostProcess:
	return _scene.instantiate()

var filter: Filter = NoFilter.new() : set = set_filter
var transparent_colors : Array[Color] = [Color.TRANSPARENT, Color.TRANSPARENT] : set = set_transparent_colors

var _material : ShaderMaterial

func _ready() -> void:
	_material = load("res://materials/post_process_material.tres").duplicate(true)
	$Texture.material = _material

# Public

func set_filter(value: Filter) -> void:
	if filter == value:
		return

	if value == null:
		value = NoFilter.new()

	filter = value
	properties_changed.emit()


func set_transparent_colors(value: Array[Color]) -> void:
	if transparent_colors == value:
		return

	transparent_colors = value
	properties_changed.emit()

# Private

func _apply_filter() -> void:
	_material.set_shader_parameter("transparent_colors", transparent_colors)
	filter.apply(_material)

# Signals

func _on_properties_changed() -> void:
	_apply_filter()

# Classes

class Filter:
	var shader : Shader
	func apply(material: ShaderMaterial) -> void:
		pass


class ColorFilter extends Filter:
	var color := Color.TRANSPARENT

	func _init(color_: Color) -> void:
		color = color_
		shader = preload("res://shaders/post_process/color_post_process_filter.gdshader")


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader
		material.set_shader_parameter("filter_color", color)


class NoFilter extends Filter:
	func _init() -> void:
		shader = preload("res://shaders/post_process/empty_post_process_filter.gdshader")


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader


class SquareFilter extends Filter:
	var square_size := 5

	func _init(square_size_: int) -> void:
		square_size = square_size_
		shader = preload("res://shaders/post_process/square_post_process_filter.gdshader")


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader
		material.set_shader_parameter("square_size", square_size)
