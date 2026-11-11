class_name Unit
extends CharacterBody3D
## Unidade base, aliada ou inimiga. Os atributos vêm de um UnitData.
## Estados de combate (plano técnico 3.5):
##   IDLE: parada. Procura inimigos dentro do alcance de detecção e com linha de visão.
##   MOVING: cumprindo ordem de movimento. Ignora inimigos até chegar, exceto quando está
##           voltando para a sua posição de formação depois de um combate.
##   ATTACKING: persegue o alvo pela navegação e ataca quando está no alcance e com visão.
##   DEFENDING: parada numa formação que mantém posição. Só ataca o que entra no alcance.
##   DEAD: incapacitada.
## Posição de formação (home_position): o ponto da última ordem de movimento, ou onde nasceu.
## Depois de um combate que ela mesma começou, a unidade volta para lá.
## A unidade só decide e emite sinais. Barras de vida e efeitos ficam em scripts de interface.
## A origem do nó fica nos pés da unidade, no chão. O corpo é provisório até existirem os modelos 3D.

signal selected_changed(is_selected: bool)
signal damaged(unit: Unit, amount: float)
signal died(unit: Unit)
signal attack_performed(attacker: Unit, target: Unit)
signal ability_used(unit: Unit, ability: AbilityData)

enum Team { PLAYER, ENEMY }
enum State { IDLE, MOVING, ATTACKING, DEFENDING, DEAD }

const LAYER_WORLD := 1  ## Chão e obstáculos.
const LAYER_UNITS := 2  ## Unidades, usada para escolher com o mouse.
const GROUP := &"units"
const SCAN_INTERVAL := 0.25  ## Segundos entre buscas de alvo, para não varrer todo quadro.
const REPATH_INTERVAL := 0.3  ## Segundos entre recálculos da rota de perseguição.
const LOSE_TARGET_FACTOR := 1.5  ## Alvo automático abandonado além de detecção x fator, medido da posição de formação.
const HOLD_REACH_MARGIN := 0.5  ## Metros de folga no alcance de quem mantém posição.
const HOME_TOLERANCE := 1.0  ## Metros. Mais longe que isso da posição de formação, a unidade volta.

var data: UnitData
var team: Team = Team.PLAYER
var health: float = 0.0
var state: State = State.IDLE
var target: Unit = null
var formation: FormationData = null
var home_position: Vector3 = Vector3.ZERO
var selected: bool = false:
	set = set_selected

var _ordered_target := false  ## Alvo dado pelo jogador: não é abandonado pela distância.
var _returning := false  ## Voltando para a posição de formação depois de um combate.
var _speed_cap := INF  ## Limite de velocidade imposto pela formação durante o deslocamento.
var _arrival_facing := Vector3.ZERO  ## Para onde virar ao chegar. Zero = não muda.
var _attack_timer := 0.0
var _scan_timer := 0.0
var _repath_timer := 0.0
var _cooldowns := {}  ## id da habilidade -> segundos restantes.
var _effects := {}  ## AbilityData.Effect -> {"magnitude": float, "remaining": float}
var _agent: NavigationAgent3D
var _ring: MeshInstance3D


## Deve ser chamada antes de add_child.
func setup(unit_data: UnitData, unit_team: Team = Team.PLAYER) -> void:
	data = unit_data
	team = unit_team
	health = unit_data.max_health


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = LAYER_UNITS
	collision_mask = LAYER_WORLD
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	home_position = global_position
	_build_body()
	_build_selection_ring()
	_build_agent()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_tick_timers(delta)
	match state:
		State.IDLE, State.DEFENDING:
			_process_resting(delta)
		State.MOVING:
			_process_moving(delta)
		State.ATTACKING:
			_process_attacking(delta)


# --- Ordens -------------------------------------------------------------------

