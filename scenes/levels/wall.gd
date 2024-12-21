class_name Wall extends StaticBody3D

@export_flags_3d_render var default_layers = 0

var layers: int : set = set_layers

var _csg_root: CSGMesh3D = null
var _portals: Array[Portal] = []

func _ready() -> void:
	self.layers = default_layers

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
	await _compute()


func unset_portal(portal: Portal) -> void:
	if not _portals.has(portal):
		return

	_portals.erase(portal)
	await _compute()


func update() -> void:
	if _csg_root == null:
		return

	var mesh = _csg_root.get_meshes()[1]
	var shape = mesh.create_trimesh_shape()

	$CollisionShape.shape = shape
	$MeshInstance.mesh = mesh

	remove_child(_csg_root)
	_csg_root = null

# Private

func _compute() -> void:
	if _portals.is_empty():
		var shape = BoxShape3D.new()
		shape.size = Vector3(2, 2, 0.05)
		$CollisionShape.shape = shape

		var mesh :=  BoxMesh.new()
		mesh.size = Vector3(2, 2, 0.05)
		$MeshInstance.mesh = mesh
		return

	_csg_root = CSGMesh3D.new()
	_csg_root.mesh = BoxMesh.new()
	_csg_root.mesh.size = Vector3(2, 2, 0.05)
	add_child(_csg_root)

	# Use CSG tool to compute de the hole left by the opened portal in the mesh of the wall.
	# This mesh is used to build the collision sahpe of the wall.
	for portal in _portals:
		var csg_child := CSGBox3D.new()
		_csg_root.add_child(csg_child)
		csg_child.operation = CSGShape3D.OPERATION_SUBTRACTION
		csg_child.quaternion = quaternion.inverse() * portal.quaternion
		csg_child.global_position = portal.global_position
		csg_child.size = Vector3(1, 2, 0.4)
	_csg_root.position = Vector3(1000, 1000, 1000)
