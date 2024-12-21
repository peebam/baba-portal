class_name Level extends Node3D

enum PORTAL_IDS {
	A = 0,
	B = 1
}

@onready var start_postion := Vector3.ZERO
@onready var start_quaternion := Quaternion.IDENTITY

var _rooms: Array[Level.Room]
var _rooms_by8id: Dictionary
# Public

func enter_room(room: Level.Room) -> void:
	pass


func get_first_room() -> Level.Room:
	return _rooms[0]


func get_next_room(room_id: String, portal_id: PORTAL_IDS) -> Level.Room:
	var room := _get_room(room_id)
	var next_room_id := room.get_next_room_id(portal_id)
	var next_room := _get_room(next_room_id)
	return next_room


func update_layers_for_portal(portal: Portal) -> void:
	var walls: Array[Wall] = _get_walls()
	for wall in walls:
		var layers = wall.layers
		if not portal.is_behind(wall.position):
			layers |= portal.linked_portal.level_cull_mask
		else:
			layers &= ~portal.linked_portal.level_cull_mask
		wall.layers = layers

# Private

func _get_room(id: String) -> Level.Room:
	var rooms : Array[Room] = _rooms.filter(
		func (r: Room) -> bool:
			return r.id == id
	)
	return rooms[0]


func _get_walls() -> Array[Wall]:
	return []

# Class

class Room:
	var id : String
	var portal_a_go_to : String
	var portal_b_go_to : String
	var filter : View.Filter
	var cull_mask : int

	func _init(
		id_: String,
		portal_a_go_to_: String,
		portal_b_go_to_: String,
		filter_ : View.Filter,
		cull_mask_ : int = 0
	) -> void:
		id = id_
		portal_a_go_to = portal_a_go_to_
		portal_b_go_to = portal_b_go_to_
		filter = filter_
		cull_mask = Math.value_to_bit_flags(cull_mask_)


	func get_next_room_id(portal_id: PORTAL_IDS)-> String:
		match portal_id:
			PORTAL_IDS.A:
				return portal_a_go_to
			PORTAL_IDS.B:
				return portal_b_go_to

		return ""
