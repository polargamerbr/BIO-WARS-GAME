extends Node3D
## Projétil de fuzil. Voa até o alvo e aplica o dano ao chegar. Se o alvo morrer antes,
## o projétil some sem efeito. Desenha o próprio traço luminoso e o clarão do impacto.
## Fica no mapa (e não dentro do atirador), para continuar o voo se o atirador cair.

const HIT_DISTANCE := 0.3  ## Metros do centro do alvo em que conta como acerto.
const MAX_LIFETIME := 3.0  ## Segundos. Segurança contra projéteis perdidos.
const TRACER_LENGTH := 0.9

var _target: Unit
var _attacker: Unit
var _damage := 0.0
var _speed := 40.0
var _age := 0.0
var _color := Color.WHITE


## Deve ser chamada antes de add_child.
func setup(attacker: Unit, target: Unit, damage: float, speed: float, from: Vector3, color: Color) -> void:
	_attacker = attacker
	_target = target
	_damage = damage
	_speed = speed
	_color = color
	position = from


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = _color
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, 0.06, TRACER_LENGTH)
	mesh.material = mat
	var tracer := MeshInstance3D.new()
	tracer.mesh = mesh
	tracer.position.z = TRACER_LENGTH * 0.5  # O traço fica atrás da ponta.
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tracer)


func _physics_process(delta: float) -> void:
	_age += delta
	if not is_instance_valid(_target) or not _target.is_alive() or _age > MAX_LIFETIME:
		queue_free()
		return
	var aim := _target.get_center()
	var to_aim := aim - global_position
	var step := _speed * delta
	if to_aim.length() <= maxf(step, HIT_DISTANCE):
		_hit(aim)
		return
	var direction := to_aim.normalized()
	global_position += direction * step
	if absf(direction.y) < 0.99:
		look_at(global_position + direction, Vector3.UP)


func _hit(at: Vector3) -> void:
	var shooter: Unit = _attacker if is_instance_valid(_attacker) else null
	_target.take_damage(_damage, shooter)
	_spawn_impact(at)
	queue_free()


func _spawn_impact(at: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = _color
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	mesh.material = mat
	var flash := MeshInstance3D.new()
	flash.mesh = mesh
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(flash)
	flash.global_position = at
	var tween := flash.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)
