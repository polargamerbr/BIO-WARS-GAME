class_name MissionController
extends Node
## Executa uma missão a partir de um MissionData: cria as unidades, acompanha os objetivos,
## soma o dano tecidual e decide vitória ou derrota. Não desenha nada; a interface escuta os sinais.
##   BRIEFING: jogo pausado mostrando a ordem de missão, até o jogador começar.
##   RUNNING: em andamento.
##   WON / LOST: terminou. O jogo fica pausado na tela final.

signal state_changed(state: State)
signal focus_controlled(index: int)
signal secondary_failed
signal mission_ended(won: bool, reason: String)

enum State { BRIEFING, RUNNING, WON, LOST }

const CHECK_INTERVAL := 0.25  ## Segundos entre verificações de objetivos.

var mission: MissionData
## Cria uma unidade: (UnitData, posição, Unit.Team) -> Unit. Definido por quem cria o controlador.
var spawner: Callable

var state: State = State.BRIEFING
var tissue_damage := 0.0  ## Pontos percentuais.
var elapsed := 0.0  ## Segundos de missão em andamento.
var units_lost := 0
var enemies_killed := 0
var end_reason := ""

var _player_units: Array[Unit] = []
var _focus_enemies: Array = []  ## Por foco: Array[Unit] dos invasores que nasceram nele.
var _focus_controlled: Array[bool] = []
var _secondary_failed := false
var _check_timer := 0.0


## Cria todas as unidades da missão e entra no briefing (pausado).
func setup_mission(mission_data: MissionData) -> void:
	mission = mission_data
	for spawn in mission.player_units:
		var unit: Unit = spawner.call(spawn.unit, mission.start_zone_center + spawn.offset, Unit.Team.PLAYER)
		unit.died.connect(_on_player_unit_died)
		_player_units.append(unit)
	for focus in mission.foci:
		var group: Array[Unit] = []
		for spawn in focus.enemies:
			var enemy: Unit = spawner.call(spawn.unit, focus.center + spawn.offset, Unit.Team.ENEMY)
			enemy.died.connect(_on_enemy_died)
			group.append(enemy)
		_focus_enemies.append(group)
		_focus_controlled.append(false)
	_set_state(State.BRIEFING)
	get_tree().paused = true


## Sai do briefing e começa a missão.
func begin() -> void:
	if state != State.BRIEFING:
		return
	_set_state(State.RUNNING)
	get_tree().paused = false


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# --- Consultas para a interface ----------------------------------------------

func is_focus_controlled(index: int) -> bool:
	return _focus_controlled[index]


func focus_enemies_alive(index: int) -> int:
	var alive := 0
	for enemy in _focus_enemies[index]:
		if is_instance_valid(enemy) and enemy.is_alive():
			alive += 1
	return alive


func has_secondary_failed() -> bool:
	return _secondary_failed


func players_alive() -> int:
	return _player_units.filter(func(u): return is_instance_valid(u) and u.is_alive()).size()


func player_total() -> int:
	return _player_units.size()


func enemy_total() -> int:
	var total := 0
	for group in _focus_enemies:
		total += group.size()
	return total


## Pontos percentuais de dano tecidual por segundo neste momento.
func tissue_damage_rate() -> float:
	var rate := 0.0
	for group in _focus_enemies:
		for enemy in group:
			if is_instance_valid(enemy) and enemy.is_alive():
				rate += enemy.data.tissue_damage_rate
	return rate


# --- Andamento -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state != State.RUNNING:
		return
	elapsed += delta
	tissue_damage = minf(tissue_damage + tissue_damage_rate() * delta, mission.tissue_damage_limit)
	if not _secondary_failed and tissue_damage >= mission.secondary_tissue_limit:
		_secondary_failed = true
		secondary_failed.emit()

	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_INTERVAL
	_check_foci()
	_check_end()


func _check_foci() -> void:
	for i in mission.foci.size():
		if _focus_controlled[i] or focus_enemies_alive(i) > 0:
			continue
		if _player_inside(mission.foci[i]):
			_focus_controlled[i] = true
			focus_controlled.emit(i)


func _player_inside(focus: FocusData) -> bool:
	for unit in _player_units:
		if not is_instance_valid(unit) or not unit.is_alive():
			continue
		var d := unit.global_position - focus.center
		if Vector2(d.x, d.z).length() <= focus.radius:
			return true
	return false


func _check_end() -> void:
	# Derrota tem prioridade: se as duas acontecem no mesmo instante, o tecido já foi perdido.
	if tissue_damage >= mission.tissue_damage_limit:
		_finish(false, "O dano tecidual chegou ao limite. O tecido foi perdido.")
	elif players_alive() == 0:
		_finish(false, "Todas as unidades de defesa foram neutralizadas.")
	elif not _focus_controlled.has(false):
		_finish(true, "Todos os focos de invasão estão sob controle.")


func _finish(won: bool, reason: String) -> void:
	end_reason = reason
	_set_state(State.WON if won else State.LOST)
	mission_ended.emit(won, reason)
	get_tree().paused = true


func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)


func _on_player_unit_died(_unit: Unit) -> void:
	units_lost += 1


func _on_enemy_died(_unit: Unit) -> void:
	enemies_killed += 1
