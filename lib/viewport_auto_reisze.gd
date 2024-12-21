class_name ViewportAutoReisze extends Node

@export var source_viewport: Viewport
@export var target_viewport: Viewport

func _ready() -> void:
	if not source_viewport:
		_auto_set_source_viewport()

	if not target_viewport:
		_auto_set_target_viewport()

	if source_viewport and target_viewport:
		_update_target_viewport_size()
		source_viewport.size_changed.connect(_update_target_viewport_size)

# Private

func _auto_set_source_viewport():
	source_viewport = get_tree().get_root().get_viewport()


func _auto_set_target_viewport():
	target_viewport = get_viewport()


func _update_target_viewport_size() -> void:
	var size := source_viewport.get_visible_rect().size
	target_viewport.size = size

# Signals

func _on_target_viewport_size_change() -> void:
	_update_target_viewport_size()
