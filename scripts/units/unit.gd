class_name Unit
extends CharacterBody3D
## Unidade base. Os atributos vêm de um UnitData; a unidade só sabe se mover e ser selecionada.
## O corpo é provisório (cápsula) até existirem os modelos 3D. Combate fica para a Etapa C.
## A origem do nó fica nos pés da unidade, no chão.

signal selected_changed(is_selected: bool)

const LAYER_WORLD := 1  ## Chão e obstáculos.
const LAYER_UNITS := 2  ## Unidades, usada para escolher com o mouse.
const GROUP := &"units"

var data: UnitData
var health: float = 0.0
var selected: bool = false:
	set = set_selected

var _agent: NavigationAgent3D
var _ring: MeshInstance3D


## Deve ser chamada antes de add_child.
func setup(unit_data: UnitData) -> void:
	data = unit_data
	health = unit_data.max_health


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = LAYER_UNITS
	collision_mask = LAYER_WORLD
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_build_body()
	_build_selection_ring()
	_build_agent()


func _physics_process(_delta: float) -> void:
	if _agent.is_navigation_finished():
		return
	var to_next := _agent.get_next_path_position() - global_position
	to_next.y = 0.0
	_agent.velocity = to_next.normalized() * data.move_speed


## Centro do corpo no mundo, usado para projetar a unidade na tela.
func get_center() -> Vector3:
	return global_position + Vector3.UP * (data.body_height * 0.5)


## Ordena o deslocamento até o ponto. O destino é ajustado para a área navegável mais próxima.
func move_to(world_pos: Vector3) -> void:
	var nav_map := get_world_3d().navigation_map
	_agent.target_position = NavigationServer3D.map_get_closest_point(nav_map, world_pos)


func stop() -> void:
	_agent.target_position = global_position
	velocity = Vector3.ZERO


func is_moving() -> bool:
	return not _agent.is_navigation_finished()


func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value
	if _ring != null:
		_ring.visible = value
	selected_changed.emit(value)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = Vector3(safe_velocity.x, 0.0, safe_velocity.z)
	if velocity.length_squared() > 0.01:
		var target_yaw := atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 0.25)
	move_and_slide()


func _build_body() -> void:
	var half_h := data.body_height * 0.5
	var shape := CapsuleShape3D.new()
	shape.radius = data.body_radius
	shape.height = data.body_height
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = half_h
	add_child(collider)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.body_color
	mat.roughness = 0.8
	var capsule := CapsuleMesh.new()
	capsule.radius = data.body_radius
	capsule.height = data.body_height
	capsule.material = mat
	var body := MeshInstance3D.new()
	body.mesh = capsule
	body.position.y = half_h
	add_child(body)

	# Visor azul no lado da frente (-Z), para ver para onde a unidade está virada.
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
