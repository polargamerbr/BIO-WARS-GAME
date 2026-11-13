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
- **Confirmado em 2026-11-11 (diretor do projeto):** continua o design camuflado areia sobre preto. As vistas de frente e de costas oficiais são as exportadas do Meshy (`neutrophil_front.png` e `neutrophil_back.png`). A versão de placas cinza gerada no Gemini foi descartada e está guardada em `docs/art/descartadas/`. O fuzil do Gemini (`neutrophil_rifle_side.jpeg`, grafite e areia com a gota vermelha) combina com esse design e foi mantido.
- **Paleta:** grafite e areia para o Neutrophil. O GDD v0.1 previa verde-oliva para infantaria, então o GDD precisa ser atualizado ou o oliva fica para outra classe.

### D003: Navegação só com o chão como superfície andável (2026-11-10)
- **Decisão:** a malha de navegação é gerada de um chão plano, e os obstáculos entram como bloqueios (`add_projected_obstruction` com `carve = false`). Os obstáculos continuam com colisão física própria.
- **Motivo:** gerar a malha a partir dos colisores fazia o topo dos obstáculos virar uma superfície andável inalcançável. Clicar num obstáculo mandava a unidade para essa ilha e ela travava. Com `carve = true` o raio do agente é ignorado e o caminho encosta no obstáculo.
- **Consequência:** o raio da malha é único (0,75 m, o do Macrophage). Mapas com relevo, rampas ou vários andares vão exigir outra abordagem.
- **Desvio de altura:** o bake deixa a malha 0,5 m acima do chão. A região é abaixada por esse desvio, medido na hora, para as distâncias de chegada em 3D funcionarem.

### D004: Atributos de unidade em `UnitData` (.tres) (2026-11-10)
- **Decisão:** vida, velocidade e tamanho do corpo vêm de `data/units/*.tres`. Atributos de combate (alcance, dano, tempo de ataque) entram na Etapa C, quando existirem usuários deles.
- **Valores atuais:** provisórios, como os da prancha do Neutrophil.

### D005: Combate de curto alcance no protótipo (2026-11-10, substituída pela D013)
- **Decisão:** NEUTROPHIL e MACROPHAGE atacam a 2 m (entre as bordas dos corpos), a bactéria a 1,5 m. O ataque é instantâneo, sem projétil.
- **Motivo:** o GDD descreve as duas unidades com fagocitose e combate direto. Isso deixa de lado o fuzil da arte de referência até a pendência "Alcance dos soldados" ser decidida.
- **Reversível:** sim. O alcance é só um valor nos arquivos `.tres`. Um ataque à distância de verdade exigiria projéteis, que ainda não existem.

### D006: Uma única classe `Unit` para aliados e inimigos (2026-11-10)
- **Decisão:** aliados e inimigos usam a mesma `Unit`, diferenciados pelo time (`Team`) e pelo `UnitData`. A IA inicial dos inimigos é a mesma máquina de estados dos aliados.
- **Motivo:** o combate fica simétrico e não há código duplicado. Comportamentos próprios de inimigos (patrulha, reprodução, resistência) entram depois, no sistema biológico, sem mudar essa base.

### D007: Consequências das formações (2026-11-10, provisória)
- **Decisão:** cada formação muda o comportamento do grupo, além do desenho. Os efeitos estão nos `.tres` de `data/formations/`.
  - LINHA: sem efeito (referência).
  - COMPACTA: anda na velocidade da unidade mais lenta.
  - DEFENSIVA: mantém posição sem perseguir, recebe 25% menos dano parada e anda junto.
  - DISPERSA: espaçamento de 3,5 m.
- **Motivo:** o GDD pede consequências reais na movimentação, proteção e eficiência. Mudar só o desenho não atenderia.
- **Pendente:** a DISPERSA só ganha sentido em combate quando existirem ataques em área. A formação é global, e não por grupo.

### D008: Primeiras habilidades com base biológica (2026-11-10, provisória)
- **NEUTROPHIL, MOBILIZAÇÃO RÁPIDA:** representa a quimiotaxia, a migração rápida do neutrófilo até o foco de infecção. É um aumento de velocidade na própria unidade.
- **MACROPHAGE, SINALIZAÇÃO POR CITOCINAS:** representa as citocinas inflamatórias que ativam as células de defesa próximas. É um aumento de dano nos aliados em volta.
- **Regra:** os efeitos não acumulam. Usar de novo só renova a duração, e as habilidades não afetam inimigos.

