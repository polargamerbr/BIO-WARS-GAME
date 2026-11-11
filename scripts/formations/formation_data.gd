class_name FormationData
extends Resource
## Definição de uma formação: o desenho das posições e as consequências para o grupo.
## Os valores vêm de arquivos .tres em data/formations/.

enum Layout { ROW, GRID, RING }  ## Fileira, bloco em grade, círculo voltado para fora.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var hotkey: Key = KEY_F1
@export var layout: Layout = Layout.ROW
@export var gap: float = 1.0  ## Metros livres entre os corpos.
@export var damage_taken_multiplier: float = 1.0  ## Aplicado enquanto a unidade não está se deslocando.
@export var hold_position: bool = false  ## Não persegue: só ataca o que entra no alcance.
@export var move_together: bool = false  ## O grupo anda na velocidade da unidade mais lenta.
