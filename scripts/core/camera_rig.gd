extends Node3D
## Câmera RTS isométrica: projeção ortogonal, 45 graus de giro e inclinação fixa.
## WASD ou setas movem o foco no plano XZ. A roda do mouse aproxima e afasta.

@export var pan_speed: float = 1.1  ## Multiplicado pelo tamanho do zoom atual.
@export var zoom_step: float = 2.0
@export var zoom_size_min: float = 8.0
@export var zoom_size_max: float = 40.0
@export var pitch_degrees: float = 50.0
@export var map_half_extent: float = 40.0

var _camera: Camera3D
var _target_size: float = 20.0


func _ready() -> void:
	rotation_degrees = Vector3(0.0, 45.0, 0.0)

	var pitch := deg_to_rad(pitch_degrees)
	var distance := 60.0
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = _target_size
	_camera.near = 0.1
	_camera.far = 200.0
	_camera.rotation = Vector3(-pitch, 0.0, 0.0)
	_camera.position = Vector3(0.0, sin(pitch) * distance, cos(pitch) * distance)
	add_child(_camera)
	_camera.make_current()


func _process(delta: float) -> void:
	_pan(delta)
	_camera.size = lerpf(_camera.size, _target_size, clampf(delta * 10.0, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	if mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
		_target_size = clampf(_target_size - zoom_step, zoom_size_min, zoom_size_max)
	elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_target_size = clampf(_target_size + zoom_step, zoom_size_min, zoom_size_max)


func _pan(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir == Vector2.ZERO:
		return

	dir = dir.normalized()
	var move := basis * Vector3(dir.x, 0.0, dir.y)
	position += move * pan_speed * _camera.size * delta
	position.x = clampf(position.x, -map_half_extent, map_half_extent)
	position.z = clampf(position.z, -map_half_extent, map_half_extent)
