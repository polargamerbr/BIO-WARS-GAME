> Atualização v0.2 (2026-11-10): o projeto passa a usar 3D com câmera isométrica fixa (ver docs/DECISIONS.md, D001). Onde este plano diz 2D, leia 3D: Godot Physics 3D, NavigationServer3D e NavigationAgent3D, lógica de jogo no plano XZ, arte em modelos 3D (GLB) com câmera ortogonal. O resto do plano continua valendo.

BIOWAR: FRONTLINE

Plano Técnico de Desenvolvimento — v0.1

1. Stack tecnológica

Componente| Tecnologia
Motor| Godot 4.x
Linguagem| GDScript
Renderização| 2D
Perspectiva| Isométrica
Física| Godot Physics 2D
Navegação| NavigationServer2D / NavigationAgent2D
Dados| Resources e arquivos JSON
Salvamento| Arquivos locais
Controle de versão| Git
Arte| Spritesheets e animações 2D

Não utilizar serviços externos ou banco de dados na primeira versão.

2. Arquitetura do projeto

O projeto deverá ser modular e orientado a dados.

Estrutura inicial:

BIOWAR_FRONTLINE/
│
├── project.godot
│
├── assets/
│   ├── units/
│   │   ├── neutrophil/
│   │   ├── macrophage/
│   │   ├── t_helper/
│   │   ├── cytotoxic_t/
│   │   └── nk_cell/
│   │
│   ├── enemies/
│   │   ├── bacteria/
│   │   ├── viruses/
│   │   └── fungi/
│   │
│   ├── environments/
│   ├── effects/
│   ├── audio/
│   └── interface/
│
├── scenes/
│   ├── main/
│   ├── battlefield/
│   ├── units/
│   ├── enemies/
│   ├── projectiles/
│   └── interface/
│
├── scripts/
│   ├── core/
│   ├── units/
│   ├── combat/
│   ├── ai/
│   ├── movement/
│   ├── formations/
│   ├── missions/
│   ├── biology/
│   ├── progression/
│   └── interface/
│
├── data/
│   ├── units/
│   ├── enemies/
│   ├── missions/
│   ├── abilities/
│   └── campaigns/
│
├── resources/
│   ├── maps/
│   └── configurations/
│
└── docs/
    ├── GDD.md
    ├── TECHNICAL_PLAN.md
    └── CHANGELOG.md

3. Sistemas principais

3.1 Sistema de unidades

Cada unidade deverá ser independente da missão em que aparece.

Criar uma estrutura base de unidade contendo:

- Identificador.
- Nome.
- Categoria.
- Vida.
- Velocidade.
- Alcance.
- Dano.
- Tempo de ataque.
- Resistências.
- Habilidades.
- Comportamento de combate.

Os atributos deverão ser configuráveis por dados, evitando valores espalhados pelo código.

Utilizar Resources personalizados do Godot para armazenar as definições das unidades.

3.2 Sistema de seleção

Responsável por:

- Seleção individual.
- Seleção múltipla.
- Seleção por arraste.
- Grupos de controle.
- Destaque visual das unidades selecionadas.
- Painel de informações.

A seleção não deverá interferir na movimentação ou no combate.

3.3 Sistema de movimentação

Utilizar navegação 2D com suporte a obstáculos.

Funcionalidades:

- Movimentação por clique.
- Cálculo de rotas.
- Desvio de obstáculos.
- Separação entre unidades.
- Movimentação coordenada.
- Preservação das formações.

Importante: não implementar movimentação independente sem considerar colisões e congestionamento de tropas.

3.4 Sistema de formações

Criar um FormationManager responsável por distribuir as unidades em posições relativas ao ponto de destino.

Primeiras formações:

- Linha.
- Compacta.
- Defensiva.
- Dispersa.

Cada formação deverá gerar posições de destino individuais, respeitando a quantidade e o tamanho das unidades.

3.5 Sistema de combate

Criar um sistema de estados:

- IDLE: aguardando ordens.
- MOVING: em deslocamento.
- ATTACKING: combatendo.
- DEFENDING: mantendo posição.
- RETREATING: recuando.
- DISABLED: unidade incapacitada.

O combate deverá verificar alcance, linha de visão, validade do alvo e condições especiais.

As decisões de combate serão separadas da representação visual.

3.6 Inteligência artificial

Implementar inicialmente uma máquina de estados finitos.

Os inimigos deverão:

- Patrulhar.
- Detectar unidades.
- Perseguir alvos.
- Atacar.
- Recuar quando necessário.
- Reproduzir-se conforme suas características biológicas.

A IA deverá ser configurável por tipo de inimigo.

3.7 Sistema de habilidades

Cada unidade poderá ter habilidades específicas.

Exemplos:

- Ataque especializado.
- Reforço defensivo.
- Marcação de alvo.
- Mobilização rápida.
- Suporte a unidades próximas.

