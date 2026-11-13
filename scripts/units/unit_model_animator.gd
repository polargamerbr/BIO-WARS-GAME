extends Node
## Toca as animações do modelo 3D (com esqueleto) conforme o estado da unidade.
## Só lê a unidade; não interfere em movimento nem combate.
##   Parada: idle (ou defend, em formação que mantém posição). Andando: walk ou run, conforme a velocidade. Atacando parada: attack.
##   Eliminada: death, uma vez só.
## Os nomes das animações vêm do UnitData, porque cada exportação do Tripo nomeia diferente.
## Andar e correr no jogo vêm da navegação; por isso o avanço da animação ("root motion")
## é retirado do osso raiz, deixando só o balanço vertical.

const BLEND := 0.2  ## Segundos de transição entre animações.
const MOVING_SPEED := 0.3  ## m/s a partir do qual a unidade é considerada em movimento.
const RUN_THRESHOLD := 0.6  ## Fração da velocidade máxima a partir da qual usa a corrida.
const STRIPPED_META := &"biowar_root_motion_stripped"

var _unit: Unit
var _model: Node3D
var _player: AnimationPlayer
var _current := &""


func setup(unit: Unit, model: Node3D) -> void:
	_unit = unit
	_model = model
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	_player = players[0]
	var data := unit.data
	for anim_name in [data.anim_idle, data.anim_walk, data.anim_run, data.anim_attack, data.anim_defend]:
		_prepare_loop(anim_name)
	unit.died.connect(_on_died)
	# Começa em um ponto aleatório do idle, para a tropa não respirar em sincronia.
	_play(data.anim_idle)
	if _player.is_playing():
		_player.seek(randf() * _player.current_animation_length, true)


func _process(_delta: float) -> void:
	if _player == null or _unit == null or not _unit.is_alive():
		return
	var data := _unit.data
	var speed := Vector2(_unit.velocity.x, _unit.velocity.z).length()
	var wanted := data.anim_idle
	if speed > MOVING_SPEED:
		var running := speed >= data.move_speed * RUN_THRESHOLD
		wanted = data.anim_run if running and _has(data.anim_run) else data.anim_walk
		if not _has(wanted):
			wanted = data.anim_run
	elif _unit.state == Unit.State.ATTACKING:
		wanted = data.anim_attack
	elif _unit.state == Unit.State.DEFENDING and _has(data.anim_defend):
		wanted = data.anim_defend
	_play(wanted)


func _on_died(_dead: Unit) -> void:
	if _player == null:
		return
	if _has(_unit.data.anim_death):
		_player.play(_unit.data.anim_death, BLEND)
		_current = _unit.data.anim_death


func _play(anim_name: StringName) -> void:
	if anim_name == _current or not _has(anim_name):
		return
	_player.play(anim_name, BLEND)
	_current = anim_name


func _has(anim_name: StringName) -> bool:
	return anim_name != &"" and _player.has_animation(anim_name)


## Liga a repetição e tira o avanço horizontal do osso raiz. A Animation é compartilhada
## por todas as unidades do mesmo modelo, então só é ajustada uma vez.
func _prepare_loop(anim_name: StringName) -> void:
	if not _has(anim_name):
		return
	var anim := _player.get_animation(anim_name)
	anim.loop_mode = Animation.LOOP_LINEAR
	if anim.has_meta(STRIPPED_META):
		return
	anim.set_meta(STRIPPED_META, true)
	var root_bone := _unit.data.model_root_bone
	if root_bone == &"":
		return
	var skeletons := _model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	# Base do esqueleto em relação ao modelo: converte a posição do osso para o espaço do
	# modelo, onde Y é para cima, zera o deslocamento horizontal e converte de volta.
	var skeleton: Skeleton3D = skeletons[0]
	var bone := skeleton.find_bone(root_bone)
	if bone < 0:
		return
	var basis := (_model.global_transform.affine_inverse() * skeleton.global_transform).basis
	var inverse := basis.inverse()
	# Prende o osso na posição horizontal de repouso (a do modelo parado). O primeiro quadro
	# da animação não serve: a corrida já começa com o corpo deslocado para a frente.
	var rest: Vector3 = basis * skeleton.get_bone_rest(bone).origin
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not str(anim.track_get_path(t)).ends_with(":" + root_bone):
			continue
		for k in anim.track_get_key_count(t):
			var p: Vector3 = basis * anim.track_get_key_value(t, k)
			anim.track_set_key_value(t, k, inverse * Vector3(rest.x, p.y, rest.z))
