shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// --- Colors ---
group_uniforms LavaColors;
uniform vec4 color_crust_dark : source_color = vec4(0.05, 0.03, 0.03, 1.0);  // Dark basalt rock
uniform vec4 color_crust_warm : source_color = vec4(0.18, 0.06, 0.03, 1.0);  // Heated charred crust
uniform vec4 color_lava_deep : source_color = vec4(0.92, 0.18, 0.02, 1.0);   // Fiery crimson magma
uniform vec4 color_lava_bright : source_color = vec4(1.0, 0.55, 0.04, 1.0);  // Intense glowing orange
uniform vec4 color_lava_core : source_color = vec4(1.0, 0.95, 0.65, 1.0);    // White-hot core heat

group_uniforms LavaTuning;
uniform float uv_scale : hint_range(0.01, 1.0) = 0.25;
uniform vec2 flow_speed_1 = vec2(0.010, 0.015);
uniform vec2 flow_speed_2 = vec2(-0.012, 0.011);
uniform float crack_spread : hint_range(0.05, 0.8) = 0.22;
uniform float emission_boost : hint_range(0.5, 8.0) = 1.8;
uniform float wave_height : hint_range(0.0, 1.0) = 0.12;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;

// Hash function
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

// 2D Noise
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = dot(hash2(i + vec2(0.0, 0.0)) - 0.5, f - vec2(0.0, 0.0));
	float b = dot(hash2(i + vec2(1.0, 0.0)) - 0.5, f - vec2(1.0, 0.0));
	float c = dot(hash2(i + vec2(0.0, 1.0)) - 0.5, f - vec2(0.0, 1.0));
	float d = dot(hash2(i + vec2(1.0, 1.0)) - 0.5, f - vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) + 0.5;
}

// Voronoi cell border distance
float voronoi_edge(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	vec2 mg, mr;
	float md = 8.0;

	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			o = 0.5 + 0.35 * sin(TIME * 0.3 + 6.2831 * o);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < md) {
				md = d;
				mr = r;
				mg = g;
			}
		}
	}

	md = 8.0;
	for (int j = -2; j <= 2; j++) {
		for (int i = -2; i <= 2; i++) {
			vec2 g = mg + vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			o = 0.5 + 0.35 * sin(TIME * 0.3 + 6.2831 * o);
			vec2 r = g + o - f;
			if (dot(mr - r, mr - r) > 0.00001) {
				md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
			}
		}
	}
	return md;
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Organic rolling waves
	float w1 = sin(world_pos.x * 0.18 + TIME * wave_speed) * cos(world_pos.z * 0.18 + TIME * wave_speed * 0.8);
	float w2 = sin(world_pos.z * 0.25 - TIME * wave_speed * 0.7 + world_pos.x * 0.12) * 0.45;
	VERTEX.y += (w1 + w2) * wave_height;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 base_uv = world_pos.xz * uv_scale;

	// Dual flow directions
	vec2 flow1 = base_uv + flow_speed_1 * TIME;
	vec2 flow2 = base_uv + flow_speed_2 * TIME;

	// Organic turbulent domain warping
	float warp_x = noise(flow1 * 2.5) - 0.5;
	float warp_z = noise(flow2 * 2.5) - 0.5;
	vec2 warped_uv = base_uv + vec2(warp_x, warp_z) * 0.4;

	// Voronoi edge detection
	float edge_dist = voronoi_edge(warped_uv * 2.5);

	// Crack intensity curve
	float crack = 1.0 - smoothstep(0.0, crack_spread, edge_dist);

	// Boiling bubbling micro-noise within molten streams
	float boil = noise(warped_uv * 8.0 + TIME * 0.6);
	crack = clamp(crack + (boil - 0.5) * 0.15 * crack, 0.0, 1.0);

	// Crust shading
	float crust_noise = noise(base_uv * 5.0);
	vec3 crust_col = mix(color_crust_dark.rgb, color_crust_warm.rgb, crust_noise * 0.7);

	// Magma colors: fiery red -> incandescent orange -> bright yellow core
	vec3 magma_col = mix(color_lava_deep.rgb, color_lava_bright.rgb, smoothstep(0.2, 0.65, crack));
	magma_col = mix(magma_col, color_lava_core.rgb, smoothstep(0.65, 0.95, crack));

	// Blend crust and magma
	vec3 final_albedo = mix(crust_col, magma_col, smoothstep(0.06, 0.35, crack));

	// Emission mask focused on cracks with incandescent glow
	float emission_mask = smoothstep(0.12, 0.8, crack);
	vec3 emission = magma_col * (emission_mask * emission_boost);

	ALBEDO = final_albedo;
	EMISSION = emission;
	ROUGHNESS = mix(0.92, 0.2, emission_mask);
	METALLIC = 0.05;
}
