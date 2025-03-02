class_name PortalCamera extends SubViewport

static var _scene : PackedScene = preload("res://scenes/portal/portal_camera.tscn")

var cull_mask := 0 : set = set_cull_mask
var post_process_transparent_colors : Array[Color] = [Color.TRANSPARENT, Color.TRANSPARENT] : set = set_post_process_transparent_colors
var view_parameters: View.Parameters = null : set = set_view_parameters

static func new_scene() -> PortalCamera:
	return _scene.instantiate()

func _ready() -> void:
	var camera := get_viewport().get_camera_3d()
	$Camera.fov = camera.fov

# Public

func set_cull_mask(value: int) -> void:
	if cull_mask == value:
		return

	cull_mask = value
	$Camera.cull_mask = value


func set_post_process_transparent_colors(value: Array[Color]) -> void:
	if post_process_transparent_colors == value:
		return

	post_process_transparent_colors = value
	%PostProcess.transparent_colors = post_process_transparent_colors


func set_view_parameters(value: View.Parameters) -> void:
	if view_parameters == value:
		return

	view_parameters = value
	%PostProcess.filter = view_parameters.filter


func update_camera(camera_position: Vector3, camera_rotation: Quaternion) -> void:
	$Camera.quaternion = camera_rotation
	$Camera.position = camera_position
