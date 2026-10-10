shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.07, 0.09, 0.13, 1.0);
uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.2;
uniform float softness_pixels : hint_range(0.0, 8.0) = 1.25;

void fragment() {
	vec2 radius = TEXTURE_PIXEL_SIZE * softness_pixels;
	float inherited_alpha = COLOR.a;
	float mask = texture(TEXTURE, UV).a * 0.4;
	mask += texture(TEXTURE, UV + vec2(radius.x, 0.0)).a * 0.1;
	mask += texture(TEXTURE, UV - vec2(radius.x, 0.0)).a * 0.1;
	mask += texture(TEXTURE, UV + vec2(0.0, radius.y)).a * 0.1;
	mask += texture(TEXTURE, UV - vec2(0.0, radius.y)).a * 0.1;
	mask += texture(TEXTURE, UV + radius).a * 0.05;
	mask += texture(TEXTURE, UV - radius).a * 0.05;
	mask += texture(TEXTURE, UV + vec2(radius.x, -radius.y)).a * 0.05;
	mask += texture(TEXTURE, UV + vec2(-radius.x, radius.y)).a * 0.05;
	COLOR = vec4(
		shadow_color.rgb,
		shadow_color.a * shadow_opacity * mask * inherited_alpha
	);
}
