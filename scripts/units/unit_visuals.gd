extends Node
## Animações procedurais do corpo provisório de uma unidade. Só lê o estado da unidade e
## reage aos sinais dela; não interfere em movimento nem combate. Quando existirem os modelos
## 3D com rig, isto é substituído pelas animações deles.
##   Soldado em pé: balança ao andar, inclina para a frente, respira parado.
##   Bastonete (bactéria): ondula ao andar e pulsa parado.
##   Ataque: avanço rápido para a frente (contato) ou recuo do disparo (fuzil). Dano recebido: clarão branco.

const WALK_BOB := 0.08  ## Metros de balanço vertical ao andar.
const WALK_STEP_RATE := 2.2  ## Passos por segundo a cada m/s de velocidade (com limite).
const LEAN_DEGREES := 7.0  ## Inclinação para a frente na velocidade máxima.
const LUNGE_DISTANCE := 0.35
const RECOIL_DISTANCE := 0.12
const FLASH_ENERGY := 2.5
const FLASH_TIME := 0.15

var _unit: Unit
var _pivot: Node3D
var _material: StandardMaterial3D
var _time := 0.0
var _lunge := 0.0
var _phase := 0.0  ## Defasagem aleatória para as unidades não se moverem em sincronia.


## pivot: nó que contém as malhas do corpo. material: material do corpo (para o clarão).
func setup(unit: Unit, pivot: Node3D, material: StandardMaterial3D) -> void:
	_unit = unit
	_pivot = pivot
	_material = material
	_material.emission_enabled = true
	_material.emission = Color.BLACK
	_phase = randf() * TAU
	unit.attack_performed.connect(_on_attack_performed)
	unit.damaged.connect(_on_damaged)


func _process(delta: float) -> void:
	if _unit == null or not _unit.is_alive():
		return
	_time += delta
	var speed := Vector2(_unit.velocity.x, _unit.velocity.z).length()
	var moving := speed > 0.3
	var speed_ratio := clampf(speed / maxf(_unit.data.move_speed, 0.1), 0.0, 1.5)
	var t := _time + _phase

	if _unit.data.body_shape == UnitData.BodyShape.ROD:
		_animate_rod(t, moving, speed)
	else:
		_animate_upright(t, moving, speed, speed_ratio)


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
	_material.emission = Color.WHITE
	_material.emission_energy_multiplier = FLASH_ENERGY
	var tween := create_tween()
	tween.tween_property(_material, "emission_energy_multiplier", 0.0, FLASH_TIME)
