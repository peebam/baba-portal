extends Node3D

signal level_set()
signal room_entered()

var level: Level : set = set_level

var _current_camera_position: Vector3
var _current_camera_rotation: Quaternion
var _portal_activated: Portal = null
var _room : Level.Room : set = _set_room

@onready var _main_post_process: PostProcess = %PostProcess
@onready var _main_viewport: SubViewport = %MainViewport
@onready var _player: Player = %Player

@onready var _player_mirror: Player = %PlayerMirror

@onready var _portal_placeholder: PortalPlaceholder = %PortalPlaceholder
@onready var _render_texture: TextureRect = $Render/RenderTexture

@onready var _portals: Portals = $Portals

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_player.moved.connect(_on_player_moved)
	_player.target_set.connect(_on_player_target_set)
	_player.target_unset.connect(_on_player_target_unset)

	var portal_a_textures := _portals.portal_a.get_textures()
	var portal_a_transparent_color := _portals.portal_a.transparent_color
	_render_texture.material.set_shader_parameter("portal_a_textures", portal_a_textures)
	_render_texture.material.set_shader_parameter("portal_a_nb_textures", portal_a_textures.size())
	_render_texture.material.set_shader_parameter("portal_a_transparent_color", portal_a_transparent_color)

	var portal_b_textures := _portals.portal_b.get_textures()
	var portal_b_transparent_color := _portals.portal_b.transparent_color
	_render_texture.material.set_shader_parameter("portal_b_textures", portal_b_textures)
	_render_texture.material.set_shader_parameter("portal_b_nb_textures", portal_b_textures.size())
	_render_texture.material.set_shader_parameter("portal_b_transparent_color", portal_b_transparent_color)

	_render_texture.material.set_shader_parameter("player_view_texture", _main_viewport.get_texture())

	var transparents_color: Array[Color] = [portal_a_transparent_color, portal_b_transparent_color]
	_main_post_process.transparent_colors = transparents_color


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()

	if event.is_action_pressed("create_portal_a"):
		_try_put_portal(_portals.portal_a)

	if event.is_action_pressed("create_portal_b"):
		_try_put_portal(_portals.portal_b)

	if event.is_action_pressed("reset_portals"):
		_reset_portals()

	_main_viewport.push_input(event)

# Public

func set_level(value: Level) -> void:
	if level != null:
		remove_child(level)

	level = value
	add_child(level)
	level_set.emit()

# Private

func _enter_level() -> void:
	_player.position = level.start_postion
	_player.quaternion = level.start_quaternion
	_room = level.get_first_room()


func _enter_next_room(from: Portal) -> void:
	_room = level.get_next_room(_room.id, from.id)


func _put_portal(portal: Portal, portal_position: Vector3, portal_rotation: Quaternion) -> void:
	portal.position = portal_position
	portal.quaternion = portal_rotation

	_update_portal_layers(portal)
	_update_portal_viewer(portal)
	_update_portal_viewer(portal.linked_portal)

	await portal.display()

func _reset_portals() -> void:
	await _portals.portal_a.dispose()
	await _portals.portal_b.dispose()


func _set_room(value: Level.Room) -> void:
	if _room == value:
		return

	_room = value
	room_entered.emit()


func _try_put_portal(portal: Portal) -> void:
	if not _portal_placeholder.active:
		return

	_put_portal(portal, _portal_placeholder.position, _portal_placeholder.quaternion)


func _update_portal_viewer(portal: Portal) -> void:
	portal.update(_current_camera_position, _current_camera_rotation)


func _update_portal_filters(portal: Portal) -> void:
	var filters: Array[View.Parameters] = []
	var nb_cameras := portal.get_nb_cameras()

	var room := _room
	for i in nb_cameras:
		room = level.get_next_room(room.id, portal.id)
		var view_parameters := View.Parameters.new(
			room.filter,
			room.cull_mask
		)
		filters.append(view_parameters)

	portal.set_post_processes_view_parameters(filters)


func _update_portal_layers(portal: Portal) -> void:
	level.update_layers_for_portal(portal)

# Signals

func _on_level_set() -> void:
	_reset_portals()
	_enter_level()


func _on_player_moved(camera_transform: Transform3D) -> void:
	_current_camera_position = camera_transform.origin
	_current_camera_rotation = camera_transform.basis.get_rotation_quaternion()

	_update_portal_viewer(_portals.portal_a)
	_update_portal_viewer(_portals.portal_b)

	if _portal_activated:
		var next_position := _portal_activated.get_linked_position(_player.position)
		var next_rotation := _portal_activated.get_linked_rotation(_player.quaternion)
		_player_mirror.position = next_position
		_player_mirror.quaternion = next_rotation


func _on_player_target_set(target_position: Vector3, target_normal: Vector3, view_direction: Vector3) -> void:
	var up_direction := _player.up_direction
	_portal_placeholder.move(target_position, target_normal, view_direction, up_direction)
	_portal_placeholder.active = true


func _on_player_target_unset() -> void:
	_portal_placeholder.active = false


func _on_portals_object_crossed(from: Portal, to: Portal, object: Node3D, new_position: Vector3, new_rotation: Quaternion) -> void:
	if object is Player:
		_player_mirror.position = object.position
		_player_mirror.quaternion = object.quaternion

		_portal_activated = to

		object.set_position_orientation(new_position, new_rotation)
		object.set_gravity_direction(-object.basis.y)
		_enter_next_room(from)


func _on_portals_object_entered(to: Portal, object: Node3D) -> void:
	if object is Player:
		_portal_activated = to
		_player_mirror.visible = true


func _on_portals_object_exited(_from: Portal, object: Node3D) -> void:
	if object is Player:
		_portal_activated = null
		_player_mirror.visible = false


func _on_room_entered() -> void:
	_update_portal_filters(_portals.portal_a)
	_update_portal_filters(_portals.portal_b)
	_main_post_process.filter = _room.filter
	_player.camera_cull_mask = _room.cull_mask
	level.enter_room(_room)
