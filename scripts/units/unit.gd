class_name Unit
extends CharacterBody3D
## Unidade base, aliada ou inimiga. Os atributos vêm de um UnitData.
## Estados de combate (plano técnico 3.5): IDLE, MOVING, ATTACKING e DEAD (incapacitada).
##   IDLE: parada. Procura inimigos dentro do alcance de detecção e com linha de visão.
##   MOVING: cumprindo ordem de movimento. Ignora inimigos até chegar.
##   ATTACKING: persegue o alvo pela navegação e ataca quando está no alcance e com visão.
## A unidade só decide e emite sinais. Barras de vida e efeitos ficam em scripts de interface.
## A origem do nó fica nos pés da unidade, no chão. O corpo é provisório até existirem os modelos 3D.

signal selected_changed(is_selected: bool)
signal damaged(unit: Unit, amount: float)
signal died(unit: Unit)
signal attack_performed(attacker: Unit, target: Unit)

enum Team { PLAYER, ENEMY }
enum State { IDLE, MOVING, ATTACKING, DEAD }

const LAYER_WORLD := 1  ## Chão e obstáculos.
const LAYER_UNITS := 2  ## Unidades, usada para escolher com o mouse.
const GROUP := &"units"
const SCAN_INTERVAL := 0.25  ## Segundos entre buscas de alvo, para não varrer todo quadro.
const REPATH_INTERVAL := 0.3  ## Segundos entre recálculos da rota de perseguição.
const LOSE_TARGET_FACTOR := 1.5  ## Alvo automático é abandonado além de detecção x este fator.

var data: UnitData
var team: Team = Team.PLAYER
var health: float = 0.0
var state: State = State.IDLE
var target: Unit = null
var selected: bool = false:
	set = set_selected

var _ordered_target := false  ## Alvo dado pelo jogador: não é abandonado pela distância.
var _attack_timer := 0.0
var _scan_timer := 0.0
var _repath_timer := 0.0
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
	_build_body()
	_build_selection_ring()
	_build_agent()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	match state:
		State.IDLE:
			_process_idle(delta)
		State.MOVING:
			_process_moving()
		State.ATTACKING:
			_process_attacking(delta)


# --- Ordens -------------------------------------------------------------------

## Ordem de deslocamento. O destino é ajustado para a área navegável mais próxima.
func move_to(world_pos: Vector3) -> void:
	if state == State.DEAD:
		return
	target = null
	_ordered_target = false
	state = State.MOVING
	_agent.target_position = _snap_to_navigation(world_pos)


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
	state = State.IDLE
	_halt()


# --- Consultas ----------------------------------------------------------------

func is_alive() -> bool:
	return state != State.DEAD


func is_moving() -> bool:
	return state == State.MOVING


func is_hostile_to(other: Unit) -> bool:
	return other != null and other.team != team


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
	health = maxf(health - amount, 0.0)
	damaged.emit(self, amount)
	if health <= 0.0:
		_die()
	elif state == State.IDLE and _is_valid_target(attacker):
		# Revida quando atacada parada, mesmo que o atacante esteja fora da detecção.
		_engage(attacker, false)


func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value
	if _ring != null:
		_ring.visible = value
	selected_changed.emit(value)


# --- Estados ------------------------------------------------------------------

func _process_idle(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	_scan_timer = SCAN_INTERVAL
	var found := _find_target()
	if found != null:
		_engage(found, false)


func _process_moving() -> void:
	if _agent.is_navigation_finished():
		state = State.IDLE
		_scan_timer = 0.0
		_halt()
		return
	_steer_along_path()


func _process_attacking(delta: float) -> void:
	if not _is_valid_target(target):
		_drop_target()
		return
	if not _ordered_target and _flat_distance(target) > data.detection_range * LOSE_TARGET_FACTOR:
		_drop_target()
		return

	if gap_to(target) <= data.attack_range and line_is_clear(get_center(), target.get_center()):
		_halt()
		_face(target.global_position - global_position)
		if _attack_timer <= 0.0:
			_attack_timer = data.attack_cooldown
			target.take_damage(data.damage, self)
			attack_performed.emit(self, target)
		return

	# Fora do alcance ou sem visão: persegue.
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = REPATH_INTERVAL
		_agent.target_position = _snap_to_navigation(target.global_position)
	if not _agent.is_navigation_finished():
		_steer_along_path()


func _engage(enemy: Unit, ordered: bool) -> void:
	target = enemy
	_ordered_target = ordered
	state = State.ATTACKING
	_repath_timer = 0.0


func _drop_target() -> void:
	target = null
	_ordered_target = false
	state = State.IDLE
	_scan_timer = 0.0
	_halt()


func _find_target() -> Unit:
	var best: Unit = null
	var best_dist := data.detection_range
	var eye := get_center()
	for node in get_tree().get_nodes_in_group(GROUP):
		var other := node as Unit
		if not _is_valid_target(other):
			continue
		var dist := _flat_distance(other)
		if dist > best_dist:
			continue
		if not line_is_clear(eye, other.get_center()):
			continue
		best = other
		best_dist = dist
	return best


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


# --- Movimento ----------------------------------------------------------------

func _steer_along_path() -> void:
	var to_next := _agent.get_next_path_position() - global_position
	to_next.y = 0.0
	_agent.velocity = to_next.normalized() * data.move_speed


func _halt() -> void:
	_agent.target_position = global_position
	_agent.velocity = Vector3.ZERO
	velocity = Vector3.ZERO


func _snap_to_navigation(world_pos: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, world_pos)


func _flat_distance(other: Unit) -> float:
	var d := other.global_position - global_position
	return Vector2(d.x, d.z).length()


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
	_agent.target_desired_distance = 0.6
	_agent.max_speed = data.move_speed
	_agent.avoidance_enabled = true
	_agent.velocity_computed.connect(_on_velocity_computed)
	add_child(_agent)
