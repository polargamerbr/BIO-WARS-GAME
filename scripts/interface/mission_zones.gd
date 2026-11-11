extends Node3D
## Marcações das áreas da missão no chão: área inicial e focos de invasão.
## Foco ativo em amarelo (ameaça); controlado em verde (GDD 2.2).

const COLOR_START := Color(0.25, 0.75, 0.30, 0.22)
const COLOR_FOCUS := Color(0.95, 0.72, 0.15, 0.16)
const COLOR_FOCUS_EDGE := Color(0.95, 0.72, 0.15, 0.85)
const COLOR_DONE := Color(0.3, 0.9, 0.4, 0.16)
const COLOR_DONE_EDGE := Color(0.3, 0.9, 0.4, 0.85)

var _focus_parts: Array = []  ## Por foco: [disco, borda, rótulo]


func build(controller: MissionController) -> void:
	var mission := controller.mission
	_add_disc("StartZone", mission.start_zone_center, mission.start_zone_radius, COLOR_START)
	for focus in mission.foci:
		var disc := _add_disc("Focus" + focus.display_name, focus.center, focus.radius, COLOR_FOCUS)
		var edge := _add_edge(focus.center, focus.radius, COLOR_FOCUS_EDGE)
		var label := Label3D.new()
		label.text = "FOCO " + focus.display_name
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.pixel_size = 0.012
		label.font_size = 40
		label.outline_size = 8
		label.modulate = COLOR_FOCUS_EDGE
		label.position = focus.center + Vector3(0.0, 0.3, -focus.radius - 0.8)
		add_child(label)
		_focus_parts.append([disc, edge, label])
	controller.focus_controlled.connect(_on_focus_controlled)


func _on_focus_controlled(index: int) -> void:
	var parts: Array = _focus_parts[index]
	(parts[0].mesh.material as StandardMaterial3D).albedo_color = COLOR_DONE
	(parts[1].mesh.material as StandardMaterial3D).albedo_color = COLOR_DONE_EDGE
	var label: Label3D = parts[2]
	label.text += " — CONTROLADO"
	label.modulate = COLOR_DONE_EDGE


func _add_disc(zone_name: String, center: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.04
	mesh.material = _flat_material(color)
	var disc := MeshInstance3D.new()
	disc.name = zone_name
	disc.mesh = mesh
	disc.position = center + Vector3.UP * 0.03
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	return disc


func _add_edge(center: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.12
	torus.outer_radius = radius
	torus.rings = 96
	torus.material = _flat_material(color)
	var edge := MeshInstance3D.new()
	edge.mesh = torus
	edge.scale.y = 0.15
	edge.position = center + Vector3.UP * 0.05
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(edge)
	return edge


func _flat_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	return mat
