extends Node
## Mantém a arma (modelo separado) na mão do modelo 3D, a cada quadro.
##   Com as duas mãos na arma (ex.: animação de tiro), o cano aponta da mão que segura o
##   punho para a mão de apoio, então a arma acompanha a mira da animação.
##   Senão, a arma fica na mão principal apontada para a frente e para baixo (pronta).
## A arma é só visual: não interfere no combate.

const LOW_READY_DEGREES := 35.0  ## Inclinação para baixo quando só uma mão segura a arma.
const TWO_HANDS_MIN := 0.15  ## Metros: abaixo disso as mãos estão juntas demais para mirar.
const TWO_HANDS_MAX := 0.75  ## Metros: acima disso a mão de apoio não está na arma.

var _unit: Unit
var _skeleton: Skeleton3D
var _weapon: Node3D
var _hand := -1
var _support := -1
var _scale := 1.0


func setup(unit: Unit, model: Node3D) -> void:
	_unit = unit
	var data := unit.data
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	_skeleton = skeletons[0]
	_hand = _skeleton.find_bone(data.weapon_hand_bone)
	_support = _skeleton.find_bone(data.weapon_support_bone)
	if _hand < 0:
		return
	_weapon = data.weapon_scene.instantiate() as Node3D
	_weapon.name = "Weapon"
	# Fica fora do pivô animado: a posição é calculada inteira aqui, no espaço do mundo.
	unit.add_child(_weapon)
	_weapon.top_level = true
	_scale = data.weapon_length / maxf(_model_length(_weapon), 0.01)
	unit.died.connect(func(_u: Unit): _weapon.visible = false)


func _process(_delta: float) -> void:
	if _weapon == null or not _weapon.visible:
		return
	var hand := _bone_position(_hand)
	var forward := -_unit.global_transform.basis.z
	var direction := forward.rotated(_unit.global_transform.basis.x, -deg_to_rad(LOW_READY_DEGREES))
	if _support >= 0:
		var to_support := _bone_position(_support) - hand
		var reach := to_support.length()
		if reach > TWO_HANDS_MIN and reach < TWO_HANDS_MAX and to_support.dot(forward) > 0.0:
			direction = to_support.normalized()
	var up := Vector3.UP
	if absf(direction.dot(up)) > 0.95:
		up = forward
	# Eixos da arma: +X é o cano, +Y é para cima.
	var x_axis := direction.normalized()
	var z_axis := x_axis.cross(up).normalized()
	var y_axis := z_axis.cross(x_axis).normalized()
	var basis := Basis(x_axis, y_axis, z_axis).scaled(Vector3.ONE * _scale)
	var grip: Vector3 = _unit.data.weapon_grip
	_weapon.global_transform = Transform3D(basis, hand - basis * grip)


func _bone_position(bone: int) -> Vector3:
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(bone).origin


## Comprimento da arma ao longo de X, no espaço do próprio modelo.
static func _model_length(model: Node3D) -> float:
	var box := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != model:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b: AABB = xf * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.size.x
