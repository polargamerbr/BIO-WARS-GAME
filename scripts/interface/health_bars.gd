extends Control
## Barras de vida desenhadas em 2D sobre cada unidade viva.
## Só lê o estado das unidades; não participa do combate.

const BAR_SIZE := Vector2(40.0, 5.0)
const HEAD_ROOM := 0.35  ## Metros acima do topo do corpo.
const COLOR_BACK := Color(0.0, 0.0, 0.0, 0.75)
const COLOR_PLAYER := Color(0.3, 0.9, 0.35)
const COLOR_PLAYER_LOW := Color(0.95, 0.3, 0.25)  ## Aliado com pouca vida.
const COLOR_ENEMY := Color(0.95, 0.7, 0.15)  ## Amarelo: ameaça (GDD 2.2).
const LOW_HEALTH := 0.35


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		var top := unit.global_position + Vector3.UP * (unit.data.top_height() + HEAD_ROOM)
		if camera.is_position_behind(top):
			continue
		var anchor := camera.unproject_position(top)
		var rect := Rect2(anchor - Vector2(BAR_SIZE.x * 0.5, BAR_SIZE.y), BAR_SIZE)
		var ratio := clampf(unit.health / unit.data.max_health, 0.0, 1.0)
		var color := COLOR_ENEMY
		if unit.team == Unit.Team.PLAYER:
			color = COLOR_PLAYER_LOW if ratio < LOW_HEALTH else COLOR_PLAYER
		draw_rect(rect.grow(1.0), COLOR_BACK)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), color)
