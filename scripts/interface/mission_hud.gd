extends CanvasLayer
## Interface da missão: barra de dano tecidual, tempo, objetivos, avisos,
## ordem de missão (briefing) e tela de vitória ou derrota.
## Funciona com o jogo pausado (briefing e tela final). Só lê o MissionController.
## Teclas: Enter inicia a missão; na tela final, R reinicia e Esc sai.

const REFRESH := 0.1
const MESSAGE_TIME := 3.0
const COLOR_OK := Color(0.35, 0.95, 0.45)
const COLOR_BAD := Color(1.0, 0.35, 0.3)
const COLOR_PENDING := Color(0.92, 0.92, 0.92)
const COLOR_THREAT := Color(0.95, 0.72, 0.15)

var controller: MissionController  ## Definido antes de entrar na árvore.

var _tissue_bar: ProgressBar
var _tissue_fill: StyleBoxFlat
var _tissue_label: Label
var _time_label: Label
var _objectives: VBoxContainer
var _message: Label
var _message_timer := 0.0
var _briefing: Control
var _end_screen: Control
var _timer := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_top_bar()
	_build_objectives()
	_build_message()
	_build_briefing()
	controller.focus_controlled.connect(_on_focus_controlled)
	controller.secondary_failed.connect(_on_secondary_failed)
	controller.mission_ended.connect(_on_mission_ended)
	_refresh()


func _process(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			_message.visible = false
	_timer -= delta
	if _timer <= 0.0:
		_timer = REFRESH
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match controller.state:
		MissionController.State.BRIEFING:
			if key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				_start()
			elif key.keycode == KEY_ESCAPE:
				get_tree().quit()
		MissionController.State.WON, MissionController.State.LOST:
			if key.keycode == KEY_R:
				controller.restart()
			elif key.keycode == KEY_ESCAPE:
				get_tree().quit()


func _start() -> void:
	_briefing.visible = false
	controller.begin()


# --- Atualização ---------------------------------------------------------------

func _refresh() -> void:
	var mission := controller.mission
	var ratio := controller.tissue_damage / mission.tissue_damage_limit
	_tissue_bar.value = ratio * 100.0
	_tissue_fill.bg_color = COLOR_OK.lerp(COLOR_THREAT, clampf(ratio * 2.0, 0.0, 1.0)).lerp(COLOR_BAD, clampf(ratio * 2.0 - 1.0, 0.0, 1.0))
	var rate := controller.tissue_damage_rate()
	_tissue_label.text = "DANO TECIDUAL  %d%%" % floori(controller.tissue_damage)
	if rate > 0.0 and controller.state == MissionController.State.RUNNING:
		_tissue_label.text += "   (+%.1f%%/s)" % rate
	_time_label.text = "TEMPO  " + _format_time(controller.elapsed)
	_fill_objectives(_objectives, true)


func _fill_objectives(box: VBoxContainer, show_counts: bool) -> void:
	for child in box.get_children():
		child.queue_free()
	box.add_child(_line("OBJETIVOS PRINCIPAIS", Color(0.75, 0.85, 0.75), 13))
	for i in controller.mission.foci.size():
		var focus := controller.mission.foci[i]
		var done := controller.is_focus_controlled(i)
		var text := "%s  Controlar o foco %s" % ["[OK]" if done else "[  ]", focus.display_name]
		if show_counts and not done:
			var alive := controller.focus_enemies_alive(i)
			text += "  (%s)" % ("%d invasores" % alive if alive > 0 else "ocupe a área")
		box.add_child(_line(text, COLOR_OK if done else COLOR_PENDING))
	box.add_child(_line("SECUNDÁRIO", Color(0.75, 0.85, 0.75), 13))
	var failed := controller.has_secondary_failed()
	var secondary := "%s  Dano tecidual abaixo de %d%%" % ["[X]" if failed else "[  ]", controller.mission.secondary_tissue_limit]
	var color := COLOR_BAD if failed else COLOR_PENDING
	if controller.state == MissionController.State.WON and not failed:
		secondary = secondary.replace("[  ]", "[OK]")
		color = COLOR_OK
	box.add_child(_line(secondary, color))


# --- Eventos -------------------------------------------------------------------

func _on_focus_controlled(index: int) -> void:
	_show_message("FOCO %s CONTROLADO" % controller.mission.foci[index].display_name, COLOR_OK)


func _on_secondary_failed() -> void:
	_show_message("ALERTA: DANO TECIDUAL ACIMA DE %d%%" % controller.mission.secondary_tissue_limit, COLOR_BAD)


func _on_mission_ended(won: bool, reason: String) -> void:
	_refresh()
	_build_end_screen(won, reason)


func _show_message(text: String, color: Color) -> void:
	_message.text = text
	_message.modulate = color
	_message.visible = true
	_message_timer = MESSAGE_TIME


# --- Montagem ------------------------------------------------------------------

func _build_top_bar() -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.offset_top = 10.0
	box.custom_minimum_size = Vector2(420.0, 0.0)
	add_child(box)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	_tissue_label = _line("", COLOR_PENDING)
	_tissue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_tissue_label)
	_time_label = _line("", COLOR_PENDING)
	row.add_child(_time_label)
	_tissue_bar = ProgressBar.new()
	_tissue_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tissue_bar.show_percentage = false
	_tissue_bar.custom_minimum_size = Vector2(420.0, 12.0)
	_tissue_fill = StyleBoxFlat.new()
	_tissue_fill.bg_color = COLOR_OK
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	_tissue_bar.add_theme_stylebox_override("fill", _tissue_fill)
	_tissue_bar.add_theme_stylebox_override("background", back)
	box.add_child(_tissue_bar)