### D009: Regras da MISSÃO 001 (2026-11-11, provisória)
- **Foco controlado:** todos os invasores que nasceram no foco foram eliminados e há uma unidade do jogador dentro da área. Uma vez controlado, o foco não volta a ficar ativo.
- **Dano tecidual:** cada invasor vivo soma uma taxa por segundo (comum 0,2%/s, encapsulada 0,35%/s). Chegar a 100% é derrota, e passar do limite secundário (50% na versão inicial, 35% depois da D012) falha o objetivo secundário. Representa o limite de dano tecidual do GDD.
- **Derrota também** quando todas as unidades do jogador caem.
- **Motivo:** o GDD pede "controlar todos os focos" e "ultrapassar o limite de dano tecidual". A taxa por invasor cria pressão de tempo sem precisar ainda da reprodução bacteriana.

### D010: Cápsula como mecanismo, e não como vida extra (2026-11-11, provisória)
- **Decisão:** a bactéria encapsulada bloqueia 60% do dano de atacantes comuns. Atacantes ativados pela SINALIZAÇÃO POR CITOCINAS ignoram a cápsula.
- **Motivo:** o GDD exige que a resistência seja um mecanismo biológico, e não só mais vida. A cápsula polissacarídica dificulta a fagocitose, e fagócitos ativados por citocinas são mais eficazes contra ela. Isso também dá um uso tático para a habilidade do Macrophage.
- **Simplificação:** na biologia real, a principal resposta à cápsula é a opsonização (anticorpos e complemento), que entra quando existirem as unidades adaptativas (B CELL).

### D011: Polimento provisório sobre os corpos de cápsula (2026-11-11)
- **Decisão:** animações procedurais e sons sintetizados, sem arte nem áudio de terceiros. As animações ficam em `unit_visuals.gd` e os sons são gerados por `tools/generate_sfx.py`.
- **Motivo:** o protótipo precisa de retorno visual e sonoro para ser jogável e testável. Os modelos 3D com rig (D001) e os sons definitivos ainda não existem.
- **Troca futura:** quando chegarem os modelos, o `UnitVisuals` é substituído pelo `AnimationPlayer` deles, sem mexer na `Unit`. Os sons definitivos entram com os mesmos nomes de arquivo.

### D012: Balanceamento da MISSÃO 001 por simulação (2026-11-11, provisória)
- **Decisão:** bactéria comum com dano 5 e objetivo secundário de 35% de dano tecidual. NEUTROPHIL continua com 100 de vida.
- **Motivo:** com 120 de vida, a jogada sem pensar (sem citocinas contra a encapsulada) ficava quase igual à boa. Com dano 6, até a melhor jogada perdia 1 a 2 de 4 unidades, o que é duro para a primeira missão. O limite de 50% era cumprido por qualquer estratégia.
- **Pendente:** validar com pessoas jogando.

### D013: Soldados com fuzil (2026-11-11, MACROPHAGE revisto na D015)
- **Decisão (do diretor do projeto):** NEUTROPHIL e MACROPHAGE atacam à distância, com fuzil. Isso resolve a pendência "Alcance dos soldados" e substitui a D005.
  - NEUTROPHIL: alcance de 7 m, detecção de 11 m.
  - MACROPHAGE: arma pesada, com alcance de 5 m, mais dano por tiro e cadência menor.
  - O tiro é um projétil a 40 m/s que aplica o dano ao chegar e some se o alvo morrer antes.
- **Inimigos:** as bactérias continuam atacando por contato.
- **Coerência com o GDD:** segue a arte de referência do Neutrophil, que carrega fuzil. O fuzil é a representação militar da ação da célula de defesa (D001 e GDD 4: "nomenclatura militar é representação de gameplay"). A cápsula da bactéria encapsulada continua reduzindo esse dano, como representação da resistência à fagocitose.
- **Fagocitose:** fica para uma habilidade ou efeito futuro. Não é o ataque básico.
- **Balanceamento (simulação, 3 partidas por estratégia):**
  - Boa jogada: ~21 s, ~21% de dano tecidual, 0 perdas (1 em uma rodada).
  - Compacta: ~24 s, 0 perdas.
  - Ingênua: ~27 s, ~26%, 1 perda.
  - Os valores da D012 foram mantidos.

### D014: Invasores humanoides com aspectos de bactéria (2026-11-11)
- **Decisão (do diretor do projeto):** as bactérias deixam de ser bastonetes e viram criaturas humanoides. Continuam lendo como bactéria:
  - Corpo de segmentos em bastonete fundidos e pele de membrana celular.
  - Placas de parede celular, pili e glândulas de toxina.
  - Sem olhos.
