class_name MissionData
extends Resource
## Configuração de uma missão (GDD 8, plano técnico 3.9). Cada missão é um arquivo .tres em
## data/missions/, para criar missões novas sem mexer nos sistemas centrais.
##   Objetivos principais: controlar todos os focos de invasão (vitória).
##   Objetivo secundário: terminar com o dano tecidual abaixo de secondary_tissue_limit.
##   Derrota: dano tecidual chega a tissue_damage_limit, ou todas as unidades do jogador caem.
## O dano tecidual cresce a cada segundo pela soma do tissue_damage_rate dos invasores vivos.

@export var id: StringName = &""
@export var display_name: String = ""
@export var campaign: String = ""
@export_range(1, 5) var difficulty: int = 1
@export_multiline var briefing: String = ""
@export var map_id: StringName = &"test_field"  ## Por enquanto só existe o campo de teste.

@export_group("Jogador")
@export var start_zone_center: Vector3 = Vector3.ZERO
@export var start_zone_radius: float = 7.0
@export var player_units: Array[SpawnData] = []

@export_group("Invasão")
@export var foci: Array[FocusData] = []

@export_group("Condições")
@export var tissue_damage_limit: float = 100.0  ## Pontos percentuais. Chegar aqui é derrota.
@export var secondary_tissue_limit: float = 50.0  ## Objetivo secundário: não passar daqui.
