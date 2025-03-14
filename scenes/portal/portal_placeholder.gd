class_name PortalPlaceholder extends Node3D

signal status_changed()

var active := false : set = set_active

var _target_normal := Vector3.ZERO
var _target_position := Vector3.ZERO
var _up_direction := Vector3.ZERO
var _view_direction := Vector3.ZERO

# Public

func move(target_position: Vector3, target_normal: Vector3, view_direction: Vector3, up_direction: Vector3) -> void:
	_target_normal = target_normal
	_target_position = target_position
	_up_direction = up_direction
	_view_direction = view_direction
	_orient()


func set_active(value: bool) -> void:
	var is_activable = _is_covering() and not _is_colliding()
	value = value && is_activable

	if (active == value):
		return

	active = value
	status_changed.emit()

# Private

func _is_colliding() -> bool:
	$ShapeCast.force_shapecast_update()
	return $ShapeCast.is_colliding()


func _is_covering() -> bool:
	$RayCastTopLeft.force_raycast_update()
	$RayCastBottomRight.force_raycast_update()
	return $RayCastTopLeft.is_colliding() and $RayCastBottomRight.is_colliding()


func _orient() -> void:
	position = _target_position.round()
	quaternion = Quaternion(Vector3.FORWARD, _target_normal)
	# If up_direction and target_normal are parallel, the placeholder must be
	# oriented in the view direction
	var dot:= roundi(_up_direction.dot(_target_normal))
	if dot == 0:
		var angle_to_view_direction := basis.y.signed_angle_to(_up_direction, basis.z)
		quaternion = Quaternion(basis.z, angle_to_view_direction) * quaternion
		return

	var angle := -(Plane(_target_normal)
		.project(_view_direction)
		.signed_angle_to(basis.y, basis.z))
#
	var rounded_angle := roundi(angle / (PI/2)) * (PI/2)
	quaternion = Quaternion(basis.z, rounded_angle) * quaternion


func _on_status_changed() -> void:
	if active:
		$Frame.main_color = Color(0, 0, 1, .5)
		$Frame.visible = true
	else:
		$Frame.main_color = Color(1, 0, 0, .5)
		$Frame.visible = false
