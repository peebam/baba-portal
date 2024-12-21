class_name Player extends CharacterBody3D

signal moved(camera_transform: Transform3D)
signal target_set(target_position: Vector3, target_normal: Vector3, view_direction: Vector3)
signal target_unset()

const SPEED = 4
const BREAK = 1.0
const JUMP_VELOCITY = 4.5
const GRAVITY := 10.0

@export var active := false : set = set_active
@export var body_color := Color.CORNFLOWER_BLUE
@export_flags_3d_render var camera_cull_mask := 0
@export_flags_3d_render var display_instance_layers := 0

@onready var _gun_target: RayCast3D = $Head/RayCast

var _go_slow := false

func _ready() -> void:
	self.active = active
	$Body.layers = display_instance_layers
	$Head/Direction.layers = display_instance_layers
	$Head.current = active
	$Head.cull_mask = camera_cull_mask
	$CollisionShapeBody.disabled = not active

	var material := StandardMaterial3D. new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = body_color
	$Body.material_override = material
	$Head/Direction.material_override = material


func _input(event: InputEvent) -> void:
	if event.is_action("go_slow"):
		_go_slow = event.is_pressed()

	if event is InputEventMouseMotion:
		rotate(basis.y, -event.relative.x / 300.0)
		$Head.rotation.x = clamp(
			$Head.rotation.x - event.relative.y / 300.0,
			-PI/2,
			 PI/2
		)

		moved.emit($Head.global_transform)


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
		moved.emit($Head.global_transform)

	if _gun_target.is_colliding():
		var target_position := _gun_target.get_collision_point()
		var target_normal := _gun_target.get_collision_normal()
		var view_direction := (target_position - _gun_target.global_position).normalized()
		target_set.emit(target_position, target_normal, view_direction)
	else:
		target_unset.emit()

# Public

func set_active(value: bool) -> void:
	active = value
	$Head.current = value


func set_gravity_direction(value: Vector3) -> void:
	if up_direction == -value:
		return

	velocity = Quaternion(up_direction, -value) * velocity
	up_direction = -value