func _build_objectives() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -16.0
	panel.offset_right = -16.0
	panel.offset_top = 12.0
	add_child(panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	column.add_child(_line(controller.mission.display_name, COLOR_THREAT, 15))
	_objectives = VBoxContainer.new()
	_objectives.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_objectives)


func _build_message() -> void:
	_message = _line("", COLOR_OK, 26)
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.offset_top = 90.0
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_constant_override("outline_size", 6)
	_message.add_theme_color_override("font_outline_color", Color.BLACK)
	_message.visible = false
	add_child(_message)


func _build_briefing() -> void:
	var mission := controller.mission
	var column := _overlay_column()
	_briefing = column.get_meta("overlay")
	column.add_child(_line(mission.campaign.to_upper(), Color(0.75, 0.85, 0.75), 14))
	column.add_child(_line(mission.display_name, COLOR_THREAT, 28))
	column.add_child(_line("Dificuldade: %s" % "■".repeat(mission.difficulty), COLOR_PENDING, 13))
	var text := _line(mission.briefing, COLOR_PENDING, 17)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(760.0, 0.0)
	column.add_child(text)
	var objectives := VBoxContainer.new()
	column.add_child(objectives)
	_fill_objectives(objectives, false)
	column.add_child(_line("Derrota: dano tecidual chegar a %d%% ou perder todas as unidades." % mission.tissue_damage_limit, COLOR_BAD, 15))
	var start := _button("INICIAR OPERAÇÃO  (Enter)")
	start.pressed.connect(_start)
	column.add_child(start)


func _build_end_screen(won: bool, reason: String) -> void:
	var column := _overlay_column()
	_end_screen = column.get_meta("overlay")
	column.add_child(_line("MISSÃO CUMPRIDA" if won else "MISSÃO FRACASSADA", COLOR_OK if won else COLOR_BAD, 34))
	column.add_child(_line(reason, COLOR_PENDING, 18))
	var stats := [
		"Tempo: %s" % _format_time(controller.elapsed),
		"Dano tecidual: %d%%" % floori(controller.tissue_damage),
		"Invasores eliminados: %d/%d" % [controller.enemies_killed, controller.enemy_total()],
		"Unidades perdidas: %d/%d" % [controller.units_lost, controller.player_total()],
	]
	for stat in stats:
		column.add_child(_line(stat, COLOR_PENDING, 17))
	var objectives := VBoxContainer.new()
	column.add_child(objectives)
	_fill_objectives(objectives, false)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	var restart := _button("REINICIAR  (R)")
	restart.pressed.connect(controller.restart)
	row.add_child(restart)
	var quit := _button("SAIR  (Esc)")
	quit.pressed.connect(get_tree().quit)
	row.add_child(quit)


## Fundo escurecido que bloqueia cliques + painel central. Retorna a coluna do painel;
## o nó do fundo fica no metadado "overlay".
func _overlay_column() -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	column.set_meta("overlay", dim)
	return column


func _line(text: String, color: Color, size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(220.0, 40.0)
	return button


static func _format_time(seconds: float) -> String:
	var total := floori(seconds)
	return "%02d:%02d" % [floori(total / 60.0), total % 60]
