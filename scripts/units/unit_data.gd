class_name UnitData
extends Resource
## Definição de uma unidade (aliada ou inimiga), independente da missão em que aparece.
## Todos os atributos vêm de arquivos .tres em data/units/ e data/enemies/. Nada de valor fixo no código.
## Os valores atuais são provisórios (ver DECISIONS.md) e não valem como regra de jogo.

enum Category { NATURAL_DEFENSE, ADAPTIVE_DEFENSE, SPECIALIZED_DEFENSE, BACTERIUM, VIRUS, FUNGUS }
## UPRIGHT: soldado em pé. ROD: bastonete deitado (bacilo). CREATURE: humanoide curvado (invasor).
enum BodyShape { UPRIGHT, ROD, CREATURE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var category: Category = Category.NATURAL_DEFENSE
@export var max_health: float = 100.0
@export var move_speed: float = 5.0  ## Metros por segundo.

@export_group("Combate")
@export var damage: float = 10.0  ## Dano por ataque.
@export var attack_cooldown: float = 1.0  ## Segundos entre ataques.
@export var attack_range: float = 1.5  ## Metros entre as bordas dos dois corpos.
@export var detection_range: float = 8.0  ## Metros. Até onde a unidade parada percebe inimigos.
## Metros por segundo do projétil. 0 = ataque de contato (dano na hora, sem projétil).
@export var projectile_speed: float = 0.0

@export_group("Escudo de bioenergia")
## Pontos de escudo que absorvem dano antes da vida (0 = sem escudo).
@export var shield_max: float = 0.0
## Segundos sem tomar dano até o escudo começar a recarregar.
@export var shield_regen_delay: float = 4.0
## Pontos de escudo recuperados por segundo durante a recarga.
@export var shield_regen_rate: float = 30.0

@export_group("Biologia")
## Fração do dano bloqueada por uma cápsula (0 = sem cápsula). A cápsula dificulta a fagocitose;
## atacantes ativados (efeito de dano, como o das citocinas) ignoram a proteção.
@export_range(0.0, 1.0) var capsule_protection: float = 0.0
## Pontos percentuais de dano tecidual por segundo enquanto o invasor está vivo.
@export var tissue_damage_rate: float = 0.0
## Cor da cápsula visível em volta do corpo (só aparece se capsule_protection > 0).
@export var capsule_color: Color = Color(0.9, 0.86, 0.68, 0.35)

@export_group("Habilidades")
@export var abilities: Array[AbilityData] = []

@export_group("Corpo provisório")
@export var body_shape: BodyShape = BodyShape.UPRIGHT
@export var body_radius: float = 0.5  ## Metros. Também é o raio do agente de navegação.
@export var body_height: float = 1.8  ## Metros. No bastonete, é o comprimento.
@export var body_color: Color = Color(0.5, 0.5, 0.5)


func has_shield() -> bool:
	return shield_max > 0.0


func is_ranged() -> bool:
	return projectile_speed > 0.0


## Altura do centro do corpo acima do chão.
func center_height() -> float:
	return body_radius if body_shape == BodyShape.ROD else body_height * 0.5


## Altura do topo do corpo acima do chão.
func top_height() -> float:
	return body_radius * 2.0 if body_shape == BodyShape.ROD else body_height
