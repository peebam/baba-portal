shader_type canvas_item;

const int NB_TEXTURES_MAX = 10;

uniform sampler2D[NB_TEXTURES_MAX] portal_a_textures;
uniform int portal_a_nb_textures = 4;
uniform vec4 portal_a_transparent_color : source_color;

uniform sampler2D[NB_TEXTURES_MAX] portal_b_textures;
uniform int portal_b_nb_textures = 4;
uniform vec4 portal_b_transparent_color : source_color;

uniform sampler2D player_view_texture : hint_default_black;

bool isAlmostSameVec4(vec4 a, vec4 b, float epsilon) {
	return all(lessThanEqual(abs(a - b), vec4(epsilon)));
}

bool isTransparent(vec4 color, vec4 transparent) {
	return isAlmostSameVec4(color, transparent, 0.005);
}

vec4 get_texture_color(sampler2D[NB_TEXTURES_MAX] textures, int nb_textures, vec4 transparent, vec2 uv) {
	for(int i = 0; i < nb_textures; i++) {
		vec4 color = texture(textures[i], uv);
		if (!isTransparent(color, transparent)) {
			return color;
		}
	}

	return vec4(0, 0, 0, 1);
}

void fragment() {

	vec4 player_view_texture_color = texture(player_view_texture, UV);
	if (isTransparent(player_view_texture_color, portal_a_transparent_color))
	{
		COLOR = get_texture_color(
			portal_a_textures,
			portal_a_nb_textures,
			portal_a_transparent_color,
			SCREEN_UV
		);
	}
	else if (isTransparent(player_view_texture_color, portal_b_transparent_color)) {
		COLOR = get_texture_color(
			portal_b_textures,
			portal_b_nb_textures,
			portal_b_transparent_color,
			SCREEN_UV
		);
	}
	else {
		COLOR = player_view_texture_color;
	}
}
