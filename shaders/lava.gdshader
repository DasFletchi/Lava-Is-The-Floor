shader_type spatial;
render_mode unshaded;

uniform vec4 deep_lava : source_color = vec4(0.35, 0.005, 0.0, 1.0);
uniform vec4 hot_lava : source_color = vec4(1.0, 0.11, 0.0, 1.0);
uniform vec4 glow_lava : source_color = vec4(1.0, 0.72, 0.05, 1.0);
uniform float speed = 0.55;

void fragment() {
	vec2 uv = UV * 7.0;
	float waves = sin((uv.x + TIME * speed) * 2.4) + sin((uv.y - TIME * speed * 0.7) * 3.1);
	float veins = smoothstep(0.35, 1.25, waves);
	ALBEDO = mix(deep_lava.rgb, hot_lava.rgb, veins);
	EMISSION = mix(hot_lava.rgb * 0.8, glow_lava.rgb * 2.3, veins);
	ROUGHNESS = 0.28;
}
