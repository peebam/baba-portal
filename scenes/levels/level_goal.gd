extends StaticBody3D

signal activated
signal left
signal reached

@export var enabled := false : set = set_enabled
@export_range(0, 20, 1) var layer: int = 0 : set = set_layer

# Public

func set_enabled(value: bool) -> void:
	if enabled == value:
		return

	enabled = value
	$CollisionShape.set_deferred("disabled", not enabled)
	$Area/CollisionShape.set_deferred("disabled", not enabled)


func set_layer(value: int) -> void:
	if layer == value:
		return

	layer = value
	$MeshInstance.layers = Math.value_to_bit_flags(value)

# Signals

func _on_activation_timer_timeout() -> void:
	activated.emit()


func _on_area_body_entered(body: Node3D) -> void:
	if body is Player:
		reached.emit()


func _on_area_body_exited(body: Node3D) -> void:
	if body is Player:
		left.emit()


func _on_left() -> void:
	%ActivationTimer.stop()


func _on_reached() -> void:
	%ActivationTimer.start()
