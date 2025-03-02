class_name PortalFrame extends Node3D

@export_flags_3d_render var layers := 0 : set = set_layers

var main_color := Color.BLACK : set = set_main_color

var _material : StandardMaterial3D = load("res://materials/portal_frame_material.tres").duplicate(true)

func _ready() -> void:
	$Cube.material_override = _material

# Public

func set_main_color(value: Color) -> void:
	main_color = value
	_material.emission = main_color
	_material.albedo_color = main_color
	if main_color.a < 1.0:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func set_layers(value: int) -> void:
	if layers == value:
		return

	layers = value
	$Cube.layers = value
