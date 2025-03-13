extends Node3D

signal portal_crossed(from_portal_id: Level.PORTAL_IDS)
signal room_entered()
signal level_set()

var level: Level : set = set_level

var _current_cmera_position: Vector3
var _current_cmera_quaternion: Quaternion
var _portal_activated: Portal = null
var _room : Level.Room : set = _set_room

@onready var _main_post_process: PostProcess = %PostProcess
@onready var _main_viewport: SubViewport = %MainViewport
@onready var _player: Player = %Player
@onready var _player_mirror: Player = %PlayerMirror
@onready var _portal_a: Portal = %PortalA
@onready var _portal_b: Portal = %PortalB
@onready var _portal_placeholder: PortalPlaceholder = %PortalPlaceholder
@onready var _render_texture: TextureRect = $Render/RenderTexture

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_portal_a.object_crossed.connect(_on_portal_object_crossed.bind(Level.PORTAL_IDS.A))
	_portal_a.object_entered.connect(_on_portal_object_entered)
	_portal_a.object_exited.connect(_on_portal_object_exited)

	_portal_b.object_crossed.connect(_on_portal_object_crossed.bind(Level.PORTAL_IDS.B))
	_portal_b.object_entered.connect(_on_portal_object_entered)
	_portal_b.object_exited.connect(_on_portal_object_exited)

	_player.moved.connect(_on_player_moved)
	_player.target_set.connect(_on_player_target_set)
	_player.target_unset.connect(_on_player_target_unset)

	var portal_a_textures := _portal_a.get_textures()
	_render_texture.material.set_shader_parameter("portal_a_textures", portal_a_textures)
	_render_texture.material.set_shader_parameter("portal_a_nb_textures", portal_a_textures.size())
	_render_texture.material.set_shader_parameter("portal_a_transparent_color", _portal_a.transparent_color)

	var portal_b_textures := _portal_b.get_textures()
	_render_texture.material.set_shader_parameter("portal_b_textures", portal_b_textures)
	_render_texture.material.set_shader_parameter("portal_b_nb_textures", portal_b_textures.size())
	_render_texture.material.set_shader_parameter("portal_b_transparent_color", _portal_b.transparent_color)

	_render_texture.material.set_shader_parameter("player_view_texture", _main_viewport.get_texture())

	var transparents_color: Array[Color] = [_portal_a.transparent_color, _portal_b.transparent_color]
	_main_post_process.transparent_colors = transparents_color


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()

	if event.is_action_pressed("create_portal_a"):
		_try_put_portal(_portal_a)

	if event.is_action_pressed("create_portal_b"):
		_try_put_portal(_portal_b)

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


func _enter_next_room(portal_id: Level.PORTAL_IDS) -> void:
	_room = level.get_next_room(_room.id, portal_id)


func _put_portal(portal: Portal, position_: Vector3, quaternion_: Quaternion) -> void:
	portal.position = position_
	portal.quaternion = quaternion_
	_update_portal_layers(portal)
	_update_portal_viewer(portal)
	_update_portal_viewer(portal.linked_portal)

	await portal.display()


func _reset_portals() -> void:
	await _portal_a.dispose()
	await _portal_b.dispose()


func _set_portal_filter(portal: Portal, filter: View.Filter):
	portal.post_process_filter = filter


func _set_room(value: Level.Room) -> void:
	if _room == value:
		return

	_room = value
	room_entered.emit()


func _try_put_portal(portal: Portal) -> void:
	if not _portal_placeholder.active:
		return

	_put_portal(
		portal,
		_portal_placeholder.position,
		_portal_placeholder.quaternion
	)


func _update_portal_viewer(portal: Portal) -> void:
	portal.update(_current_cmera_position, _current_cmera_quaternion)


func _update_portal_filters(portal: Portal, portal_id: Level.PORTAL_IDS) -> void:
	var filters: Array[View.Parameters] = []
	var nb_cameras := portal.get_nb_cameras()

	var room = _room
	for i in nb_cameras:
		room = level.get_next_room(room.id, portal_id)
		var view_parameters := View.Parameters.new(
			room.filter,
			room.cull_mask
		)
		filters.append(view_parameters)

	portal.set_post_processes_view_parameters(filters)


func _update_portal_layers(portal: Portal) -> void:
	var walls: Array[Wall] = $Level.get_walls()
	for wall in walls:
		var layers = wall.layers
		if not portal.is_behind(wall.position):
			layers |= portal.linked_portal.level_cull_mask
		else:
			layers &= ~portal.linked_portal.level_cull_mask
		wall.layers = layers

# Signals

func _on_level_set() -> void:
	_reset_portals()
	_enter_level()


func _on_player_moved(camera_transform: Transform3D) -> void:
	_current_cmera_position = camera_transform.origin
	_current_cmera_quaternion = camera_transform.basis.get_rotation_quaternion()

	_portal_a.update(_current_cmera_position, _current_cmera_quaternion)
	_portal_b.update(_current_cmera_position, _current_cmera_quaternion)

	if _player_mirror.visible:
		var next_position := _portal_activated.get_linked_position(_player.position)
		var next_rotation := _portal_activated.get_linked_rotation(_player.quaternion)
		_player_mirror.position = next_position
		_player_mirror.quaternion = next_rotation


func _on_player_target_set(target_position: Vector3, target_normal: Vector3, view_direction: Vector3) -> void:
	var up_direction := _player.up_direction
	_portal_placeholder.move(
		target_position,
		target_normal,
		view_direction,
		up_direction)


func _on_player_target_unset() -> void:
	_portal_placeholder.active = false


func _on_portal_object_crossed(object: Node3D, new_position: Vector3, new_rotation: Quaternion, portal_id: Level.PORTAL_IDS) -> void:
	if object is Player:
		_player_mirror.position = object.position
		_player_mirror.quaternion = object.quaternion

		object.set_position_orientation(new_position, new_rotation)
		object.set_gravity_direction(-object.basis.y)

		portal_crossed.emit(portal_id)


func _on_portal_object_entered(object: Node3D, portal: Portal) -> void:
	if object is Player:
		_portal_activated = portal
		_player_mirror.visible = true


func _on_portal_object_exited(object: Node3D, _portal: Portal, _to_linked_portal: bool) -> void:
	if object is Player:
		_portal_activated = null
		_player_mirror.visible = false


func _on_room_entered() -> void:
	_update_portal_filters(_portal_a, Level.PORTAL_IDS.A)
	_update_portal_filters(_portal_b, Level.PORTAL_IDS.B)

	_main_post_process.filter = _room.filter
	_player.camera_cull_mask = _room.cull_mask


func _on_portal_crossed(portal_id: Level.PORTAL_IDS) -> void:
	_enter_next_room(portal_id)
