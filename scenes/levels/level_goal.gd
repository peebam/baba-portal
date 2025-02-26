extends StaticBody3D

signal activated
signal left
signal reached

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
