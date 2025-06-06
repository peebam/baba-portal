extends Node

class Resources:

	static var color_filter_shader :Shader =  preload("res://shaders/post_process/color_post_process_filter.gdshader")
	static var empty_filter_shader :Shader =  preload("res://shaders/post_process/square_post_process_filter.gdshader")
	static var square_filter_shader :Shader =  preload("res://shaders/post_process/empty_post_process_filter.gdshader")


class Parameters:
	var filter: Filter
	var cull_mask: int

	func _init(filter_: Filter, cull_mask_: int) -> void:
		filter = filter_
		cull_mask = cull_mask_


class Filter:

	var shader : Shader
	func apply(_material: ShaderMaterial) -> void:
		pass


class ColorFilter extends Filter:

	var color := Color.TRANSPARENT

	func _init(color_: Color) -> void:
		color = color_
		shader = Resources.color_filter_shader


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader
		material.set_shader_parameter("filter_color", color)


class NoFilter extends Filter:
	func _init() -> void:
		shader = Resources.empty_filter_shader


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader


class SquareFilter extends Filter:
	var square_size := 5

	func _init(square_size_: int) -> void:
		square_size = square_size_
		shader = Resources.square_filter_shader


	func apply(material: ShaderMaterial) -> void:
		material.shader = shader
		material.set_shader_parameter("square_size", square_size)
