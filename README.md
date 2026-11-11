# BIOWAR: FRONTLINE

RTS militar tático ambientado dentro do corpo humano. Status: pré-produção.

Documentação em `docs/`: `GDD.md`, `TECHNICAL_PLAN.md`, `DECISIONS.md`, `CHANGELOG.md`.

## Como abrir

1. Instale o Godot 4.x, versão **padrão** (não a ".NET", porque o projeto usa GDScript): https://godotengine.org/download
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para rodar.

## O que a versão atual faz (Etapa C)

Um campo de batalha de teste em 3D com câmera isométrica. 3 NEUTROPHIL e 1 MACROPHAGE na área verde enfrentam 5 bactérias na área amarela (corpos provisórios). As unidades detectam inimigos próximos, perseguem, atacam e revidam. Controles:

- Clique esquerdo: selecionar uma unidade (no vazio, limpa a seleção)
- Arrastar com o esquerdo: selecionar várias em retângulo
- Shift: somar à seleção
- Clique direito no chão: mover as unidades selecionadas (elas contornam os obstáculos)
- Clique direito em um inimigo: atacar
- WASD ou setas: mover a câmera
- Roda do mouse: zoom
- F11: tela cheia
- Esc: sair

Ainda não há formações, habilidades, objetivos nem tela de vitória ou derrota.
