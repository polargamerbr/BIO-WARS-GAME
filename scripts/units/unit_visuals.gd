extends Node
## Animações procedurais do corpo provisório de uma unidade. Só lê o estado da unidade e
## reage aos sinais dela; não interfere em movimento nem combate. Quando existirem os modelos
## 3D com rig, isto é substituído pelas animações deles.
##   Soldado em pé: balança ao andar, inclina para a frente, respira parado.
##   Bastonete (bactéria): ondula ao andar e pulsa parado.
##   Criatura (invasor humanoide): curvada, passo rápido e balanço inquieto parada.
##   Escudo de bioenergia: painel translúcido à frente; some quando zera, pisca ao absorver.
##   Ataque: avanço rápido para a frente (contato) ou recuo do disparo (fuzil). Dano recebido: clarão branco.

const WALK_BOB := 0.08  ## Metros de balanço vertical ao andar.
const WALK_STEP_RATE := 2.2  ## Passos por segundo a cada m/s de velocidade (com limite).
const LEAN_DEGREES := 7.0  ## Inclinação para a frente na velocidade máxima.
const LUNGE_DISTANCE := 0.35
const RECOIL_DISTANCE := 0.12
const FLASH_ENERGY := 2.5
const FLASH_TIME := 0.15
const SHIELD_COLOR := Color(0.35, 0.85, 1.0)
const SHIELD_ALPHA := 0.35
const SHIELD_SHADER := preload("res://assets/effects/bioenergy_shield.gdshader")

var _unit: Unit
var _pivot: Node3D
var _material: StandardMaterial3D
var _time := 0.0
var _lunge := 0.0
var _shield_panel: MeshInstance3D
var _shield_mat: ShaderMaterial
var _shield_flash := 0.0
var _shield_strength := 1.0
var _overlay: StandardMaterial3D  ## Clarão de dano sobre o modelo 3D.
var _phase := 0.0  ## Defasagem aleatória para as unidades não se moverem em sincronia.


## pivot: nó que contém as malhas do corpo. material: material do corpo (para o clarão).
## Com modelo 3D, material é null: o modelo tem animações próprias (UnitModelAnimator) e o
## clarão de dano usa um material sobreposto em todas as malhas.
func setup(unit: Unit, pivot: Node3D, material: StandardMaterial3D) -> void:
	_unit = unit
	_pivot = pivot
	_material = material
	if _material != null:
		_material.emission_enabled = true
		_material.emission = Color.BLACK
	else:
		_overlay = StandardMaterial3D.new()
		_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_overlay.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
		for mi in pivot.find_children("*", "MeshInstance3D", true, false):
			mi.material_overlay = _overlay
	_phase = randf() * TAU
	unit.attack_performed.connect(_on_attack_performed)
	unit.damaged.connect(_on_damaged)
	if unit.data.has_shield():
		_build_shield_panel()
		unit.shield_hit.connect(_on_shield_hit)


func _process(delta: float) -> void:
	if _unit == null or not _unit.is_alive():
		return
	_time += delta
	var speed := Vector2(_unit.velocity.x, _unit.velocity.z).length()
	var moving := speed > 0.3
	var speed_ratio := clampf(speed / maxf(_unit.data.move_speed, 0.1), 0.0, 1.5)
	var t := _time + _phase

	if _unit.data.has_model():
		_pivot.position = Vector3(0.0, 0.0, -_lunge)
		if _shield_panel != null:
			_update_shield_panel(t)
		return

	match _unit.data.body_shape:
		UnitData.BodyShape.ROD:
			_animate_rod(t, moving, speed)
		UnitData.BodyShape.CREATURE:
			_animate_creature(t, moving, speed, speed_ratio)
		_:
			_animate_upright(t, moving, speed, speed_ratio)
	if _shield_panel != null:
		_update_shield_panel(t)


func _animate_upright(t: float, moving: bool, speed: float, speed_ratio: float) -> void:
	var bob := 0.0
	var lean := 0.0
	var breathe := 1.0
	if moving:
		var rate := minf(speed * WALK_STEP_RATE, 12.0)
		bob = absf(sin(t * rate)) * WALK_BOB
		lean = -deg_to_rad(LEAN_DEGREES) * speed_ratio
	else:
		breathe = 1.0 + sin(t * 2.0) * 0.015
	_pivot.position = Vector3(0.0, bob, -_lunge)
	_pivot.rotation.x = lerp_angle(_pivot.rotation.x, lean, 0.2)
	_pivot.scale = Vector3(1.0, breathe, 1.0)


