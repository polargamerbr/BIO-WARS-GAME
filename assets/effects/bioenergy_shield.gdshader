// Escudo de bioenergia do MACROPHAGE: painel oval translúcido com padrão de colmeia
// (referência: docs/art/concept/macrophage_bioenergy_shield.jpeg).
// strength: carga do escudo (0 a 1). flash: clarão ao absorver dano (0 a 1).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 shield_color : source_color = vec4(0.35, 0.85, 1.0, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float hex_scale = 7.0;

// Distância até a borda de um hexágono centrado na origem.
float hex_dist(vec2 p) {
	p = abs(p);
	return max(dot(p, normalize(vec2(1.0, 1.732))), p.x);
}

// xy: posição dentro da célula hexagonal; zw: identificador da célula.
vec4 hex_coords(vec2 uv) {
	vec2 r = vec2(1.0, 1.732);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return vec4(gv, uv - gv);
}

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float radius = length(c);
	float oval = 1.0 - smoothstep(0.88, 1.0, radius);
	vec4 h = hex_coords(UV * hex_scale);
	float edge = smoothstep(0.40, 0.50, hex_dist(h.xy));
	float pulse = 0.5 + 0.5 * sin(TIME * 3.0 + h.z * 1.7 + h.w * 1.3);
	float rim = smoothstep(0.65, 0.98, radius);
	float glow = (0.08 + edge * 0.5 * (0.6 + 0.4 * pulse) + rim * 0.45) * oval * strength;
	glow += flash * oval * 0.7;
	ALBEDO = shield_color.rgb * glow + vec3(flash * glow * 0.6);
	ALPHA = clamp(glow, 0.0, 1.0);
}
