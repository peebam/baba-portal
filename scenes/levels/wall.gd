class_name Wall extends StaticBody3D

@export_flags_3d_render var layers = 0 : set = set_layers

var _portals: Array[Portal] = []

# Public

func get_normal() -> Vector3:
	return basis.z


func set_layers(value: int) -> void:
	if layers == value:
		return

	layers = value
	$MeshInstance.layers = value


func set_portal(portal: Portal) -> void:
	if _portals.has(portal):
		return

	_portals.push_back(portal)
	await _update_mesh()
	await _update_collision_shape()


func unset_portal(portal: Portal) -> void:
	if not _portals.has(portal):
		return

	_portals.erase(portal)
	await _update_mesh()
	await _update_collision_shape()


# Private

func _compute_collision_shape() -> Shape3D:
	if _portals.is_empty():
		var shape = BoxShape3D.new()
		shape.size = Vector3(2, 2, 0.2)
		return shape

	var base_mesh :=  BoxMesh.new()
	base_mesh.size = Vector3(2, 2, 0.2)
	var csg_root := CSGMesh3D.new()
	csg_root.mesh = 	base_mesh
	add_child(csg_root)

	# Use CSG tool to compute de the hole left by the opened portal in the mesh of the wall.
	# This mesh is used to build the collision sahpe of the wall.
	for portal in _portals:
		var csg_child := CSGBox3D.new()
		csg_root.add_child(csg_child)
		csg_child.operation = CSGShape3D.OPERATION_SUBTRACTION
		csg_child.quaternion = quaternion.inverse() * portal.quaternion
		csg_child.global_position = portal.global_position
		csg_child.size = Vector3(1, 2, 0.4)
	csg_root.position = Vector3(1000, 1000, 1000)

	# Wait for the CSG to compute the mesh
	await get_tree().process_frame
	await get_tree().process_frame

	var computed_mesh = csg_root.get_meshes()[1]
	remove_child(csg_root)
	return computed_mesh.create_trimesh_shape()


func _compute_meshes() -> Mesh:
	var base_mesh :=  QuadMesh.new()
	base_mesh.size = Vector2(2, 2)

	if _portals.is_empty():
		return base_mesh

	var csg_root := CSGMesh3D.new()
	csg_root.mesh = base_mesh
	add_child(csg_root)

	# Use CSG tool to compute de the hole left by the opened portal in the mesh of the wall
	for portal in _portals:
		var csg_child := CSGBox3D.new()
		csg_root.add_child(csg_child)
		csg_child.operation = CSGShape3D.OPERATION_SUBTRACTION
		csg_child.quaternion = quaternion.inverse() * portal.quaternion
		csg_child.global_position = portal.global_position
		csg_child.size = Vector3(1, 1.9, 0.2)
	csg_root.position = Vector3(1000, 1000, 1000)

	# Wait for the CSG to compute the mesh
	await get_tree().process_frame
	await get_tree().process_frame

	var meshes = csg_root.get_meshes()
	var computed_mesh = meshes[1]

	remove_child(csg_root)
	return computed_mesh


func _update_collision_shape() -> void:
	$CollisionShape.shape = await _compute_collision_shape()
	await get_tree().physics_frame
	await get_tree().physics_frame


func _update_mesh() -> void:
	$MeshInstance.mesh = await _compute_meshes()
