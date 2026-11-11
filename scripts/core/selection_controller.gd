class_name SelectionController
extends Node
## Seleção e ordens de movimento com o mouse.
##   Clique esquerdo: seleciona uma unidade (clicar no vazio limpa a seleção).
##   Arrastar com o esquerdo: seleciona todas as unidades dentro do retângulo.
##   Shift: soma à seleção (ou tira, no clique em uma unidade já selecionada).
##   Clique direito no chão: manda as unidades selecionadas para o ponto.
##   Clique direito em um inimigo: ordem de ataque a ele.
## Só unidades do jogador podem ser selecionadas.
## A seleção não interfere no movimento: só guarda quais unidades receberão a ordem.

const DRAG_THRESHOLD := 6.0  ## Pixels que separam clique de arrasto.
const RAY_LENGTH := 500.0
const SLOT_GAP := 0.8  ## Espaço entre as unidades ao distribuir o destino, além dos corpos.
const INFO_REFRESH := 0.1  ## Segundos entre atualizações do painel (a vida muda em combate).

var _selected: Array[Unit] = []
var _info_timer := 0.0
var _pressing := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _overlay: BoxOverlay
var _info: Label


class BoxOverlay:
	extends Control
	var rect := Rect2()
	var active := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if active:
			draw_rect(rect, Color(0.35, 1.0, 0.45, 0.15), true)
			draw_rect(rect, Color(0.35, 1.0, 0.45, 0.9), false, 1.5)


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_overlay = BoxOverlay.new()
	layer.add_child(_overlay)
	_info = Label.new()
	_info.position = Vector2(16.0, 996.0)
	layer.add_child(_info)
	_refresh_info()


func get_selected() -> Array[Unit]:
	_prune_selection()
	return _selected


func _process(delta: float) -> void:
	_info_timer -= delta
	if _info_timer <= 0.0:
		_info_timer = INFO_REFRESH
		_refresh_info()


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_pressing = true
				_dragging = false
				_press_pos = button.position
			elif _pressing:
				_finish_press(button.position, button.shift_pressed)
		elif button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
			_order(button.position)
		return

	var motion := event as InputEventMouseMotion
	if motion != null and _pressing:
		if not _dragging and motion.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			_overlay.rect = Rect2(_press_pos, motion.position - _press_pos).abs()
			_overlay.active = true
			_overlay.queue_redraw()


func _finish_press(pos: Vector2, additive: bool) -> void:
	if _dragging:
		_box_select(Rect2(_press_pos, pos - _press_pos).abs(), additive)
	else:
		_click_select(pos, additive)
	_pressing = false
	_dragging = false
	_overlay.active = false
	_overlay.queue_redraw()


func _click_select(pos: Vector2, additive: bool) -> void:
	var hit := _raycast(pos, Unit.LAYER_UNITS)
	var unit: Unit = null
	if not hit.is_empty():
		unit = hit["collider"] as Unit
	if unit != null and not _is_selectable(unit):
		unit = null
	if unit == null:
		if not additive:
			_clear_selection()
	elif additive:
		_set_unit_selected(unit, not unit.selected)
	else:
		_clear_selection()
		_set_unit_selected(unit, true)
	_refresh_info()


func _box_select(rect: Rect2, additive: bool) -> void:
	var camera := get_viewport().get_camera_3d()
	if not additive:
		_clear_selection()
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if not _is_selectable(unit):
			continue
		var center := unit.get_center()
		if camera.is_position_behind(center):
			continue
		if rect.has_point(camera.unproject_position(center)):
			_set_unit_selected(unit, true)
	_refresh_info()


func _order(pos: Vector2) -> void:
	_prune_selection()
	if _selected.is_empty():
		return
	var unit_hit := _raycast(pos, Unit.LAYER_UNITS)
	if not unit_hit.is_empty():
		var enemy := unit_hit["collider"] as Unit
		if enemy != null and enemy.is_alive() and enemy.team != Unit.Team.PLAYER:
			for unit in _selected:
				unit.attack(enemy)
			_spawn_marker(enemy.global_position, Color(1.0, 0.75, 0.15, 0.9))
			return
	_order_move(pos)


func _order_move(pos: Vector2) -> void:
	var hit := _raycast(pos, Unit.LAYER_WORLD)
	if hit.is_empty():
		return
	var point: Vector3 = hit["position"]
	# Distribuição provisória em grade. O FormationManager (Etapa D) substitui isto.
	var slots := _grid_slots(point)
	for i in _selected.size():
		_selected[i].move_to(slots[i])
	_spawn_marker(point, Color(0.35, 1.0, 0.45, 0.9))


func _grid_slots(center: Vector3) -> Array[Vector3]:
	var widest := 0.0
	for unit in _selected:
		widest = maxf(widest, unit.data.body_radius * 2.0)
	var gap := widest + SLOT_GAP
	var count := _selected.size()
	var cols := ceili(sqrt(float(count)))
	var rows := ceili(float(count) / cols)
	var slots: Array[Vector3] = []
	for i in count:
		var col := i % cols
		var row := floori(float(i) / cols)
		var offset := Vector3((col - (cols - 1) * 0.5) * gap, 0.0, (row - (rows - 1) * 0.5) * gap)
		slots.append(center + offset)
	return slots


func _spawn_marker(point: Vector3, color: Color) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.7
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	torus.material = mat
	var marker := MeshInstance3D.new()
	marker.mesh = torus
	marker.scale = Vector3(1.0, 0.2, 1.0)
	marker.position = point + Vector3.UP * 0.08
	get_parent().add_child(marker)
	var tween := marker.create_tween().set_parallel(true)
	tween.tween_property(marker, "scale", Vector3(2.0, 0.2, 2.0), 0.5)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tween.chain().tween_callback(marker.queue_free)


func _raycast(pos: Vector2, mask: int) -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	var from := camera.project_ray_origin(pos)
	var to := from + camera.project_ray_normal(pos) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	return camera.get_world_3d().direct_space_state.intersect_ray(query)


func _set_unit_selected(unit: Unit, value: bool) -> void:
	unit.selected = value
	if value and not _selected.has(unit):
		_selected.append(unit)
	elif not value:
		_selected.erase(unit)


func _clear_selection() -> void:
	for unit in _selected:
		if is_instance_valid(unit):
			unit.selected = false
	_selected.clear()


func _is_selectable(unit: Unit) -> bool:
	return unit.team == Unit.Team.PLAYER and unit.is_alive()


func _prune_selection() -> void:
	for i in range(_selected.size() - 1, -1, -1):
		if not is_instance_valid(_selected[i]) or not _selected[i].is_alive():
			_selected.remove_at(i)


func _refresh_info() -> void:
	_prune_selection()
	if _selected.is_empty():
		_info.text = "Nenhuma unidade selecionada"
	elif _selected.size() == 1:
		var unit := _selected[0]
		_info.text = "%s  |  Vida %d/%d" % [unit.data.display_name, unit.health, unit.data.max_health]
	else:
		var counts := {}
		for unit in _selected:
			counts[unit.data.display_name] = counts.get(unit.data.display_name, 0) + 1
		var parts: PackedStringArray = []
		for unit_name in counts:
			parts.append("%dx %s" % [counts[unit_name], unit_name])
		_info.text = "Selecionadas: %d  |  %s" % [_selected.size(), ", ".join(parts)]
