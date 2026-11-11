# DECISIONS

Registro das decisões do projeto. Uma entrada por decisão, com data.

## Adotadas

### D001: 3D com câmera isométrica fixa em vez de 2D (2026-11-10)
- **Decisão:** o jogo usa Godot 3D com câmera ortogonal fixa (giro de 45 graus, inclinação de 50 graus). A lógica de jogo acontece no plano XZ.
- **Motivo:** o pipeline de arte escolhido gera modelos 3D (Meshy), que ganham rig e animações uma única vez e servem para todas as direções de visão. Em 2D isométrico seriam necessários sprites em 8 direções para cada animação.
- **Impacto no plano técnico:** Godot Physics 3D, NavigationServer3D e NavigationAgent3D, arte em GLB.
- **Reversível:** sim, porque ainda não há sistemas construídos sobre ela. Deve ser reavaliada se o teste com 6 unidades na tela ficar ilegível.

### D002: Neutrophil oficial (2026-11-09)
- **Decisão:** o design de referência é o da vista de frente e de costas em `assets/units/neutrophil/reference/`. Capacete cinza com faixa vermelha, visor azul, camuflado areia sobre preto.
- **Emblema:** gota vermelha nos ombros no lugar da cruz vermelha, porque o emblema da Cruz Vermelha é protegido por lei em vários países.
- **Paleta:** grafite e areia para o Neutrophil. O GDD v0.1 previa verde-oliva para infantaria, então o GDD precisa ser atualizado ou o oliva fica para outra classe.

### D003: Navegação só com o chão como superfície andável (2026-11-10)
- **Decisão:** a malha de navegação é gerada de um chão plano, e os obstáculos entram como bloqueios (`add_projected_obstruction` com `carve = false`). Os obstáculos continuam com colisão física própria.
- **Motivo:** gerar a malha a partir dos colisores fazia o topo dos obstáculos virar uma superfície andável inalcançável. Clicar num obstáculo mandava a unidade para essa ilha e ela travava. Com `carve = true` o raio do agente é ignorado e o caminho encosta no obstáculo.
- **Consequência:** o raio da malha é único (0,75 m, o do Macrophage). Mapas com relevo, rampas ou vários andares vão exigir outra abordagem.
- **Desvio de altura:** o bake deixa a malha 0,5 m acima do chão. A região é abaixada por esse desvio, medido na hora, para as distâncias de chegada em 3D funcionarem.

### D004: Atributos de unidade em `UnitData` (.tres) (2026-11-10)
- **Decisão:** vida, velocidade e tamanho do corpo vêm de `data/units/*.tres`. Atributos de combate (alcance, dano, tempo de ataque) entram na Etapa C, quando existirem usuários deles.
- **Valores atuais:** provisórios, como os da prancha do Neutrophil.

### D005: Combate de curto alcance no protótipo (2026-11-10, provisória)
- **Decisão:** NEUTROPHIL e MACROPHAGE atacam a 2 m (entre as bordas dos corpos), a bactéria a 1,5 m. O ataque é instantâneo, sem projétil.
- **Motivo:** o GDD descreve as duas unidades com fagocitose e combate direto. Isso deixa de lado o fuzil da arte de referência até a pendência "Alcance dos soldados" ser decidida.
- **Reversível:** sim. O alcance é só um valor nos arquivos `.tres`. Um ataque à distância de verdade exigiria projéteis, que ainda não existem.

### D006: Uma única classe `Unit` para aliados e inimigos (2026-11-10)
- **Decisão:** aliados e inimigos usam a mesma `Unit`, diferenciados pelo time (`Team`) e pelo `UnitData`. A IA inicial dos inimigos é a mesma máquina de estados dos aliados.
- **Motivo:** o combate fica simétrico e não há código duplicado. Comportamentos próprios de inimigos (patrulha, reprodução, resistência) entram depois, no sistema biológico, sem mudar essa base.

## Em aberto

- **Recurso do jogador:** o GDD fala em "recursos iniciais" sem definir o que são. Ideia em avaliação: sinais inflamatórios para chamar reforços.
- **Alcance dos soldados:** o GDD usa fuzil, o que conflita com fagocitose (combate próximo). A decidir.
- **Formato de dados:** o plano cita Resources e JSON. A decidir se fica só Resources (`.tres`).
- **Estatísticas da prancha do Neutrophil** (custo, tempo de produção, cura): são placeholder, não valem como regra.
