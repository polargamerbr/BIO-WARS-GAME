# CHANGELOG

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