## Ordem de deslocamento. O destino é ajustado para a área navegável mais próxima e vira a
## nova posição de formação. facing: direção para virar ao chegar. speed_cap: limite do grupo.
func move_to(world_pos: Vector3, facing: Vector3 = Vector3.ZERO, speed_cap: float = INF) -> void:
	if state == State.DEAD:
		return
	target = null
	_ordered_target = false
	_returning = false
	_arrival_facing = facing
	_speed_cap = speed_cap
	home_position = _snap_to_navigation(world_pos)
	state = State.MOVING
	_agent.target_position = home_position


## Ordem de ataque a um alvo específico. A unidade persegue até o alvo morrer.
func attack(enemy: Unit) -> void:
	if state == State.DEAD or not is_hostile_to(enemy) or not enemy.is_alive():
		return
	_engage(enemy, true)


func stop() -> void:
	if state == State.DEAD:
		return
	target = null
	_ordered_target = false
	_returning = false
	home_position = global_position
	state = _resting_state()
	_halt()


## Usa a habilidade se ela estiver pronta. Retorna true se foi usada.
func use_ability(ability: AbilityData) -> bool:
	if state == State.DEAD or ability_cooldown(ability) > 0.0:
		return false
	_cooldowns[ability.id] = ability.cooldown
	if ability.radius <= 0.0:
		apply_effect(ability.effect, ability.magnitude, ability.duration)
	else:
		for node in get_tree().get_nodes_in_group(GROUP):
			var ally := node as Unit
			if ally.team == team and ally.is_alive() and _flat_distance(ally) <= ability.radius:
				ally.apply_effect(ability.effect, ability.magnitude, ability.duration)
	ability_used.emit(self, ability)
	return true


## Efeito temporário. Repetir o mesmo efeito renova a duração; não acumula.
func apply_effect(effect: AbilityData.Effect, magnitude: float, duration: float) -> void:
	var current: Dictionary = _effects.get(effect, {"magnitude": 1.0, "remaining": 0.0})
	_effects[effect] = {
		"magnitude": maxf(current["magnitude"], magnitude),
		"remaining": maxf(current["remaining"], duration),
	}


# --- Consultas ----------------------------------------------------------------

func is_alive() -> bool:
	return state != State.DEAD


func is_moving() -> bool:
	return state == State.MOVING


func is_hostile_to(other: Unit) -> bool:
	return other != null and other.team != team


func holds_position() -> bool:
	return formation != null and formation.hold_position


func has_ability(ability: AbilityData) -> bool:
	for own in data.abilities:
		if own.id == ability.id:
			return true
	return false


func ability_cooldown(ability: AbilityData) -> float:
	return _cooldowns.get(ability.id, 0.0)


func effect_remaining(effect: AbilityData.Effect) -> float:
	return _effects[effect]["remaining"] if _effects.has(effect) else 0.0


func current_speed() -> float:
	return minf(data.move_speed * _effect_multiplier(AbilityData.Effect.SPEED), _speed_cap)


func current_damage() -> float:
	return data.damage * _effect_multiplier(AbilityData.Effect.DAMAGE)


## Multiplicador de dano recebido pela formação. Só vale com a unidade parada ou lutando.
func damage_taken_multiplier() -> float:
	if formation == null or state == State.MOVING:
		return 1.0
	return formation.damage_taken_multiplier


## Centro do corpo no mundo, usado para mira, linha de visão e projeção na tela.
func get_center() -> Vector3:
	return global_position + Vector3.UP * data.center_height()


## Distância entre as bordas dos dois corpos, no plano do chão.
func gap_to(other: Unit) -> float:
	return _flat_distance(other) - data.body_radius - other.data.body_radius


## True se nenhum obstáculo do mundo bloqueia a linha entre os dois pontos.
func line_is_clear(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, LAYER_WORLD)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# --- Dano ---------------------------------------------------------------------

