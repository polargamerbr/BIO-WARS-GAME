# CHANGELOG

## [0.0.2] Etapa B, controle (2026-11-10)

### Adicionado
- `UnitData` (`scripts/units/unit_data.gd`): definição de unidade como Resource. Os valores ficam em `data/units/neutrophil.tres` e `data/units/macrophage.tres`.
- `Unit` (`scripts/units/unit.gd`): unidade base com corpo provisório (cápsula com visor azul), anel de seleção, vida e movimento por `NavigationAgent3D` com desvio entre unidades.
- `SelectionController` (`scripts/core/selection_controller.gd`): clique seleciona, arrastar seleciona em retângulo, Shift soma ou tira, clique no vazio limpa. Clique direito move a seleção. Mostra um marcador no destino e um painel simples com a seleção.
- Colisão no chão e nos obstáculos (camada 1 = mundo, camada 2 = unidades) e malha de navegação gerada na abertura do jogo.
- 3 NEUTROPHIL e 1 MACROPHAGE na área inicial.

### Alterado
- `main.gd`: chão e obstáculos agora são corpos sólidos. Textos do HUD atualizados para a Etapa B.

### Testado
- Teste automatizado temporário (fora do repositório) com a janela aberta: clique, arrastar, Shift, clique no vazio, ordem de movimento contornando um obstáculo, parada de todas as unidades, nenhuma unidade dentro de obstáculo, ordem sem seleção sem efeito, clique no topo de um obstáculo levando a unidade até a face dele. Todos passaram.
- Jogo abre em modo headless por 180 quadros sem erros.

### Não testado
- Mouse e teclado reais (os eventos foram simulados).
- Muitas unidades ao mesmo tempo. Só foram testadas 4.

### Problemas conhecidos
- O destino de grupo usa uma grade provisória. As formações de verdade (Linha, Compacta, Defensiva, Dispersa) são da Etapa D.
- Clicar fora do mapa não faz nada.
- Unidades sobrepostas na tela: o clique escolhe a mais próxima da câmera.
- Grupos de controle (teclas numéricas) ficam para a Etapa D.

## [0.0.1] Etapa A, fundação (2026-11-10)

### Adicionado
- Estrutura de pastas conforme o plano técnico.
- `project.godot` (Godot 4.x, 1920x1080, stretch `canvas_items`).
- Cena `Main` com campo de batalha de teste em 3D: chão, grade, 5 obstáculos, área inicial (verde) e área de invasão (amarela).
- `camera_rig.gd`: câmera isométrica ortogonal com movimento por WASD/setas e zoom suave pela roda do mouse.
- HUD mínimo com FPS e atalhos (F11 tela cheia, Esc sair).
- Documentação inicial em `docs/` e arte de referência do Neutrophil.

### Testado
- Importação e execução da cena principal em modo headless no Godot 4.7.2 (180 quadros, sem erros de script, saída com código 0).

### Não testado
- O visual e os controles (câmera, zoom, F11) ainda precisam ser conferidos por uma pessoa com a janela aberta.

### Problemas conhecidos
- Nenhum conhecido ainda.