func _animate_creature(t: float, moving: bool, speed: float, speed_ratio: float) -> void:
	var bob := 0.0
	var lean := 0.0
	var sway := 0.0
	if moving:
		var rate := minf(speed * 3.2, 16.0)  # Passo mais rápido e nervoso que o do soldado.
		bob = absf(sin(t * rate)) * WALK_BOB * 1.4
		lean = -deg_to_rad(14.0) * speed_ratio
		sway = sin(t * rate * 0.5) * deg_to_rad(6.0)
	else:
		sway = sin(t * 1.7) * deg_to_rad(4.0)  # Balanço inquieto, de predador parado.
		bob = sin(t * 2.6) * 0.03
	_pivot.position = Vector3(0.0, bob, -_lunge)
	_pivot.rotation.x = lerp_angle(_pivot.rotation.x, lean, 0.2)
	_pivot.rotation.z = sway


## Painel oval de bioenergia com padrão de colmeia, à frente do corpo (shader próprio).
func _build_shield_panel() -> void:
	var r := _unit.data.body_radius
	var h := _unit.data.body_height
	_shield_mat = ShaderMaterial.new()
	_shield_mat.shader = SHIELD_SHADER
	_shield_mat.set_shader_parameter("shield_color", SHIELD_COLOR)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(r * 2.6, h * 0.95)
	mesh.material = _shield_mat
	_shield_panel = MeshInstance3D.new()
	_shield_panel.name = "ShieldPanel"
	_shield_panel.mesh = mesh
	_shield_panel.position = Vector3(0.0, h * 0.5, -r - 0.45)
	_shield_panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivot.add_child(_shield_panel)


func _update_shield_panel(_t: float) -> void:
	var ratio := _unit.shield / _unit.data.shield_max
	_shield_panel.visible = ratio > 0.0 or _shield_flash > 0.01
	# Mais forte com o escudo cheio; nunca some de todo enquanto há carga.
	_shield_strength = lerpf(_shield_strength, 0.35 + 0.65 * ratio, 0.2)
	_shield_mat.set_shader_parameter("strength", _shield_strength if ratio > 0.0 else 0.0)
	_shield_mat.set_shader_parameter("flash", _shield_flash)


func _on_shield_hit(_unit_hit: Unit, _absorbed: float, broken: bool) -> void:
	_shield_flash = 1.0
	var tween := create_tween()
	tween.tween_property(self, "_shield_flash", 0.0, 0.25)
	if broken:
		# Estoura: cresce e volta ao tamanho normal (fica invisível até recarregar).
		_shield_panel.scale = Vector3.ONE * 1.3
		var pop := create_tween()
		pop.tween_property(_shield_panel, "scale", Vector3.ONE, 0.25)


func _animate_rod(t: float, moving: bool, speed: float) -> void:
	if moving:
		# Ondulação: gira de um lado para o outro e estica no sentido do movimento.
		var rate := minf(speed * 3.0, 14.0)
		_pivot.rotation.y = sin(t * rate) * deg_to_rad(10.0)
		_pivot.scale = Vector3(1.0 - sin(t * rate * 2.0) * 0.05, 1.0, 1.0 + sin(t * rate * 2.0) * 0.08)
	else:
		var pulse := sin(t * 3.0) * 0.04
		_pivot.rotation.y = lerp_angle(_pivot.rotation.y, 0.0, 0.1)
		_pivot.scale = Vector3(1.0 + pulse, 1.0 + pulse, 1.0 - pulse * 0.5)
	_pivot.position = Vector3(0.0, 0.0, -_lunge)


func _on_attack_performed(_attacker: Unit, _target: Unit) -> void:
	# Com fuzil, o corpo recua com o disparo; no contato, avança contra o alvo.
	var offset := -RECOIL_DISTANCE if _unit.data.is_ranged() else LUNGE_DISTANCE
	var tween := create_tween()
	tween.tween_property(self, "_lunge", offset, 0.05)
	tween.tween_property(self, "_lunge", 0.0, 0.15)


func _on_damaged(_unit_hit: Unit, _amount: float) -> void:
	if _overlay != null:
		_overlay.albedo_color.a = 0.55
		var fade := create_tween()
		fade.tween_property(_overlay, "albedo_color:a", 0.0, FLASH_TIME)
		return
	_material.emission = Color.WHITE
	_material.emission_energy_multiplier = FLASH_ENERGY
	var tween := create_tween()
	tween.tween_property(_material, "emission_energy_multiplier", 0.0, FLASH_TIME)
