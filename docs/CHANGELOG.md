# CHANGELOG

## [0.0.5] Etapa E, missão (2026-11-11)

### Adicionado
- Sistema de missões (`scripts/missions/`): `MissionData`, `FocusData` e `SpawnData` como Resources, e o `MissionController`, que cria as unidades, acompanha os objetivos, soma o dano tecidual e decide vitória ou derrota.
- `data/missions/mission_001_first_contact.tres`, a MISSÃO 001 — PRIMEIRO CONTATO:
  - 3 NEUTROPHIL e 1 MACROPHAGE.
  - Foco BRAVO com 2 bactérias comuns.
  - Foco ALFA com 3 bactérias comuns e 1 bactéria encapsulada.
- Objetivos principais: controlar cada foco, isto é, eliminar os invasores que nasceram nele e ter uma unidade dentro da área. A vitória vem quando todos os focos estão controlados.
- Objetivo secundário: terminar com o dano tecidual abaixo de 50%.
- Derrota: o dano tecidual chega a 100% (cada invasor vivo soma uma taxa por segundo), ou todas as unidades do jogador caem.
- BACTÉRIA ENCAPSULADA (`data/enemies/bacteria_encapsulated.tres`): a cápsula bloqueia 60% do dano de atacantes comuns, mas atacantes ativados pela SINALIZAÇÃO POR CITOCINAS ignoram a cápsula.
- Novos campos no `UnitData`: `capsule_protection` e `tissue_damage_rate`.
- Interface da missão (`scripts/interface/mission_hud.gd`):
  - Barra de dano tecidual com a taxa atual e o tempo.
  - Painel de objetivos, com o número de invasores de cada foco.
  - Avisos ("FOCO BRAVO CONTROLADO", "ALERTA: DANO TECIDUAL ACIMA DE 50%").
  - Ordem de missão (briefing) com o jogo pausado.
  - Tela final MISSÃO CUMPRIDA ou FRACASSADA, com tempo, dano tecidual, invasores eliminados, unidades perdidas e objetivos, e botões REINICIAR (R) e SAIR (Esc).
- Marcação dos focos no chão (`mission_zones.gd`): disco, borda e nome. Ficam amarelos enquanto ativos e verdes quando controlados.

### Alterado
- O `main.gd` não tem mais unidades nem zonas fixas: tudo vem do arquivo da missão. A função `spawn_unit` passou a ser pública para a missão usar.
- O jogo abre pausado no briefing. Enter, Espaço ou o botão INICIAR OPERAÇÃO começam a missão.

### Testado
- Teste automatizado temporário com a janela aberta, com uma partida completa jogada pelos controles:
  - Seleção dos 4, ataque ao foco BRAVO, controle do foco e aviso.
  - Aproximação do foco ALFA, citocinas (E) e ataque à encapsulada.
  - Vitória em cerca de 23 s, com 22% de dano tecidual, 1 unidade perdida e o secundário cumprido.
  - Tela final pausada com as estatísticas.
- Também: R reinicia no briefing. A cápsula bloqueia 60% contra atacante comum e nada contra atacante ativado. Há derrota por perda das unidades e derrota por 100% de dano tecidual. O aviso dos 50% aparece, o dano tecidual não cresce durante o briefing e os botões INICIAR e REINICIAR funcionam.
- Os testes das Etapas B, C e D continuam passando. Eles agora iniciam a missão e desligam as regras dela, porque testam os sistemas isolados.

### Não testado
- Mouse e teclado reais (os eventos foram simulados).
- Exportação como executável independente do Windows (critério 8 do protótipo).

### Problemas conhecidos
- Só existe o campo de teste: o `map_id` da missão ainda não escolhe mapa.
- Os tipos de objetivo são fixos (controlar focos e limite de dano tecidual). Outros tipos exigirão novos campos.
- A animação de morte de quem cai no último instante fica congelada na tela final, porque o jogo pausa.
- Dano tecidual, taxas e cápsula são provisórios e sem balanceamento.

## [0.0.4] Etapa D, estratégia (2026-11-10)

### Adicionado
- Grupos de controle: Ctrl + 1 a 9 cria o grupo, 1 a 9 chama, apertar duas vezes centraliza a câmera. O painel da seleção mostra o número do grupo.
- `FormationManager` (`scripts/formations/`) com quatro formações em `data/formations/*.tres`. F1 a F4 ou os botões do painel trocam a formação e reorganizam a seleção no lugar.
  - LINHA (padrão): frente larga, de lado para o destino.
  - COMPACTA: bloco fechado. O grupo anda na velocidade da unidade mais lenta.
  - DEFENSIVA: círculo voltado para fora. Mantém posição sem perseguir, recebe 25% menos dano parada e anda junto.
  - DISPERSA: espaçamento largo.
- Cada unidade recebe uma posição da formação (o par unidade-posição mais próximo primeiro, para não se cruzarem) e chega virada para a frente da formação.
- Habilidades (`AbilityData`, `data/abilities/*.tres`), ligadas às unidades pelo `UnitData`:
  - Q, MOBILIZAÇÃO RÁPIDA (NEUTROPHIL): +60% de velocidade por 5 s, recarga de 18 s.
  - E, SINALIZAÇÃO POR CITOCINAS (MACROPHAGE): aliados a até 8 m causam +30% de dano por 8 s, recarga de 25 s.
