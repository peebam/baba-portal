class_name Portal extends StaticBody3D
## Portals works in pair.
##
## The WallDetector : Detect the walls behind the portal.
## The PlayerDetector : Detect when the player arrived near the portal. Then the collision shape of the
## walls behind the portal are disabled.

signal object_crossed(object: Node3D, current_position: Vector3, current_rotation: Quaternion, new_position: Vector3, new_rotation: Quaternion)
signal object_entered(object: Node3D, portal: Portal)
signal object_exited(object: Node3D, portal: Portal, to_linked_portal: bool)

const DEFAULT_UP_DIRECTION := Vector3.UP
const EXTRA_CULL_MARGIN_MAX := 16384.0
const EXTRA_CULL_MARGIN_MIN := 0.0

@export_category("General")
@export_color_no_alpha var main_color := Color.AQUA

@export_category("Cull masks")
@export_flags_3d_render var default_cull_mask := 0
@export_flags_3d_render var level_cull_mask := 0

@export_category("Layers")
@export_flags_3d_render var frame_layers := 0
@export_flags_3d_render var technical_layers := 0

@export_category("Link")
@export var linked_portal : Portal

@export_category("Recursion")
@export_range(1, 10) var view_recursion := 4
@export_color_no_alpha var transparent_color : Color = Color.AQUA

var _cameras: Array[PortalCamera] = []
var _extra_cull_mask := EXTRA_CULL_MARGIN_MIN : set = _set_extra_cull_mask
var _objects: Array[Node3D] = []
var _walls_behind: Array[Wall] = []

@onready var _collision_shape: CollisionShape3D = $CollisionShape
@onready var _display_close: MeshInstance3D = $Display/Close
@onready var _display_frame: PortalFrame = $Display/Frame
@onready var _display_technical: MeshInstance3D = $Display/Technical
@onready var _objects_detector: ShapeCast3D = $ObjectsDetector
@onready var _walls_detector: ShapeCast3D = $WallsDetector

func _ready() -> void:
	_create_cameras()

	var technical_material: Material = load("res://materials/portal_technical_material.tres").duplicate(true)
	technical_material.albedo_color = transparent_color

	_display_frame.main_color = main_color
	_display_technical.material_override = technical_material

	_display_close.layers = technical_layers
	_display_frame.layers = technical_layers | frame_layers
	_display_technical.layers = technical_layers

	get_tree().get_root().size_changed.connect(_on_viewport_size_changed)
	_update_viewport_size()
	_update_walls_behind()

	if visible:
		display()
	else:
		dispose()


func _physics_process(_delta: float) -> void:
	if not visible:
		return

	_check_crosser()

# Public

func display() -> void:
	visible = true
	_display_close.visible = true

	await _unset_from_walls_behind()
	_update_walls_behind()
	await _set_to_walls_behind()

	_try_open()


func dispose() -> void:
	_display_close.visible = true

	await _unset_from_walls_behind()

	linked_portal._close()
	visible = false


func get_linked_position(object_position: Vector3) -> Vector3:
	return _get_linked_position(
		position,
		quaternion,
		linked_portal.position,
		linked_portal.quaternion,
		object_position
	)


func get_linked_rotation(object_rotation: Quaternion) -> Quaternion:
	return _get_linked_rotation(
		quaternion,
		linked_portal.quaternion,
		object_rotation
	)


func get_nb_cameras() -> int:
	return _cameras.size()


func get_texture() -> Texture:
	return _cameras[0].get_texture()


func get_textures() -> Array[Texture]:
	var textures: Array[Texture] = []
	textures.assign(
		_cameras.map(
			func (c: PortalCamera):
			return c.get_texture())
	)
	return textures


func is_behind(object_position: Vector3) -> bool:
	var portal_plane := Plane(basis.z)
	return portal_plane.distance_to(position - object_position) <= 0


func set_post_processes_view_parameters(view_parameters: Array[View.Parameters]) -> void:
	for i in _cameras.size():
		_cameras[i].view_parameters = view_parameters[i % view_parameters.size()]
		_cameras[i].post_process_transparent_colors = [transparent_color]


func update(camera_position: Vector3, camera_rotation: Quaternion) -> void:
	var camera_position_rec := camera_position
	var camera_rotation_rec := camera_rotation

	for i in _cameras.size():
		camera_position_rec = get_linked_position(camera_position_rec)
		camera_rotation_rec = get_linked_rotation(camera_rotation_rec)
		_cameras[i].update_camera(camera_position_rec, camera_rotation_rec)

