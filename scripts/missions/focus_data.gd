class_name FocusData
extends Resource
## Foco de invasão: uma área do mapa com os invasores que nascem nela.
## O foco fica controlado quando todos os seus invasores foram eliminados e há
## pelo menos uma unidade do jogador dentro da área.

@export var display_name: String = ""
@export var center: Vector3 = Vector3.ZERO
@export var radius: float = 8.0  ## Metros.
@export var enemies: Array[SpawnData] = []