As habilidades terão tempo de recarga, alcance, duração e condições de ativação quando aplicável.

3.8 Sistema biológico

O sistema biológico deverá ser independente do sistema de combate.

Responsabilidades:

- Resistência bacteriana.
- Reprodução de microrganismos.
- Interação entre agentes infecciosos.
- Efeitos farmacológicos.
- Concentração de medicamentos.
- Dano tecidual.
- Resposta imunológica.

Os parâmetros serão simplificados inicialmente e evoluirão conforme as necessidades das campanhas.

3.9 Sistema de missões

Cada missão deverá ser carregada a partir de uma configuração própria.

A missão controla:

- Mapa.
- Unidades iniciais.
- Inimigos.
- Recursos.
- Eventos.
- Objetivos.
- Condições de vitória.
- Condições de derrota.

Isso permitirá criar novas missões sem reprogramar os sistemas centrais.

4. Primeiro protótipo funcional

Nome: PROTOTYPE 001 — FIRST CONTACT.

O primeiro protótipo não terá campanhas, laboratório ou sistema de progressão.

Seu objetivo será provar que o combate RTS funciona.

Conteúdo obrigatório

Mapa

- Um cenário isométrico 2D.
- Ambiente biológico representando tecido humano.
- Obstáculos.
- Área inicial.
- Área de invasão.

Unidades aliadas

- 3 NEUTROPHIL.
- 1 MACROPHAGE.

Inimigos

- 5 bactérias comuns.
- 1 bactéria com característica especial.

Mecânicas

- Selecionar soldados.
- Selecionar múltiplos soldados.
- Movimentar unidades.
- Criar formação.
- Atacar inimigos.
- Receber dano.
- Eliminar inimigos.
- Concluir a missão.

Interface

- Painel de unidades.
- Barra de vida.
- Botões de habilidades.
- Indicador de objetivo.
- Tela de vitória e derrota.

5. Cronograma por entregas

Etapa A — Fundação

- Criar projeto Godot.
- Configurar resolução e câmera.
- Criar estrutura de pastas.
- Implementar mapa de teste.

Etapa B — Controle

- Criar unidade base.
- Implementar seleção.
- Implementar movimentação.
- Implementar câmera e zoom.

Etapa C — Combate

- Criar inimigos.
- Implementar detecção.
- Implementar ataques.
- Implementar dano e eliminação.

Etapa D — Estratégia

- Criar grupos de controle.
- Implementar formações.
- Criar habilidades.
- Implementar comportamento de combate.

Etapa E — Missão

- Criar objetivos.
- Implementar vitória e derrota.
- Criar interface de missão.
- Testar o primeiro cenário completo.

Etapa F — Polimento

- Animações.
- Efeitos visuais.
- Sons.
- Ajustes de equilíbrio.
- Otimização.

6. Critérios de aprovação do protótipo

O protótipo será considerado funcional quando:

1. O jogador conseguir selecionar uma ou várias unidades.
2. As unidades obedecerem às ordens de movimentação.
3. As unidades conseguirem manter formações.
4. Os inimigos conseguirem detectar e atacar.
5. O combate funcionar sem travamentos ou erros críticos.
6. A missão conseguir identificar vitória e derrota.
7. Os dados das unidades puderem ser alterados sem modificar os sistemas centrais.
8. O jogo conseguir ser executado como uma versão independente no Windows.

7. Estratégia de desenvolvimento com Claude

O Claude será utilizado como assistente de programação.

Regras de trabalho:

- Desenvolver um sistema por vez.
- Nunca substituir arquivos completos sem necessidade.
- Solicitar explicação da arquitetura antes de alterações estruturais.
- Testar cada funcionalidade antes de avançar.
- Preservar funcionalidades já aprovadas.
- Registrar mudanças no CHANGELOG.
- Corrigir erros antes de adicionar novos recursos.
- Não criar sistemas futuros sem necessidade para o protótipo atual.

Cada entrega deverá conter:

- Arquivos criados.
- Arquivos modificados.
- Explicação das funcionalidades.
- Instruções de teste.
- Problemas conhecidos.

8. Fora do escopo inicial

Não desenvolver ainda:

- Multiplayer.
- Campanhas completas.
- Sistema de economia complexo.
- Centenas de unidades.
- Mundo aberto.
- Simulação integral de um organismo.
- Inteligência artificial avançada.
- Sistema online de contas.
- Traduções múltiplas.

9. Objetivo final da primeira versão

Entregar uma missão RTS jogável, visualmente coerente com a identidade militar do BIOWAR e com uma arquitetura preparada para receber novas unidades, inimigos, mapas e campanhas.

Princípio técnico fundamental: construir sistemas reutilizáveis, não missões isoladas programadas individualmente.

---

FIM DO PLANO TÉCNICO v0.1