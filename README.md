# BIOWAR: FRONTLINE

RTS militar tático ambientado dentro do corpo humano. Status: pré-produção.

Documentação em `docs/`: `GDD.md`, `TECHNICAL_PLAN.md`, `DECISIONS.md`, `CHANGELOG.md`.

## Como abrir

1. Instale o Godot 4.x, versão **padrão** (não a ".NET", porque o projeto usa GDScript): https://godotengine.org/download
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para rodar.

## O que a versão atual faz (Etapa E)

A MISSÃO 001 — PRIMEIRO CONTATO, jogável do começo ao fim. O jogo abre na ordem de missão (Enter para começar).

- 3 NEUTROPHIL e 1 MACROPHAGE (corpos provisórios) partem da área verde.
- Dois focos de invasão: BRAVO (2 bactérias comuns) e ALFA (3 comuns e 1 encapsulada, cuja cápsula bloqueia boa parte do dano).
- Vitória: controlar os dois focos (eliminar os invasores e ocupar a área).
- Derrota: o dano tecidual, que cresce enquanto há invasores vivos, chega a 100%, ou todas as unidades caem.
- Objetivo secundário: terminar com dano tecidual abaixo de 50%.

Controles:

- Clique esquerdo: selecionar uma unidade (no vazio, limpa a seleção)
- Arrastar com o esquerdo: selecionar várias em retângulo
- Shift: somar à seleção
- Clique direito no chão: mover as unidades selecionadas (elas contornam os obstáculos)
- Clique direito em um inimigo: atacar
- Ctrl + 1 a 9: criar grupo de controle. 1 a 9: chamar o grupo (duas vezes: centraliza a câmera)
- F1 a F4: formação LINHA, COMPACTA, DEFENSIVA ou DISPERSA (também pelos botões no canto inferior direito)
- Q: MOBILIZAÇÃO RÁPIDA (NEUTROPHIL). E: SINALIZAÇÃO POR CITOCINAS (MACROPHAGE), que também anula a cápsula
- WASD ou setas: mover a câmera
- Roda do mouse: zoom
- F11: tela cheia
- Na tela final: R reinicia, Esc sai
- Esc: sair
