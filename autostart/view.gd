extends Node


class Parameters:
	var filter: Filter
	
	func _init(filter_: Filter) -> void:
		filter = filter_
	

class Filter:
	var shader : Shader
	func apply(_material: ShaderMaterial) -> void:
		pass


class ColorFilter extends Filter:
	var color := Color.TRANSPARENT

	func _init(color_: Color) -> void:
		color = color_
		shader = preload("res://shaders/post_process/color_post_process_filter.gdshader")


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader
		material.set_shader_parameter("filter_color", color)


class NoFilter extends Filter:
	func _init() -> void:
		shader = preload("res://shaders/post_process/empty_post_process_filter.gdshader")


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader


class SquareFilter extends Filter:
	var square_size := 5

	func _init(square_size_: int) -> void:
		square_size = square_size_
		shader = preload("res://shaders/post_process/square_post_process_filter.gdshader")


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader
		material.set_shader_parameter("square_size", square_size)
