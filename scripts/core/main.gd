extends Node3D
## Campo de batalha de teste e montagem da partida: mapa, missão, controles e interface.
## O cenário é montado por código para a fundação ficar pequena e sem risco de
## erro em arquivo de cena. Quando o sistema de mapas existir, isto vira cena própria.

const CameraRigScript := preload("res://scripts/core/camera_rig.gd")
const SelectionControllerScript := preload("res://scripts/core/selection_controller.gd")
const UnitScript := preload("res://scripts/units/unit.gd")
const CombatFxScript := preload("res://scripts/combat/combat_fx.gd")
const HealthBarsScript := preload("res://scripts/interface/health_bars.gd")
const CommandPanelScript := preload("res://scripts/interface/command_panel.gd")
const FormationManagerScript := preload("res://scripts/formations/formation_manager.gd")
const MissionControllerScript := preload("res://scripts/missions/mission_controller.gd")
const MissionZonesScript := preload("res://scripts/interface/mission_zones.gd")
const MissionHudScript := preload("res://scripts/interface/mission_hud.gd")
const AudioManagerScript := preload("res://scripts/core/audio_manager.gd")

const MAP_SIZE := 80.0
## Missão carregada ao abrir. Unidades, focos e condições vêm todos deste arquivo.
const MISSION_PATH := "res://data/missions/mission_001_first_contact.tres"

var _fps_label: Label
var _nav_region: NavigationRegion3D
var _combat_fx: Node3D
var _selection: SelectionController
var _mission: MissionController
var _audio: AudioManager
var _obstacle_boxes: Array[AABB] = []


func _ready() -> void:
	_build_environment()
	_build_navigation_region()
	_build_ground()
	_build_obstacles()
	_bake_navigation()
	_build_grid()
	_build_camera()
	_build_mission()
	_build_selection()
	_build_hud()


func _process(_delta: float) -> void:
	_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F11:
		var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if is_full else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	elif key.keycode == KEY_ESCAPE:
		get_tree().quit()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.35, 0.35)
	env.ambient_light_energy = 0.8
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_navigation_region() -> void:
	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "NavigationRegion"
	add_child(_nav_region)


func _bake_navigation() -> void:
	## Só o chão é superfície andável. Os obstáculos entram como bloqueios que recortam a malha,
	## senão o topo deles viraria uma ilha navegável impossível de alcançar.
	## O raio do agente (0,75 m) cobre a maior unidade, o Macrophage.
	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	nav_mesh.agent_radius = 0.75
	nav_mesh.agent_height = 2.0

	var source := NavigationMeshSourceGeometryData3D.new()
	var h := MAP_SIZE * 0.5
	var ground_faces := PackedVector3Array([
		Vector3(-h, 0.0, -h), Vector3(h, 0.0, -h), Vector3(h, 0.0, h),
		Vector3(-h, 0.0, -h), Vector3(h, 0.0, h), Vector3(-h, 0.0, h),
	])
	source.add_faces(ground_faces, Transform3D.IDENTITY)
	for box in _obstacle_boxes:
		var lo := box.position
		var hi := box.end
		var outline := PackedVector3Array([
			Vector3(lo.x, 0.0, lo.z), Vector3(hi.x, 0.0, lo.z),
			Vector3(hi.x, 0.0, hi.z), Vector3(lo.x, 0.0, hi.z),
		])
		# carve = false para o raio do agente também afastar o caminho dos obstáculos.
		source.add_projected_obstruction(outline, 0.0, box.size.y, false)

	NavigationServer3D.bake_from_source_geometry_data(nav_mesh, source)
	_nav_region.navigation_mesh = nav_mesh

	# O bake deixa a malha um pouco acima do chão. Abaixa a região por esse desvio, para a
	# malha ficar em y = 0 junto com os pés das unidades (as distâncias de chegada são em 3D).
	var lowest := INF
	for v in nav_mesh.get_vertices():
		lowest = minf(lowest, v.y)
	_nav_region.position.y = -lowest


func _add_static_block(
	block_name: String, center: Vector3, size: Vector3, material: Material, blocks_navigation := false
) -> void:
	## Bloco sólido com colisão (camada do mundo) e malha visível.
	if blocks_navigation:
		_obstacle_boxes.append(AABB(center - size * 0.5, size))
	var body := StaticBody3D.new()
	body.name = block_name
	body.collision_layer = Unit.LAYER_WORLD
	body.collision_mask = 0
	body.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	body.add_child(visual)
	_nav_region.add_child(body)


