extends Level

signal goal_activated

func _init() -> void:

	var room0 := Level.Room.new(
		"0", "A", "B", View.NoFilter.new()
	)

	var roomA := Level.Room.new(
		"A", "B", "0", View.ColorFilter.new(Color(1, 0, 0, 0.3))
	)

	var roomB := Level.Room.new(
		"B", "C", "0", View.ColorFilter.new(Color(0, 1, 0, 0.5))
	)

	var roomC := Level.Room.new(
		"C", "0", "A", View.ColorFilter.new(Color(0, 0, 1, 0.4)), 11
	)

	_rooms = [room0, roomA, roomB, roomC]

# Public

func get_walls() -> Array[Wall]:
	var walls: Array[Wall] = []

	var wall_nodes: Array[Node3D] = []
	wall_nodes.assign($Walls.get_children())

	var ground_nodes: Array[Node3D] = []
	ground_nodes.assign($Ground.get_children())

	var roof_nodes: Array[Node3D] = []
	roof_nodes.assign($Roof.get_children())

	walls.append_array(wall_nodes)
	walls.append_array(ground_nodes)
	walls.append_array(roof_nodes)

	return walls

# Signals

func _on_level_goal_activated() -> void:
	goal_activated.emit()
