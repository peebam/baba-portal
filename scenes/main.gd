extends Node3D

var level_scene_names: Array[String]= [
	"res://scenes/levels/levels_test_1.tscn"
]

func _ready() -> void:
	load_level(0)

# Public

func load_level(number: int) -> void:
	var scene_name := level_scene_names[number]
	var scene: PackedScene = load(scene_name)
	var level: Level = scene.instantiate()
	level.goal_activated.connect(func ():
		print("Goal Activated")
	)
	$Game.level = level
