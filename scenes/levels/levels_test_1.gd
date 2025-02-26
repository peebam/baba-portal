extends Level

func _init() -> void:

	var room0 := Level.Room.new(
		"0", "A", "B", PostProcess.NoFilter.new()
	)

	var roomA := Level.Room.new(
		"A", "B", "0", PostProcess.ColorFilter.new(Color(1, 0, 0, 0.3))
	)

	var roomB := Level.Room.new(
		"B", "0", "A", PostProcess.ColorFilter.new(Color(0, 1, 0, 0.3))
	)

	_rooms = [room0, roomA, roomB]

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
