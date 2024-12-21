shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform vec4[2] transparent_colors : source_color;
uniform vec4 filter_color : source_color;
uniform int square_size;

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
		if (square_size == 0) {
			COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		}
		else {
			ivec2 position = ivec2(
				int((UV.x / SCREEN_PIXEL_SIZE.x)),
				int((UV.y / SCREEN_PIXEL_SIZE.y))
			);

			bool x_display = int(floor(float(position.x) / float(square_size))) % 2 == 0;
			bool y_display = int(floor(float(position.y) / float(square_size))) % 2 == 0;

			if ((x_display || y_display) && x_display != y_display)
				COLOR = mix(COLOR, vec4(0.0, 0.0, 0.0, 1.0), .9);
			else
				COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		}
	}
}
