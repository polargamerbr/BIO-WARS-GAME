# BIOWAR: FRONTLINE

RTS militar tático ambientado dentro do corpo humano. Status: pré-produção.

Documentação em `docs/`: `GDD.md`, `TECHNICAL_PLAN.md`, `DECISIONS.md`, `CHANGELOG.md`.

## Como abrir

1. Instale o Godot 4.x, versão **padrão** (não a ".NET", porque o projeto usa GDScript): https://godotengine.org/download
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para rodar.

## O que a versão atual faz (Etapa F)

A MISSÃO 001 — PRIMEIRO CONTATO, jogável do começo ao fim. O jogo abre na ordem de missão (Enter para começar).

- 3 NEUTROPHIL (fuzil) e 1 MACROPHAGE (corpo a corpo, com escudo de bioenergia) partem da área verde. Os corpos são provisórios.
- Dois focos de invasão com bactérias humanoides: BRAVO (2 comuns) e ALFA (3 comuns e 1 encapsulada, cuja cápsula translúcida bloqueia boa parte do dano).
- Vitória: controlar os dois focos (eliminar os invasores e ocupar a área).
- Derrota: o dano tecidual, que cresce enquanto há invasores vivos, chega a 100%, ou todas as unidades caem.
- Objetivo secundário: terminar com dano tecidual abaixo de 35%.
- Animações provisórias e efeitos sonoros (tecla M liga e desliga o som).

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
- M: ligar e desligar o som
- F11: tela cheia
- Na tela final: R reinicia, Esc sai
- Esc: sair

## Como gerar o executável do Windows

1. No editor do Godot 4.7.2: menu **Editor > Gerenciar Modelos de Exportação... > Baixar e Instalar** (download de cerca de 1 GB, uma vez só).
2. Menu **Projeto > Exportar...**, escolha o preset **Windows Desktop** e clique em **Exportar Projeto**. Ou, pela linha de comando, a partir desta pasta:

   ```
   Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" build/windows/BIOWAR_FRONTLINE.exe
   ```

O resultado é `build/windows/BIOWAR_FRONTLINE.exe`, com os dados do jogo embutidos (a pasta `build/` não vai para o Git).

## Modelos 3D pelo Tripo (ponte direta)

O plugin **Tripo Bridge** (`addons/tripo_bridge/`) já vem ativado. Ele recebe no editor do Godot os modelos gerados no Tripo Studio, sem baixar e importar à mão.

1. Abra o projeto no **editor** do Godot. O plugin mostra o painel "Tripo Bridge" e fica esperando conexão em `ws://127.0.0.1:60650` (só no seu computador).
2. No **Tripo Studio** (site), gere o modelo a partir da imagem de referência da unidade (`assets/.../reference/`) e use a opção de enviar para o Godot (DCC Bridge). Guia oficial: https://www.tripo3d.ai/pt/blog/tripo-dcc-bridge-guide-hub
3. O modelo chega em `res://TripoModels/`. Depois é levado para a pasta da unidade (por exemplo, `assets/units/neutrophil/`) e ligado ao jogo no lugar da cápsula provisória.

O plugin só funciona no editor e fica fora do executável.

## Arte

Prompts para gerar as referências de arte no Gemini antes de gastar créditos de 3D: `docs/ART_PROMPTS.md`.

## Sons

Os efeitos sonoros são gerados por `tools/generate_sfx.py` (só precisa do Python): `python tools/generate_sfx.py`.