func take_damage(amount: float, attacker: Unit = null) -> void:
	if state == State.DEAD:
		return
	var final_amount := amount * damage_taken_multiplier()
	health = maxf(health - final_amount, 0.0)
	damaged.emit(self, final_amount)
	if health <= 0.0:
		_die()
		return
	# Revida quando atacada parada ou voltando para a formação.
	var can_react := state in [State.IDLE, State.DEFENDING] or (state == State.MOVING and _returning)
	if can_react and _is_valid_target(attacker) and _within_reach(attacker):
		_engage(attacker, false)


func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value
	if _ring != null:
		_ring.visible = value
	selected_changed.emit(value)


# --- Estados ------------------------------------------------------------------

func _process_resting(delta: float) -> void:
	_scan_for_target(delta)


func _process_moving(delta: float) -> void:
	if _agent.is_navigation_finished():
		_arrive()
		return
	if _returning and _scan_for_target(delta):
		return
	_steer_along_path()


func _process_attacking(delta: float) -> void:
	if not _is_valid_target(target):
		_drop_target()
		return
	if not _ordered_target:
		if holds_position() and not _within_reach(target):
			_drop_target()
			return
		if _flat_distance_to_point(target.global_position, home_position) > data.detection_range * LOSE_TARGET_FACTOR:
			_drop_target()
			return

	if gap_to(target) <= data.attack_range and line_is_clear(get_center(), target.get_center()):
		_halt()
		_face(target.global_position - global_position)
		if _attack_timer <= 0.0:
			_attack_timer = data.attack_cooldown
			target.take_damage(current_damage(), self)
			attack_performed.emit(self, target)
		return

	# Fora do alcance ou sem visão: persegue.
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = REPATH_INTERVAL
		_agent.target_position = _snap_to_navigation(target.global_position)
	if not _agent.is_navigation_finished():
		_steer_along_path()


## Procura alvo a cada SCAN_INTERVAL. Retorna true se entrou em combate.
func _scan_for_target(delta: float) -> bool:
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return false
	_scan_timer = SCAN_INTERVAL
	var found := _find_target()
	if found == null:
		return false
	_engage(found, false)
	return true


func _arrive() -> void:
	state = _resting_state()
	_returning = false
	_speed_cap = INF
	_scan_timer = 0.0
	_halt()
	if _arrival_facing != Vector3.ZERO:
		rotation.y = atan2(-_arrival_facing.x, -_arrival_facing.z)


func _engage(enemy: Unit, ordered: bool) -> void:
	target = enemy
	_ordered_target = ordered
	_returning = false
	_speed_cap = INF
	state = State.ATTACKING
	_repath_timer = 0.0


func _drop_target() -> void:
	if _ordered_target:
		# Depois de uma ordem de ataque, a unidade fica onde terminou.
		home_position = global_position
	target = null
	_ordered_target = false
	_scan_timer = 0.0
	if _flat_distance_to_point(global_position, home_position) > HOME_TOLERANCE:
		state = State.MOVING
		_returning = true
		_agent.target_position = home_position
	else:
		state = _resting_state()
		_halt()


func _resting_state() -> State:
	return State.DEFENDING if holds_position() else State.IDLE


func _find_target() -> Unit:
	var best: Unit = null
	var best_dist := INF
	var eye := get_center()
	for node in get_tree().get_nodes_in_group(GROUP):
		var other := node as Unit
		if not _is_valid_target(other) or not _within_reach(other):
			continue
		var dist := _flat_distance(other)
		if dist >= best_dist:
			continue
		if not line_is_clear(eye, other.get_center()):
			continue
		best = other
		best_dist = dist
	return best


## Quem mantém posição só alcança o que está no alcance de ataque. Os demais, o que detectam.
func _within_reach(other: Unit) -> bool:
	if holds_position():
		return gap_to(other) <= data.attack_range + HOLD_REACH_MARGIN
	return _flat_distance(other) <= data.detection_range


func _is_valid_target(other: Unit) -> bool:
	return other != null and is_instance_valid(other) and other.is_alive() and is_hostile_to(other)


