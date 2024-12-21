class_name PortalCamera extends SubViewport

static var _scene : PackedScene = preload("res://scenes/portal/portal_camera.tscn")

var post_process_filter: PostProcess.Filter = null : set = set_post_process_filter
var post_process_transparent_colors : Array[Color] = [Color.TRANSPARENT, Color.TRANSPARENT] : set = set_post_process_transparent_colors


static func new_scene() -> PortalCamera:
	return _scene.instantiate()

var cull_mask := 0 : set = set_cull_mask

func _ready() -> void:
	var camera := get_viewport().get_camera_3d()
	$Camera.fov = camera.fov

# Public

func set_cull_mask(value: int) -> void:
	if cull_mask == value:
		return

	cull_mask = value
	$Camera.cull_mask = value


func set_post_process_filter(value: PostProcess.Filter) -> void:
	if post_process_filter == value:
		return

	post_process_filter = value
	%PostProcess.filter = post_process_filter


func set_post_process_transparent_colors(value: Array[Color]) -> void:
	if post_process_transparent_colors == value:
		return

	post_process_transparent_colors = value
	%PostProcess.transparent_colors = post_process_transparent_colors


func update_camera(camera_position: Vector3, camera_rotation: Quaternion) -> void:
	$Camera.quaternion = camera_rotation
	$Camera.position = camera_position