- Painel de comandos no canto inferior direito, com os botões de formação e de habilidades (com tempo de recarga).
- Indicadores de efeito ativo ao lado da barra de vida (ciano: velocidade, laranja: dano) e anel visual ao usar habilidade.
- Novo estado DEFENDING (manter posição) na máquina de estados.
- Retorno à formação: depois de um combate que a unidade começou sozinha, ela volta para a sua posição. Depois de uma ordem de ataque do jogador, ela fica onde terminou.
- O alvo automático é abandonado pela distância da posição de formação, e não da unidade. Isso evita que o grupo seja arrastado para longe, e vale também para as bactérias, que voltam para a área delas.

### Alterado
- A ordem de movimento usa a formação atual no lugar da grade provisória da Etapa B.
- A chegada ao destino ficou mais precisa (0,35 m), para as formações saírem alinhadas.
- O texto de ajuda do HUD foi atualizado.

### Testado
- Teste automatizado temporário com a janela aberta:
  - Grupos de controle: criar, chamar e centralizar a câmera.
  - LINHA: mesma profundidade, lado a lado e viradas para o destino.
  - COMPACTA: ninguém passa de 3,5 m/s e o bloco fecha em raio de 1,1 m.
  - DEFENSIVA: círculo, estado DEFENDING, viradas para fora e 25% menos dano. Não persegue inimigo fora do alcance e mata atacantes sem sair do lugar.
  - LINHA: persegue um inimigo detectado e volta para a posição.
  - Habilidades por tecla e por clique no botão, recarga, botão desabilitado e efeitos que expiram.
  - DISPERSA: folga mínima de 3,2 m entre corpos.
  - Clicar no painel não altera a seleção.
- Os testes das Etapas B e C continuam passando. O critério de "perto do alvo" da Etapa B foi ampliado para a largura da LINHA. O jogo abre em modo headless sem erros.

### Não testado
- Mouse e teclado reais (os eventos foram simulados).
- Grupos com mais de 4 unidades e formações com várias fileiras.

### Problemas conhecidos
- A formação é uma escolha global: vale para a próxima ordem de qualquer seleção.
- Posições de formação que caem dentro de obstáculos são empurradas para fora e podem ficar próximas umas das outras.
- A DISPERSA ainda não tem vantagem em combate. Isso depende de ataques em área, que não existem.
- Valores de formação e habilidade são provisórios e sem balanceamento.

## [0.0.3] Etapa C, combate (2026-11-10)

### Adicionado
- Atributos de combate no `UnitData`: dano, tempo entre ataques, alcance de ataque (entre as bordas dos corpos) e alcance de detecção. Forma do corpo: soldado em pé ou bastonete deitado.
- Inimigo `data/enemies/bacteria_common.tres` (BACTÉRIA COMUM). Cinco deles na área de invasão.
- Máquina de estados na `Unit`, igual para aliados e inimigos: IDLE (procura alvo a cada 0,25 s), MOVING (ordem de movimento, ignora inimigos), ATTACKING (persegue pela navegação e ataca no alcance e com linha de visão) e DEAD.
- Linha de visão: obstáculos bloqueiam a detecção e o ataque.
- Revide: unidade parada que toma dano ataca quem a atingiu.
- Eliminação: a unidade morta sai do grupo, perde colisão, encolhe e é removida da cena.
- Clique direito em um inimigo dá ordem de ataque (marcador amarelo). Inimigos não podem ser selecionados.
- `scripts/interface/health_bars.gd`: barra de vida sobre cada unidade (verde para aliados, vermelha com pouca vida, amarela para inimigos).
- `scripts/combat/combat_fx.gd`: traço e clarão provisórios a cada ataque.

### Alterado
- O painel da seleção se atualiza durante o combate e tira unidades mortas.

### Testado
- Teste automatizado temporário com a janela aberta. Unidades distantes ficam paradas. A linha de visão é bloqueada pelo obstáculo e fica livre em campo aberto. Clicar ou arrastar sobre inimigos não os seleciona. A ordem de ataque coloca os 4 aliados em ATTACKING. Os 5 inimigos são eliminados em cerca de 17 s (1 NEUTROPHIL morreu e as bactérias revidaram). Ninguém entrou em obstáculo, os aliados voltaram a IDLE, os mortos saíram da cena e da seleção.
- O teste da Etapa B continua passando. O jogo abre em modo headless por 300 quadros sem erros.

### Não testado
- Mouse e teclado reais (os eventos foram simulados).
- Desempenho com muitas unidades. A busca de alvos compara todas as unidades entre si.

### Problemas conhecidos
- Valores de vida, dano e alcance são provisórios e sem balanceamento.
- Ainda falta a bactéria com característica especial do protótipo.
- Os inimigos não patrulham nem se reproduzem. A IA é só detectar, perseguir e atacar.
- Ataque é instantâneo, sem projétil.
- A bactéria (verde-amarelada) se confunde com a área de invasão amarela.

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
