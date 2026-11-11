extends PanelContainer
## Painel de comandos no canto inferior direito: botões de formação e de habilidades.
## Os botões chamam o SelectionController, que é quem dá as ordens às unidades.

const REFRESH := 0.1

var selection: SelectionController  ## Definido antes de entrar na árvore.

var _formation_buttons := {}  ## FormationData -> Button
var _ability_row: HBoxContainer
var _ability_buttons := {}  ## id da habilidade -> Button
var _ability_ids: Array[StringName] = []
var _timer := 0.0


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -16.0
	offset_right = -16.0
	offset_top = -52.0
	offset_bottom = -52.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN

	var column := VBoxContainer.new()
	add_child(column)

	column.add_child(_title("FORMAÇÃO"))
	var formation_row := HBoxContainer.new()
	column.add_child(formation_row)
	var group := ButtonGroup.new()
	for formation in selection.formation_manager.formations:
		var button := _make_button("%s  %s" % [OS.get_keycode_string(formation.hotkey), formation.display_name])
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = formation.description
		button.button_pressed = formation == selection.formation_manager.current
		button.pressed.connect(selection.set_formation.bind(formation))
		formation_row.add_child(button)
		_formation_buttons[formation] = button
	selection.formation_manager.formation_changed.connect(_on_formation_changed)

	column.add_child(_title("HABILIDADES"))
	_ability_row = HBoxContainer.new()
	column.add_child(_ability_row)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = REFRESH
	_refresh_abilities()


func _refresh_abilities() -> void:
	var abilities := selection.get_selection_abilities()
	var ids: Array[StringName] = []
	for ability in abilities:
		ids.append(ability.id)
	if ids != _ability_ids:
		_rebuild_ability_buttons(abilities)
		_ability_ids = ids
	var selected := selection.get_selected()
	for ability in abilities:
		# Pronta se pelo menos uma unidade selecionada pode usar agora.
		var shortest := INF
		for unit in selected:
			if unit.has_ability(ability):
				shortest = minf(shortest, unit.ability_cooldown(ability))
		var button: Button = _ability_buttons[ability.id]
		var label := "%s  %s" % [OS.get_keycode_string(ability.hotkey), ability.display_name]
		if shortest > 0.0:
			label += "  (%ds)" % ceili(shortest)
		button.text = label
		button.disabled = shortest > 0.0


func _rebuild_ability_buttons(abilities: Array[AbilityData]) -> void:
	for child in _ability_row.get_children():
		child.queue_free()
	_ability_buttons.clear()
	if abilities.is_empty():
		var none := Label.new()
		none.text = "Nenhuma (selecione unidades)"
		none.modulate = Color(1, 1, 1, 0.6)
		_ability_row.add_child(none)
		return
	for ability in abilities:
		var button := _make_button(ability.display_name)
		button.tooltip_text = ability.description
		button.pressed.connect(selection.use_ability_on_selection.bind(ability))
		_ability_row.add_child(button)
		_ability_buttons[ability.id] = button


func _on_formation_changed(formation: FormationData) -> void:
	if _formation_buttons.has(formation):
		_formation_buttons[formation].button_pressed = true


func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.modulate = Color(0.75, 0.85, 0.75)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE  ## Teclas continuam indo para os atalhos.
	return button
