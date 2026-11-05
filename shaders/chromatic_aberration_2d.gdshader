shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 0.1) = 0.05;

void fragment() {
	vec2 center = vec2(0.5);
	float dist = distance(SCREEN_UV, center);
	float t = 1.0 - dist;
	float aberration = intensity * t * 0.05;

	// Red channel shifted left (negative UV offset)
	float r = textureLod(screen_texture, SCREEN_UV - vec2(aberration, 0.0), 0.0).r;
	// Green channel stays center
	float g = textureLod(screen_texture, SCREEN_UV, 0.0).g;
	// Blue channel shifted right (positive UV offset)
	float b = textureLod(screen_texture, SCREEN_UV + vec2(aberration, 0.0), 0.0).b;

	COLOR = vec4(r, g, b, 1.0);
}
