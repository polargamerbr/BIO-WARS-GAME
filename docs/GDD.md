BIOWAR: FRONTLINE

Game Design Document — GDD v0.1

Status: Pré-produção
Versão: 0.1
Plataforma inicial: Windows PC
Motor gráfico: Godot Engine 4.x
Linguagem: GDScript
Gênero: RTS militar tático com progressão por campanhas

---

1. Visão geral

BIOWAR: FRONTLINE é um jogo de estratégia militar em tempo real ambientado no interior do corpo humano.

O jogador assume o comando de forças especializadas de defesa biológica, enfrentando invasões de bactérias, vírus, fungos e outros agentes infecciosos.

O jogo utiliza uma representação militar antropomórfica das estruturas e funções biológicas. Células imunológicas são representadas como soldados, equipes de suporte e unidades especializadas. Os tratamentos farmacológicos são representados como recursos estratégicos e capacidades operacionais.

A proposta combina:

- Estratégia militar em tempo real.
- Controle de unidades e formações.
- Habilidades especiais.
- Gerenciamento de recursos.
- Progressão tecnológica.
- Campanhas divididas em missões.
- Conteúdo científico adaptado à jogabilidade.

Pilares do jogo:

1. Estratégia acima de ação frenética.
2. Identidade militar forte.
3. Variedade de unidades e especializações.
4. Progressão por campanhas.
5. Fundamentação biológica e farmacológica.

2. Direção artística

2.1 Identidade visual

O jogo utilizará uma estética militar moderna, realista e cinematográfica.

Referência visual: forças especiais contemporâneas, equipamentos táticos modernos e cenários de ficção científica militar com influência biológica.

Características:

- Soldados humanoides com proporções realistas.
- Capacetes, coletes, mochilas, armamentos e equipamentos especializados.
- Texturas detalhadas e materiais com aparência física.
- Identificação das unidades por siglas e nomenclaturas científicas.
- Animações de combate, movimentação e formação.
- Ambientes orgânicos representando tecidos, vasos sanguíneos e órgãos.

2.2 Paleta de cores

- Verde-oliva: infantaria.
- Grafite e preto: operações especiais.
- Bege e areia: suporte e engenharia.
- Branco e cinza: unidades especializadas.
- Vermelho escuro: ambientes biológicos e zonas de infecção.
- Amarelo: alertas e ameaças.
- Verde: condições favoráveis e objetivos concluídos.

Evitar estética infantil, personagens cartunescos e representações de células como pequenas bolinhas coloridas.

2.3 Câmera

Perspectiva isométrica 2D.

Recursos:

- Zoom.
- Movimentação livre da câmera.
- Seleção individual e por grupo.
- Seleção por retângulo.
- Indicadores de alcance.
- Identificação de unidades.
- Interface de comandos.
- Mini mapa em versões posteriores.

3. Estrutura das campanhas

O jogo será dividido em campanhas independentes, organizadas por tipos de ameaças e situações biológicas.

Campanha I — Primeira Linha de Defesa

Introdução ao sistema de combate e às defesas naturais.

Missões:

1. Alerta de invasão.
2. Contenção bacteriana.
3. Mobilização dos neutrófilos.
4. Limpeza da área infectada.

Campanha II — Guerra Bacteriana

Introdução a tratamentos antibacterianos e mecanismos de resistência.

Missões:

1. Invasão bacteriana localizada.
2. Identificação de bactérias resistentes.
3. Operação de suporte farmacológico.
4. Combate contra bactérias produtoras de betalactamases.
5. Controle de uma infecção persistente.

Campanha III — Invasão Viral

Introdução às respostas antivirais.

Missões:

1. Identificação de células infectadas.
2. Mobilização de células NK.
3. Resposta dos linfócitos T.
4. Produção de anticorpos.
5. Contenção da propagação viral.

Campanha IV — Guerra Fúngica

Introdução aos agentes antifúngicos e às estruturas dos fungos.

Campanha V — Emergência Sistêmica

Cenários avançados envolvendo infecções disseminadas, inflamação excessiva e preservação dos órgãos.

As campanhas serão desenvolvidas progressivamente. Não fazem parte do primeiro protótipo.

4. Sistema de unidades

As unidades serão divididas por função operacional.

4.1 Defesa natural

NEUTROPHIL — Infantaria de resposta rápida

- Alta mobilidade.
- Combate direto.
- Resposta rápida.
- Fagocitose de agentes invasores.
- Baixa resistência em confrontos prolongados.

MACROPHAGE — Unidade pesada

- Maior resistência.
- Capacidade de fagocitose.
- Remoção de invasores e resíduos.
- Participação na apresentação de antígenos.
- Mobilidade reduzida.

4.2 Defesa adaptativa

T HELPER — Coordenação tática

- Coordenação da resposta imune.
- Apoio às unidades aliadas.
- Ativação de respostas especializadas.
- Habilidades de comando.

CYTOTOXIC T — Operações especiais

- Reconhecimento de células infectadas.
- Eliminação direcionada de células comprometidas.
- Alta especialização.
- Necessidade de identificação prévia do alvo.

