shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear;

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 pixel = SCREEN_PIXEL_SIZE;
	vec3 center = texture(scene_color, SCREEN_UV).rgb;
	float northwest = luminance(texture(scene_color, SCREEN_UV + pixel * vec2(-1.0, -1.0)).rgb);
	float northeast = luminance(texture(scene_color, SCREEN_UV + pixel * vec2(1.0, -1.0)).rgb);
	float southwest = luminance(texture(scene_color, SCREEN_UV + pixel * vec2(-1.0, 1.0)).rgb);
	float southeast = luminance(texture(scene_color, SCREEN_UV + pixel * vec2(1.0, 1.0)).rgb);
	float middle = luminance(center);
	float minimum = min(middle, min(min(northwest, northeast), min(southwest, southeast)));
	float maximum = max(middle, max(max(northwest, northeast), max(southwest, southeast)));
	vec2 direction = vec2(southwest + southeast - northwest - northeast, northwest + southwest - northeast - southeast);
	float damping = max((northwest + northeast + southwest + southeast) / 32.0, 1.0 / 128.0);
	direction = clamp(direction / (min(abs(direction.x), abs(direction.y)) + damping), vec2(-8.0), vec2(8.0)) * pixel;
	vec3 narrow = 0.5 * (texture(scene_color, SCREEN_UV - direction / 6.0).rgb + texture(scene_color, SCREEN_UV + direction / 6.0).rgb);
	vec3 broad = narrow * 0.5 + 0.25 * (texture(scene_color, SCREEN_UV - direction * 0.5).rgb + texture(scene_color, SCREEN_UV + direction * 0.5).rgb);
	float broad_luma = luminance(broad);
	vec3 filtered = broad_luma < minimum || broad_luma > maximum ? narrow : broad;
	COLOR = vec4(maximum - minimum < max(0.04, maximum * 0.1) ? center : filtered, 1.0);
}
