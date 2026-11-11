extends Node3D
## Efeito visual provisório de ataque: um traço curto do atacante ao alvo e um clarão no impacto.
## Escuta o sinal attack_performed das unidades. Não decide nada sobre o combate.

const DURATION := 0.15
const COLOR_PLAYER := Color(0.8, 0.92, 1.0, 0.9)
const COLOR_ENEMY := Color(0.85, 0.9, 0.3, 0.9)


func watch(unit: Unit) -> void:
	unit.attack_performed.connect(_on_attack_performed)
	unit.ability_used.connect(_on_ability_used)


## Anel que se expande até o raio da habilidade (ou em volta da unidade, se for só nela).
func _on_ability_used(unit: Unit, ability: AbilityData) -> void:
	var color := Color(0.3, 0.85, 1.0, 0.8) if ability.effect == AbilityData.Effect.SPEED else Color(1.0, 0.45, 0.3, 0.8)
	var final_radius := ability.radius if ability.radius > 0.0 else unit.data.body_radius + 0.8
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	var ring := _spawn_fading(torus, color, 0.6)
	ring.global_position = unit.global_position + Vector3.UP * 0.1
	ring.scale = Vector3(0.3, 0.2, 0.3)
	var grow := ring.create_tween()
	grow.tween_property(ring, "scale", Vector3(final_radius, 0.2, final_radius), 0.6)


func _on_attack_performed(attacker: Unit, target: Unit) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	var color := COLOR_PLAYER if attacker.team == Unit.Team.PLAYER else COLOR_ENEMY
	var from := attacker.get_center()
	var to := target.get_center()
	_spawn_streak(from, to, color)
	_spawn_flash(to, color)


func _spawn_streak(from: Vector3, to: Vector3, color: Color) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, length)
	var piece := _spawn_fading(mesh, color)
	piece.global_position = (from + to) * 0.5
	var up := Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT
	piece.look_at(to, up)


func _spawn_flash(at: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	var piece := _spawn_fading(mesh, color)
	piece.global_position = at


func _spawn_fading(mesh: PrimitiveMesh, color: Color, duration: float = DURATION) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mesh.material = mat
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(piece)
	var tween := piece.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	tween.tween_callback(piece.queue_free)
	return piece
