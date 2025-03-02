class_name Player extends CharacterBody3D

signal moved(camera_transform: Transform3D)
signal target_set(target_position: Vector3, target_normal: Vector3, view_direction: Vector3)
signal target_unset()

const SPEED = 4
const BREAK = 1.0
const JUMP_VELOCITY = 4.5
const GRAVITY := 10.0

@export var active := false
@export var body_color := Color.CORNFLOWER_BLUE
@export_flags_3d_render var camera_cull_mask := 0
@export_flags_3d_render var display_instance_layers := 0

var cross_position: Vector3 : get = get_cross_position

var _go_slow := false

@onready var _body: MeshInstance3D = $Body
@onready var _collision_shape: CollisionShape3D = $CollisionShape
@onready var _gun_target: RayCast3D = $Head/RayCast
@onready var _head: Camera3D = $Head
@onready var _head_direction: MeshInstance3D = $Head/Direction

func _ready() -> void:
	var material := StandardMaterial3D. new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = body_color

	_body.layers = display_instance_layers
	_body.material_override = material
	_collision_shape.set_deferred("disabled", not active)
	_head.cull_mask = camera_cull_mask
	_head.current = active
	_head_direction.layers = display_instance_layers
	_head_direction.material_override = material


func _input(event: InputEvent) -> void:
	if event.is_action("go_slow"):
		_go_slow = event.is_pressed()

	if event is InputEventMouseMotion:
		rotate(basis.y, -event.relative.x / 300.0)
		_head.rotation.x = clamp(
			_head.rotation.x - event.relative.y / 300.0,
			-PI/2,
			 PI/2
		)

		moved.emit(_head.global_transform)


func _physics_process(delta: float) -> void:
	if not active:
		return

	var vertical_velocity := velocity.dot(up_direction) * up_direction
	if not is_on_floor():
		vertical_velocity  += -up_direction * GRAVITY * delta
	elif Input.is_action_just_pressed("ui_accept"):
		vertical_velocity += up_direction * JUMP_VELOCITY

	var input_direction := Input.get_vector("straf_left", "straf_right", "go_forward", "go_backward")
	if input_direction:
		var speed := SPEED * (0.05 if _go_slow else 1.0)
		velocity = (
			vertical_velocity +
			input_direction.x * basis.x * speed +
			input_direction.y * basis.z * speed)
	else:
		velocity = (
			vertical_velocity +
			move_toward(velocity.dot(basis.x), 0, BREAK) * basis.x +
			move_toward(velocity.dot(basis.z), 0, BREAK) * basis.z)

	if velocity != Vector3.ZERO:
		move_and_slide()
		moved.emit(_head.global_transform)

	if _gun_target.is_colliding():
		var target_position := _gun_target.get_collision_point()
		var target_normal := _gun_target.get_collision_normal()
		var view_direction := (target_position - _gun_target.global_position).normalized()
		target_set.emit(target_position, target_normal, view_direction)
	else:
		target_unset.emit()

# Public

func get_cross_position() -> Vector3:
	return _head.global_position


func set_active(value: bool) -> void:
	if active == value:
		return

	active = value
	_head.current = active
	_collision_shape.set_deferred("disabled", not active)


func set_gravity_direction(value: Vector3) -> void:
	if up_direction == -value:
		return

	velocity = Quaternion(up_direction, -value) * velocity
	up_direction = -value
