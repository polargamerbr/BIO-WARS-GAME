class_name UnitData
extends Resource
## Definição de uma unidade, independente da missão em que aparece.
## Todos os atributos vêm de arquivos .tres em data/units/. Nada de valor fixo no código.
## Os valores atuais são provisórios (ver DECISIONS.md) e não valem como regra de jogo.

enum Category { NATURAL_DEFENSE, ADAPTIVE_DEFENSE, SPECIALIZED_DEFENSE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var category: Category = Category.NATURAL_DEFENSE
@export var max_health: float = 100.0
@export var move_speed: float = 5.0  ## Metros por segundo.
@export_group("Corpo provisório")
@export var body_radius: float = 0.5  ## Metros. Também é o raio do agente de navegação.
@export var body_height: float = 1.8  ## Metros.
@export var body_color: Color = Color(0.5, 0.5, 0.5)