# Privates

func _check_crosser() -> void:
	var colliders := _detect_crossers()
	for collider in colliders:
		if !_objects.has(collider):
			object_entered.emit(collider, self)
			_objects.append(collider)

		if is_behind(collider.cross_position):
			var new_position := get_linked_position(collider.position)
			var new_rotation := get_linked_rotation(collider.quaternion)
			object_crossed.emit(
				collider,
				new_position,
				new_rotation)
			_objects.erase(collider)
			object_exited.emit(collider, self, true)


	for object in _objects:
		if !colliders.has(object):
			_objects.erase(object)
			object_exited.emit(object, self, false)


func _close() -> void:
	if visible:
		_display_close.visible = true
		_collision_shape.set_deferred("disabled", false)


func _create_camera() -> PortalCamera:
	var camera := PortalCamera.new_scene()
	add_child(camera)
	camera.default_cull_mask = (default_cull_mask | level_cull_mask | technical_layers)
	return camera


func _create_cameras() -> void:
	for i in view_recursion:
		var camera := _create_camera()
		_cameras.push_back(camera)


func _detect_crossers() -> Array[Node3D]:
	_objects_detector.force_shapecast_update()

	var colliders: Array[Node3D] = []
	var nb_objects := _objects_detector.get_collision_count()
	for i in nb_objects:
		var collider: Node3D = _objects_detector.get_collider(i)
		if collider.is_in_group("crosser"):
			colliders.append(_objects_detector.get_collider(i))

	return colliders


func _get_linked_position(
		portal_position: Vector3,
		portal_rotation: Quaternion,
		linked_portal_position: Vector3,
		linked_portal_rotation: Quaternion,
		object_position: Vector3) -> Vector3:
	var symetry_up := Quaternion(basis.y, PI)
	var object_position_relative_to_portal := portal_position - object_position
	var linked_object_position := linked_portal_position - linked_portal_rotation * (portal_rotation.inverse()  * (symetry_up * object_position_relative_to_portal))
	return linked_object_position


func _get_linked_rotation(
		portal_rotation: Quaternion,
		linked_portal_rotation: Quaternion,
		object_rotation: Quaternion) -> Quaternion:
	var symetry_up := Quaternion(basis.y, PI)
	var object_linked_rotation := linked_portal_rotation * (portal_rotation.inverse() * (symetry_up * object_rotation))
	return object_linked_rotation


func _get_walls_behind() -> Array[Wall]:
	_walls_detector.force_shapecast_update()

	var walls_behind: Array[Wall] = []
	for i in _walls_detector.get_collision_count():
		var wall: Wall = _walls_detector.get_collider(i)
		var dot := roundi(wall.get_normal().dot(basis.y))
		if dot == 0:
			walls_behind.push_back(wall)

	return walls_behind


func _open() -> bool:
	if visible:
		_display_close.visible = false
		_collision_shape.set_deferred("disabled", true)
		return true
	return false


func _set_extra_cull_mask(value: float) -> void:
	if _extra_cull_mask == value:
		return

	_extra_cull_mask = value
	_display_technical.extra_cull_margin = _extra_cull_mask
	_display_close.extra_cull_margin = _extra_cull_mask


func _set_to_walls_behind() -> void:
	for wall in _walls_behind:
		await wall.set_portal(self)


func _try_open() -> void:
	if linked_portal._open():
		_open()
	else:
		_close()


func _unset_from_walls_behind() -> void:
	for wall in _walls_behind:
		await wall.unset_portal(self)


func _update_viewport_size() -> void:
	var viewport_size := get_tree().get_root().get_viewport().get_visible_rect().size
	for i in _cameras.size():
		_cameras[i].size = viewport_size


func _update_walls_behind() -> void:
	_walls_behind = _get_walls_behind()

# Signals

func _on_object_entered(_object: Node3D, _portal: Portal) -> void:
	if not visible:
		return

	linked_portal._extra_cull_mask = EXTRA_CULL_MARGIN_MAX


func _on_object_exited(_object: Node3D, _portal: Portal, to_linked_portal: bool) -> void:
	if not visible:
		return

	if not to_linked_portal:
		linked_portal._extra_cull_mask = EXTRA_CULL_MARGIN_MIN
		_extra_cull_mask = EXTRA_CULL_MARGIN_MIN


func _on_viewport_size_changed() -> void:
	_update_viewport_size()
