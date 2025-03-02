class_name PostProcess extends CanvasLayer

signal properties_changed

var filter: View.Filter = View.NoFilter.new() : set = set_filter
var transparent_colors : Array[Color] = [Color.TRANSPARENT, Color.TRANSPARENT] : set = set_transparent_colors

var _material : ShaderMaterial

func _ready() -> void:
	_material = load("res://materials/post_process_material.tres").duplicate(true)
	$Texture.material = _material

# Static

static var _scene : PackedScene = preload("res://scenes/post_process.tscn")

static func new_scene() -> PostProcess:
	return _scene.instantiate()

# Public

func set_filter(value: View.Filter) -> void:
	if filter == value:
		return

	if value == null:
		value = View.NoFilter.new()

	filter = value
	properties_changed.emit()


func set_transparent_colors(value: Array[Color]) -> void:
	if transparent_colors == value:
		return

	transparent_colors = value
	properties_changed.emit()

# Private

func _update() -> void:
	_update_filter()
	_update_transparent_colors()


func _update_filter() -> void:
	filter.apply(_material)


func _update_transparent_colors():
	_material.set_shader_parameter("transparent_colors", transparent_colors)

# Signals

func _on_properties_changed() -> void:
	_update()

# Classes
