shader_type canvas_item;

uniform vec4 rock_color : source_color = vec4(0.04, 0.035, 0.04, 1.0);
uniform vec4 lava_hot : source_color = vec4(1.0, 0.72, 0.15, 1.0);
uniform vec4 lava_deep : source_color = vec4(0.85, 0.16, 0.02, 1.0);
uniform float speed : hint_range(0.01, 1.0) = 0.18;
uniform float scale : hint_range(1.0, 20.0) = 4.0;

vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
		    dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
		    dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.0 + vec2(100.0);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * scale;
	float t = TIME * speed;

	// Slow organic swirling lava currents
	vec2 flow1 = vec2(fbm(uv + vec2(t * 0.2, t * 0.15)), fbm(uv + vec2(-t * 0.15, t * 0.25)));
	vec2 flow2 = vec2(fbm(uv + 3.0 * flow1 + vec2(1.7, 4.2)), fbm(uv + 3.0 * flow1 + vec2(8.3, 1.8)));
	float pattern = fbm(uv + 2.5 * flow2);

	// Crack threshold
	float crack = smoothstep(0.02, 0.38, pattern);
	float hot_core = smoothstep(0.22, 0.45, pattern);

	vec3 lava_col = mix(lava_deep.rgb, lava_hot.rgb, hot_core);
	vec3 final_col = mix(rock_color.rgb, lava_col, crack);

	// Subtle pulsing hot glow
	float pulse = 0.5 + 0.5 * sin(TIME * 1.5 + pattern * 6.28);
	final_col += lava_hot.rgb * hot_core * pulse * 0.25;

	COLOR = vec4(final_col, 1.0);
}