B CELL — Unidade de suporte estratégico

- Produção de anticorpos.
- Marcação de ameaças.
- Apoio ao reconhecimento e neutralização de invasores.

4.3 Defesa especializada

NK CELL — Forças especiais

- Reconhecimento de células alteradas ou infectadas.
- Eliminação de determinados alvos celulares.
- Mobilidade e capacidade de resposta rápida.

As unidades terão atributos próprios: resistência, mobilidade, alcance, especialização, custo operacional e habilidades.

A nomenclatura militar é uma representação de gameplay, não uma equivalência literal entre células e soldados.

5. Inimigos

Os inimigos terão aparência e comportamento próprios.

Categorias:

- Bactérias comuns.
- Bactérias encapsuladas.
- Bactérias produtoras de betalactamases.
- Bactérias resistentes a determinados antibióticos.
- Vírus.
- Fungos.
- Parasitas.

Cada inimigo poderá apresentar:

- Resistência.
- Velocidade.
- Capacidade de reprodução.
- Mecanismos de defesa.
- Vulnerabilidades.
- Comportamento de grupo.
- Habilidades específicas.

A resistência bacteriana deverá ser representada como um mecanismo biológico, não apenas como aumento arbitrário da vida do inimigo.

6. Sistema farmacológico

Os medicamentos serão tratados como recursos estratégicos ou unidades de efeito farmacológico.

Exemplos:

Amoxicilina

- Interfere na síntese da parede celular bacteriana.
- Afeta bactérias sensíveis.
- Sua eficácia depende da concentração e do tempo de exposição.

Clavulanato

- Inibe determinadas betalactamases.
- Protege a amoxicilina contra determinados mecanismos de degradação.
- Não neutraliza todos os mecanismos de resistência.

Outras classes serão introduzidas nas campanhas posteriores.

O sistema deverá permitir representar concentração, absorção, distribuição, metabolismo e eliminação de forma simplificada.

Não será permitido que medicamentos tenham efeitos biologicamente incompatíveis apenas para criar uma habilidade interessante sem explicação no universo do jogo.

7. Mecânicas de combate

O combate será em tempo real.

Controles previstos:

- Clique esquerdo: selecionar unidade.
- Arrastar: seleção múltipla.
- Clique direito: movimentar ou atacar.
- Teclas numéricas: grupos de controle.
- Teclas de habilidade: ativação de capacidades especiais.
- Shift: adicionar unidades à seleção.
- Comandos de formação.

Formações

Primeiras formações previstas:

- Linha de combate.
- Formação compacta.
- Formação defensiva.
- Formação dispersa.

As formações terão consequências reais na movimentação, proteção e eficiência operacional.

Comportamentos

As unidades deverão:

- Identificar ameaças dentro do alcance.
- Atacar alvos válidos.
- Respeitar ordens do jogador.
- Evitar obstáculos.
- Manter formação quando possível.
- Reagir a ameaças próximas.
- Retornar à formação após movimentação.

8. Sistema de missões

Cada missão deverá possuir um arquivo de configuração independente.

Informações:

- Identificador.
- Nome.
- Campanha.
- Dificuldade.
- Cenário.
- Unidades disponíveis.
- Inimigos.
- Recursos iniciais.
- Objetivos principais.
- Objetivos secundários.
- Condições de vitória.
- Condições de derrota.

Exemplo:

MISSÃO 001 — PRIMEIRO CONTATO

Objetivo: conter uma invasão bacteriana localizada.

Unidades:

- 3 NEUTROPHIL.
- 1 MACROPHAGE.

Inimigos:

- Bactérias invasoras.
- Uma unidade bacteriana especializada.

Vitória:

- Controlar todos os focos de invasão.

Derrota:

- Ultrapassar o limite de dano tecidual.

9. Progressão

O jogador receberá pontos de pesquisa e experiência operacional.

Desbloqueios:

- Novas unidades.
- Novas habilidades.
- Novas formações.
- Novas tecnologias.
- Novas campanhas.

A progressão deverá privilegiar especialização e variedade, não apenas aumentar números de ataque e resistência.

10. Interface

A interface deverá apresentar:

- Barra superior com recursos e indicadores da missão.
- Painel inferior com unidades selecionadas.
- Barra de habilidades.
- Indicadores de vida e condições das tropas.
- Objetivos da missão.
- Alertas de ameaças.
- Painel de informações científicas.

O HUD deverá manter uma identidade militar, semelhante a um sistema de comando operacional.

11. Regras de qualidade

- Não utilizar personagens infantis ou cartunescos.
- Não transformar todos os medicamentos em soldados armados.
- Não confundir vírus com bactérias.
- Não apresentar antibióticos como tratamento antiviral.
- Não tratar resistência bacteriana como invulnerabilidade absoluta.
- Diferenciar simplificação de gameplay de realidade científica.
- Priorizar desempenho e legibilidade durante batalhas com muitas unidades.

---

FIM DO GDD v0.1