func _die() -> void:
	state = State.DEAD
	target = null
	selected = false
	remove_from_group(GROUP)
	collision_layer = 0
	_agent.avoidance_enabled = false
	velocity = Vector3.ZERO
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.05, 1.2), 0.5)
	tween.tween_callback(queue_free)


func _tick_timers(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] -= delta
		if _cooldowns[key] <= 0.0:
			_cooldowns.erase(key)
	for key in _effects.keys():
		_effects[key]["remaining"] -= delta
		if _effects[key]["remaining"] <= 0.0:
			_effects.erase(key)


func _effect_multiplier(effect: AbilityData.Effect) -> float:
	return _effects[effect]["magnitude"] if _effects.has(effect) else 1.0


# --- Movimento ----------------------------------------------------------------

func _steer_along_path() -> void:
	var speed := current_speed()
	_agent.max_speed = speed
	var to_next := _agent.get_next_path_position() - global_position
	to_next.y = 0.0
	_agent.velocity = to_next.normalized() * speed


func _halt() -> void:
	_agent.target_position = global_position
	_agent.velocity = Vector3.ZERO
	velocity = Vector3.ZERO


func _snap_to_navigation(world_pos: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, world_pos)


func _flat_distance(other: Unit) -> float:
	return _flat_distance_to_point(global_position, other.global_position)


func _flat_distance_to_point(a: Vector3, b: Vector3) -> float:
	return Vector2(b.x - a.x, b.z - a.z).length()


func _face(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length_squared() < 0.0001:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 0.25)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if state == State.DEAD:
		return
	velocity = Vector3(safe_velocity.x, 0.0, safe_velocity.z)
	if velocity.length_squared() > 0.01:
		_face(velocity)
	move_and_slide()


# --- Montagem -----------------------------------------------------------------

func _build_body() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.body_color
	mat.roughness = 0.8
	var capsule := CapsuleMesh.new()
	capsule.radius = data.body_radius
	capsule.height = data.body_height
	capsule.material = mat
	var body := MeshInstance3D.new()
	body.mesh = capsule
	var shape := CapsuleShape3D.new()
	shape.radius = data.body_radius
	shape.height = data.body_height
	var collider := CollisionShape3D.new()
	collider.shape = shape

	var center := Vector3.UP * data.center_height()
	body.position = center
	collider.position = center
	if data.body_shape == UnitData.BodyShape.ROD:
		# Bastonete deitado ao longo do eixo de frente (-Z).
		body.rotation_degrees.x = 90.0
		collider.rotation_degrees.x = 90.0
	add_child(collider)
	add_child(body)

	if data.body_shape == UnitData.BodyShape.UPRIGHT:
		# Visor azul no lado da frente (-Z), para ver para onde o soldado está virado.
		var visor_mat := StandardMaterial3D.new()
		visor_mat.albedo_color = Color(0.25, 0.55, 0.95)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.1, 0.3, 0.6)
		var visor_mesh := BoxMesh.new()
		visor_mesh.size = Vector3(data.body_radius * 1.1, data.body_radius * 0.35, data.body_radius * 0.5)
		visor_mesh.material = visor_mat
		var visor := MeshInstance3D.new()
		visor.mesh = visor_mesh
		visor.position = Vector3(0.0, data.body_height * 0.78, -data.body_radius * 0.85)
		add_child(visor)


func _build_selection_ring() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = data.body_radius + 0.15
	torus.outer_radius = data.body_radius + 0.35
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.35, 1.0, 0.45)
	torus.material = mat
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.position.y = 0.06
	_ring.scale.y = 0.3
	_ring.visible = selected
	add_child(_ring)


func _build_agent() -> void:
	_agent = NavigationAgent3D.new()
	_agent.radius = data.body_radius
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 0.35  ## Precisão da chegada à posição de formação.
	_agent.max_speed = data.move_speed
	_agent.avoidance_enabled = true
	_agent.velocity_computed.connect(_on_velocity_computed)
	add_child(_agent)