- **Inspiração:** o "enxame alienígena predador" da ficção científica (tipo Zerg ou Xenomorfo), **sem copiar**. O design é original e os prompts proíbem os traços marcantes dessas criaturas.
- **No protótipo:** o corpo provisório `CREATURE` tem tronco curvado, cabeça sem rosto, espinhos (pili) e brilho de toxina no peito, com animação de passo nervoso e balanço de predador. A bactéria encapsulada ganha uma casca translúcida creme em volta do corpo, que é a cápsula visível.
- **Mantido:** GDD 2.1 (nada cartunesco) e a regra de não confundir vírus com bactéria.

### D015: MACROPHAGE como tropa física com escudo de bioenergia (2026-11-11)
- **Decisão (do diretor do projeto):** o MACROPHAGE larga a arma pesada e passa a lutar corpo a corpo (alcance de 1,5 m), com um escudo de bioenergia. Substitui a parte da D013 sobre o MACROPHAGE. O NEUTROPHIL continua com fuzil.
- **Escudo:** 120 pontos que absorvem dano antes da vida. Recarrega a 30 pontos/s depois de 4 s sem tomar dano. Os valores ficam no `UnitData` (`shield_max`, `shield_regen_delay`, `shield_regen_rate`).
- **Visual:** painel de energia ciano translúcido à frente do corpo, faixa ciano acima da barra de vida e sons de impacto e de estouro do escudo.
- **Coerência com o GDD:** o GDD 4.1 descreve o MACROPHAGE como unidade pesada, de grande resistência e com fagocitose. O combate de perto representa a fagocitose (engolir o invasor), e o escudo representa a resistência. O papel é de linha de frente.
- **Balanceamento (simulação):** vitória em todas as estratégias, com 0 a 1 perda. A boa jogada fica em ~22 s e ~22% de dano tecidual.
- **Pendente:** os invasores escolhem sempre o alvo mais próximo, então às vezes ignoram o MACROPHAGE e atacam os NEUTROPHILS. Uma habilidade de provocação faria dele um tanque de verdade.

### D016: Modelos 3D chegam pela ponte do Tripo (2026-11-11)
- **Decisão (do diretor do projeto):** os modelos 3D são gerados no Tripo Studio e enviados ao Godot pelo plugin Tripo Bridge. O plugin foi movido para `addons/tripo_bridge/` (antes ficava na raiz, onde o Godot não o reconhecia) e ativado no projeto.
- **Fluxo:** a imagem de referência é aprovada (ART_PROMPTS) e vira modelo no Tripo Studio. O modelo é enviado pela ponte, chega em `res://TripoModels/` e depois vai para a pasta da unidade, onde substitui o corpo provisório.
- **Por que não a API:** a API exige chave própria e normalmente tem cobrança separada da assinatura do site. A ponte usa a mesma geração que já seria feita no site.
- **Segurança:** o servidor do plugin escuta só em `127.0.0.1:60650`, no próprio computador. O plugin fica fora do executável. Ele grava em `project.godot` a data da última limpeza de arquivos temporários (`tripo_bridge/last_cleanup`).

### D017: Como os modelos 3D entram no jogo (2026-11-12)
- **Dados:** cada unidade aponta para o modelo no `UnitData` (`model_scene`), com o giro para a frente e os nomes das animações. Trocar ou adicionar modelos não exige mudar código.
- **Escala:** o modelo é ajustado à `body_height` da unidade. A colisão continua sendo a cápsula do `UnitData`.
- **Animação:** o deslocamento vem da navegação, então o avanço das animações (root motion) é retirado do osso raiz. Repetição ligada para parado, andar, correr e atacar.
- **Esqueleto:** Mixamo, que é padrão, funciona bem no Godot e permite reaproveitar animações entre os soldados.
- **Formato:** a ponte entrega FBX com texturas em pasta ao lado. O Godot importa FBX direto.

## Em aberto

- **Recurso do jogador:** o GDD fala em "recursos iniciais" sem definir o que são. Ideia em avaliação: sinais inflamatórios para chamar reforços.
- **Formato de dados:** o plano cita Resources e JSON. A decidir se fica só Resources (`.tres`).
- **Estatísticas da prancha do Neutrophil** (custo, tempo de produção, cura): são placeholder, não valem como regra.
