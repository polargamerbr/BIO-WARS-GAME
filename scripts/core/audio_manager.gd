class_name AudioManager
extends Node
## Toca os efeitos sonoros reagindo aos sinais do jogo (unidades, seleção e missão).
## Usa um conjunto fixo de players e limita a repetição de cada som, para o combate com
## muitas unidades não virar ruído. Sons não posicionais, porque a câmera é ortogonal e distante.
## Tecla M liga e desliga o som. Funciona com o jogo pausado (sons da tela final).

const SFX_DIR := "res://assets/audio/sfx/"
const POOL_SIZE := 12
const PITCH_VARIATION := 0.08

## nome do som -> [volume em dB, intervalo mínimo entre repetições em segundos]
const SOUNDS := {
	"select": [-10.0, 0.05],
	"order_move": [-8.0, 0.05],
	"order_attack": [-8.0, 0.05],
	"attack_player": [-14.0, 0.07],
	"rifle_shot": [-15.0, 0.06],
	"attack_enemy": [-16.0, 0.07],
	"death_enemy": [-6.0, 0.05],
	"death_player": [-4.0, 0.05],
	"ability_speed": [-8.0, 0.1],
	"ability_cytokine": [-7.0, 0.1],
	"focus_controlled": [-4.0, 0.2],
	"alert": [-6.0, 0.5],
	"victory": [-3.0, 1.0],
	"defeat": [-3.0, 1.0],
}

var muted := false

var _streams := {}
var _last_played := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound_name in SOUNDS:
		_streams[sound_name] = load(SFX_DIR + sound_name + ".wav")
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)


func play(sound_name: String, vary_pitch: bool = true) -> void:
	if muted or not _streams.has(sound_name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var min_gap: float = SOUNDS[sound_name][1]
	if now - _last_played.get(sound_name, -INF) < min_gap:
		return
	_last_played[sound_name] = now
	var player := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = _streams[sound_name]
	player.volume_db = SOUNDS[sound_name][0]
	player.pitch_scale = 1.0 + randf_range(-PITCH_VARIATION, PITCH_VARIATION) if vary_pitch else 1.0
	player.play()


# --- Ligações com o jogo ---------------------------------------------------------

func watch_unit(unit: Unit) -> void:
	unit.attack_performed.connect(func(attacker: Unit, _t: Unit):
		if attacker.data.is_ranged():
			play("rifle_shot")
		else:
			play("attack_player" if attacker.team == Unit.Team.PLAYER else "attack_enemy"))
	unit.died.connect(func(dead: Unit):
		play("death_player" if dead.team == Unit.Team.PLAYER else "death_enemy"))
	unit.ability_used.connect(func(_u: Unit, ability: AbilityData):
		play("ability_speed" if ability.effect == AbilityData.Effect.SPEED else "ability_cytokine"))


func watch_selection(selection: SelectionController) -> void:
	selection.selection_made.connect(func(): play("select"))
	selection.order_issued.connect(func(kind: StringName):
		play("order_attack" if kind == &"attack" else "order_move"))


func watch_mission(mission: MissionController) -> void:
	mission.focus_controlled.connect(func(_i: int): play("focus_controlled", false))
	mission.secondary_failed.connect(func(): play("alert", false))
	mission.mission_ended.connect(func(won: bool, _reason: String): play("victory" if won else "defeat", false))


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_M:
		muted = not muted
		if muted:
			for player in _pool:
				player.stop()
		get_viewport().set_input_as_handled()