func _build_ground() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.08, 0.10)
	mat.roughness = 0.85
	# Placa de 1 m de espessura com o topo em y = 0.
	_add_static_block("Ground", Vector3(0.0, -0.5, 0.0), Vector3(MAP_SIZE, 1.0, MAP_SIZE), mat)


func _build_grid() -> void:
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	var half := MAP_SIZE * 0.5
	var step := 4.0
	var p := -half
	while p <= half:
		lines.surface_add_vertex(Vector3(p, 0.02, -half))
		lines.surface_add_vertex(Vector3(p, 0.02, half))
		lines.surface_add_vertex(Vector3(-half, 0.02, p))
		lines.surface_add_vertex(Vector3(half, 0.02, p))
		p += step
	lines.surface_end()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.55, 0.16, 0.18, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var grid := MeshInstance3D.new()
	grid.name = "Grid"
	grid.mesh = lines
	grid.material_override = mat
	add_child(grid)


func _build_obstacles() -> void:
	## Blocos que representam estruturas de tecido. Posição e tamanho em metros.
	var obstacles := [
		[Vector3(-6.0, 1.5, -4.0), Vector3(6.0, 3.0, 4.0)],
		[Vector3(8.0, 1.0, 6.0), Vector3(4.0, 2.0, 8.0)],
		[Vector3(-14.0, 1.0, 10.0), Vector3(8.0, 2.0, 3.0)],
		[Vector3(14.0, 1.5, -14.0), Vector3(5.0, 3.0, 5.0)],
		[Vector3(0.0, 1.0, 20.0), Vector3(10.0, 2.0, 3.0)],
	]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.05, 0.07)
	mat.roughness = 0.9
	var i := 0
	for o in obstacles:
		_add_static_block("Obstacle%d" % i, o[0], o[1], mat, true)
		i += 1


func _build_camera() -> void:
	var rig := CameraRigScript.new()
	rig.name = "CameraRig"
	rig.map_half_extent = MAP_SIZE * 0.5
	rig.position = Vector3(-18.0, 0.0, 14.0)
	add_child(rig)


func _build_mission() -> void:
	_audio = AudioManagerScript.new() as AudioManager
	_audio.name = "AudioManager"
	add_child(_audio)
	_combat_fx = CombatFxScript.new()
	_combat_fx.name = "CombatFx"
	add_child(_combat_fx)
	_mission = MissionControllerScript.new() as MissionController
	_mission.name = "MissionController"
	_mission.spawner = spawn_unit
	add_child(_mission)
	_mission.setup_mission(load(MISSION_PATH) as MissionData)
	var zones := MissionZonesScript.new()
	zones.name = "MissionZones"
	add_child(zones)
	zones.build(_mission)
	_audio.watch_mission(_mission)


## Cria uma unidade no mapa. Usada pela missão (e por testes).
func spawn_unit(unit_data: UnitData, pos: Vector3, team: Unit.Team) -> Unit:
	var unit := UnitScript.new() as Unit
	unit.setup(unit_data, team)
	unit.position = pos
	add_child(unit)
	_combat_fx.watch(unit)
	_audio.watch_unit(unit)
	return unit


func _build_selection() -> void:
	var formations := FormationManagerScript.new() as FormationManager
	formations.name = "FormationManager"
	add_child(formations)
	_selection = SelectionControllerScript.new() as SelectionController
	_selection.name = "SelectionController"
	_selection.formation_manager = formations
	add_child(_selection)
	_audio.watch_selection(_selection)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	layer.add_child(HealthBarsScript.new())

	var panel := CommandPanelScript.new()
	panel.name = "CommandPanel"
	panel.selection = _selection
	layer.add_child(panel)

	var title := Label.new()
	title.text = "BIOWAR: FRONTLINE  |  Prototype 001  |  Etapa F: polimento"
	title.position = Vector2(16.0, 12.0)
	layer.add_child(title)

	_fps_label = Label.new()
	_fps_label.position = Vector2(16.0, 40.0)
	layer.add_child(_fps_label)

	var help := Label.new()
	help.text = "Esq: selecionar (arrastar, Shift)  |  Dir: mover/atacar  |  Ctrl+1-9: criar grupo, 1-9: chamar (2x: câmera)  |  F1-F4: formação  |  Q/E: habilidades  |  WASD/Roda: câmera  |  M: som  |  F11  |  Esc"
	help.position = Vector2(16.0, 1040.0)
	layer.add_child(help)

	var mission_hud := MissionHudScript.new()
	mission_hud.name = "MissionHud"
	mission_hud.controller = _mission
	add_child(mission_hud)
