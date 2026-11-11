class_name FormationManager
extends Node
## Distribui as unidades em posições relativas ao ponto de destino (plano técnico 3.4).
## Cada formação gera uma posição por unidade, respeitando a quantidade e o tamanho delas,
## e passa para as unidades as consequências da formação (manter posição, andar junto, dano).

signal formation_changed(formation: FormationData)

const FORMATION_PATHS := [
	"res://data/formations/line.tres",
	"res://data/formations/compact.tres",
	"res://data/formations/defensive.tres",
	"res://data/formations/spread.tres",
]
const MAX_ROW := 8  ## Unidades por fileira na formação em linha.
const DEFAULT_FACING := Vector3(0.7071, 0.0, -0.7071)  ## Rumo à área de invasão.

var formations: Array[FormationData] = []
var current: FormationData

var _last_facing := DEFAULT_FACING


func _ready() -> void:
	for path in FORMATION_PATHS:
		formations.append(load(path) as FormationData)
	current = formations[0]


func set_current(formation: FormationData) -> void:
	if formation == current:
		return
	current = formation
	formation_changed.emit(formation)


func find_by_hotkey(key: Key) -> FormationData:
	for formation in formations:
		if formation.hotkey == key:
			return formation
	return null


## Manda o grupo para o ponto, de frente para a direção do deslocamento.
func order_move(units: Array[Unit], point: Vector3) -> void:
	if units.is_empty():
		return
	var facing := point - centroid(units)
	facing.y = 0.0
	if facing.length() > 0.5:
		_last_facing = facing.normalized()
	_apply(units, point, _last_facing)


## Reorganiza o grupo no lugar onde ele está, na formação atual.
func reform(units: Array[Unit]) -> void:
	if units.is_empty():
		return
	_apply(units, centroid(units), _last_facing)


static func centroid(units: Array[Unit]) -> Vector3:
	var sum := Vector3.ZERO
	for unit in units:
		sum += unit.global_position
	return sum / units.size()


## Posições da formação em volta de center, com a frente apontando para facing.
static func compute_slots(formation: FormationData, units: Array[Unit], center: Vector3, facing: Vector3) -> Array[Vector3]:
	var count := units.size()
	var widest := 0.0
	for unit in units:
		widest = maxf(widest, unit.data.body_radius * 2.0)
	var step := widest + formation.gap
	var right := facing.cross(Vector3.UP).normalized()
	var slots: Array[Vector3] = []

	match formation.layout:
		FormationData.Layout.ROW:
			var cols := mini(count, MAX_ROW)
			for i in count:
				var col := i % cols
				var row := floori(float(i) / cols)
				var side := (col - (cols - 1) * 0.5) * step
				slots.append(center + right * side - facing * (row * step))
		FormationData.Layout.GRID:
			var cols := ceili(sqrt(float(count)))
			var rows := ceili(float(count) / cols)
			for i in count:
				var col := i % cols
				var row := floori(float(i) / cols)
				var side := (col - (cols - 1) * 0.5) * step
				var depth := (row - (rows - 1) * 0.5) * step
				slots.append(center + right * side - facing * depth)
		FormationData.Layout.RING:
			if count == 1:
				slots.append(center)
			else:
				# Raio em que cabem todas as unidades lado a lado na circunferência.
				var radius := maxf(step * count / TAU, step * 0.75)
				for i in count:
					var angle := TAU * i / count
					slots.append(center + (facing * cos(angle) + right * sin(angle)) * radius)
	return slots


func _apply(units: Array[Unit], center: Vector3, facing: Vector3) -> void:
	var slots := compute_slots(current, units, center, facing)
	var assignment := _assign(units, slots)
	var speed_cap := INF
	if current.move_together:
		for unit in units:
			speed_cap = minf(speed_cap, unit.data.move_speed)
	for i in units.size():
		var unit := units[i]
		var slot: Vector3 = slots[assignment[i]]
		var face := facing
		if current.layout == FormationData.Layout.RING:
			var outward := slot - center
			outward.y = 0.0
			if outward.length() > 0.1:
				face = outward.normalized()
		unit.formation = current
		unit.move_to(slot, face, speed_cap)


## Liga cada unidade a uma posição, sempre o par mais próximo primeiro, para evitar que as
## unidades se cruzem no caminho. Retorna o índice da posição de cada unidade.
static func _assign(units: Array[Unit], slots: Array[Vector3]) -> Array[int]:
	var result: Array[int] = []
	result.resize(units.size())
	var free_units := range(units.size())
	var free_slots := range(slots.size())
	while not free_units.is_empty():
		var best_u := -1
		var best_s := -1
		var best_d := INF
		for u in free_units:
			for s in free_slots:
				var d := units[u].global_position.distance_squared_to(slots[s])
				if d < best_d:
					best_d = d
					best_u = u
					best_s = s
		result[best_u] = best_s
		free_units.erase(best_u)
		free_slots.erase(best_s)
	return result
