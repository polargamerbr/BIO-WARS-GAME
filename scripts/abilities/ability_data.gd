class_name AbilityData
extends Resource
## Definição de uma habilidade. Os valores vêm de arquivos .tres em data/abilities/.
## Uma habilidade aplica um efeito temporário (multiplicador) na própria unidade ou nos aliados em volta.

enum Effect { SPEED, DAMAGE }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var hotkey: Key = KEY_Q
@export var cooldown: float = 20.0  ## Segundos até poder usar de novo.
@export var duration: float = 5.0  ## Segundos de efeito.
@export var radius: float = 0.0  ## Metros. 0 = só a própria unidade.
@export var effect: Effect = Effect.SPEED
@export var magnitude: float = 1.5  ## Multiplicador aplicado ao atributo do efeito.
