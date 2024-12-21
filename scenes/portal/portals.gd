class_name Portals extends Node3D

signal object_crossed(from: Portal, to: Portal, object: Node3D, new_position: Vector3, new_rotation: Quaternion)
signal object_entered(to: Portal, object: Node3D)
signal object_exited(from: Portal, object: Node3D)

const EXTRA_CULL_MARGIN_MAX := 16384.0
const EXTRA_CULL_MARGIN_MIN := 0.0
const PORTAL_CROSSING_DETECTION_MARGIN := 0.009

@onready var portal_a: Portal = %PortalA
@onready var portal_b: Portal = %PortalB

var _objects: Array[Node3D] = []
var _objects_pivot_previous: Dictionary = {}
var _objects_portal: Dictionary = {}

func _physics_process(_delta: float) -> void:
	if not visible:
		return

	if portal_a.open and portal_b.open:
		_check_crossers()

# Private

func _check_crossers() -> void:
	var objects: Array[Node3D] = []

	var detections := _detect_near_objects()
	# Check the node that just entered
	for detection in detections:
		objects.append(detection.object)
		if not self._objects.has(detection.object):
			object_entered.emit(detection.portal, detection.object)
			_objects_pivot_previous[detection.object] = detection.object.pivot
			_objects_portal[detection.object] = detection.portal

	# Check if detected object are crossing
	for detection in detections:
		if _check_crosser(detection.portal, detection.object):
			_objects_pivot_previous[detection.object] = detection.object.pivot
			_objects_portal[detection.object] = detection.portal.linked_portal

	# Check the node that just exited
	for object in self._objects:
		if not objects.has(object):
			object_exited.emit(_objects_portal[object], object)
			_objects_pivot_previous.erase(object)
			_objects_portal.erase(object)

	self._objects = objects


func _check_crosser(portal: Portal, object: Node3D) -> bool:
	var object_pivot_previous: Vector3 = _objects_pivot_previous[object]
	var object_pivot_current: Vector3 = object.pivot

	# Distance position portal where a crossing can be triggered.
	if not portal.is_crossed(object_pivot_current, object_pivot_previous, PORTAL_CROSSING_DETECTION_MARGIN):
		_objects_pivot_previous[object] = object.pivot
		return false

	var object_direction := (object_pivot_current - object_pivot_previous).normalized()
	var distance_to_portal := portal.distance_to(object_pivot_current)
	# If the margin is greater than 0, the crossing can be triggered whereas the object is not really behind the portal.
	# The project_position is computed to predict the position of the object as it should be behind the portal.
	var projected_position := object.position + object_direction * (PORTAL_CROSSING_DETECTION_MARGIN + distance_to_portal)

	var new_position := portal.get_linked_position(projected_position)
	var new_rotation := portal.get_linked_rotation(object.quaternion)

	object_crossed.emit(portal, portal.linked_portal, object, new_position, new_rotation)
	return true

# Return the objects near the portals
# Array[Array[portal_a, Array[Node3D]], Array[portal_b, Array[Node3D]]]
func _detect_near_objects() -> Array[Dictionary]:
	var objects: Array[Dictionary] = []

	for object in portal_a.detect_near_objects():
		objects.append({
			"portal": portal_a,
			"object": object
		})

	for object in portal_b.detect_near_objects():
		objects.append({
			"portal": portal_b,
			"object": object
		})

	return objects

# Signals

func _on_object_crossed(from: Portal, to: Portal, object: Node3D, _new_position: Vector3, _new_rotation: Quaternion) -> void:
	prints("crossed", self.name, object.name)


func _on_object_entered(to: Portal, object: Node3D) -> void:
	prints("enter", self.name, object.name)
	to.linked_portal.extra_cull_mask = EXTRA_CULL_MARGIN_MAX
	to.extra_cull_mask = EXTRA_CULL_MARGIN_MAX


func _on_object_exited(from: Portal, object: Node3D) -> void:
	prints("exit", self.name, object.name)
	from.linked_portal.extra_cull_mask = EXTRA_CULL_MARGIN_MIN
	from.extra_cull_mask = EXTRA_CULL_MARGIN_MIN
