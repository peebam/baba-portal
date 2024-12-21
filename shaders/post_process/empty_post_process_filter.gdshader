shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform vec4[2] transparent_colors : source_color;
uniform vec4 filter_color : source_color;

bool isAlmostSameVec4(vec4 a, vec4 b, float epsilon) {
	return all(lessThanEqual(abs(a - b), vec4(epsilon)));
}

bool isTransparent(vec4 color) {
	return
	(
		transparent_colors[0].a != 0.0 &&
		isAlmostSameVec4(color, transparent_colors[0], 0.005)) ||
	(
		transparent_colors[0].a != 0.0 &&
		isAlmostSameVec4(color, transparent_colors[1], 0.005));
}

void fragment() {
	vec4 color = texture(screen_texture, UV);
	if (isTransparent(color)) {
		COLOR = vec4(0);
	}
	else {
		COLOR = color;
	}
}
