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

## Em aberto

- **Recurso do jogador:** o GDD fala em "recursos iniciais" sem definir o que são. Ideia em avaliação: sinais inflamatórios para chamar reforços.
- **Alcance dos soldados:** o GDD usa fuzil, o que conflita com fagocitose (combate próximo). A decidir.
- **Formato de dados:** o plano cita Resources e JSON. A decidir se fica só Resources (`.tres`).
- **Estatísticas da prancha do Neutrophil** (custo, tempo de produção, cura): são placeholder, não valem como regra.
