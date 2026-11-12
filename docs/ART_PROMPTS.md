# ART PROMPTS — BIOWAR: FRONTLINE

Prompts para gerar as imagens de referência no Gemini (ou outra IA de imagem) **antes** de gastar créditos no Tripo/Meshy.

## Fluxo recomendado (economiza créditos)

1. **Gerar e iterar a imagem 2D no Gemini** (barato ou grátis). Repita até ficar boa. Errar aqui não custa crédito de 3D.
2. **Conferir a imagem** com a checklist do fim deste arquivo.
3. **Mandar só a imagem aprovada para o Tripo** (imagem → modelo 3D). Uma geração por asset, em vez de várias tentativas por texto.
4. Se o Tripo aceitar várias vistas (*multiview*), gere frente, lado e costas no Gemini e mande as três. O modelo sai mais fiel.
5. **Armas em arquivo separado** do soldado. No Godot, a arma vai presa ao osso da mão. Isso facilita o rig, a animação e a troca de arma.
6. Os arquivos vão para `assets/units/<unidade>/reference/` (imagens) e `assets/units/<unidade>/` (o `.glb`).

Dica: o Neutrophil já tem uma referência aprovada (`assets/units/neutrophil/reference/neutrophil_front.png`). **Anexe essa imagem no Gemini** junto com os prompts das outras unidades e peça "mesmo estilo e mesma qualidade". Assim toda a tropa fica coerente.

---

## Bloco de estilo (cole no início de todo prompt de personagem)

```
Style: realistic modern military sci-fi concept art for a 3D game character reference,
grounded and cinematic, NOT cartoon, NOT chibi, NOT anime. Realistic human proportions.
Detailed physical materials: matte armor plates, worn fabric, scuffed metal, rubber, nylon straps.
Setting context: elite soldiers that represent immune system cells fighting infections inside the human body
(military anthropomorphic representation).
```

## Regras técnicas para imagem → 3D (cole no fim de todo prompt de personagem)

```
Technical requirements for image-to-3D conversion:
single character, full body visible from head to boots, centered, nothing cropped,
A-pose (arms 30-45 degrees away from the body, legs slightly apart), facing the camera,
orthographic front view, neutral flat light gray background, soft even studio lighting,
no cast shadows on the floor, no motion blur, no depth of field, no text, no logos, no watermark,
no weapon in the hands, hands open and relaxed, no cape, no loose cloth, no thin hanging parts,
no particles or effects around the character.
```

## Lista do que evitar (negativo)

Use no campo de "negative prompt" quando existir. No Gemini, escreva no final como "Avoid: ...":

```
Avoid: cartoon, chibi, anime, toy, cute, big head, exaggerated proportions, cropped body,
dramatic perspective, low angle, dynamic pose, weapon in hand, holding objects, cape, scarf,
long hair, background scenery, text, logo, watermark, red cross symbol, multiple characters,
blurry, motion blur, heavy shadows.
```

> O emblema **não pode ser a cruz vermelha** (protegida por lei, D002). Use a **gota vermelha**.

---

## 1. NEUTROPHIL — vistas que faltam (lado e costas)

A frente já existe. Para o Tripo *multiview*, anexe `neutrophil_front.png` e peça:

```
Using the attached image as the exact design reference, generate the SAME character
from the [LEFT SIDE / BACK] view. Keep identical: gray combat helmet with a vertical red stripe,
glowing blue visor, sand/tan camouflage over black combat uniform, tan plate carrier with pouches,
red blood-drop emblem on both shoulder plates, knee pads, black boots.
Same A-pose, same proportions, same scale, orthographic [left side / back] view,
neutral flat light gray background, even studio lighting, no shadows, no weapon, no text.
```

Gere duas imagens, uma com `LEFT SIDE` e outra com `BACK`.

## 2. MACROPHAGE — tropa física com escudo de bioenergia

O GDD define: unidade pesada, maior resistência, mobilidade reduzida e fagocitose. A D015 define: combate corpo a corpo e escudo de bioenergia.

O escudo de energia translúcido é um **efeito feito no Godot**, não parte do modelo. No modelo 3D, só entra o **emissor**, o aparelho no antebraço que projeta o escudo.

```
[BLOCO DE ESTILO]

Character: "MACROPHAGE", heavy close-combat shock trooper of the immune defense force,
a physical brawler built to hold the front line and engulf invaders (phagocytosis theme).
Noticeably bulkier and taller than a standard soldier, broad shoulders, heavy layered armor plates,
thick reinforced chest armor, large rounded shoulder pauldrons, armored shins.
Left forearm: a large armored bio-energy shield EMITTER gauntlet (a thick device with a glowing
cyan emitter strip along its edge, NO energy shield shown, just the device).
Right forearm: massive reinforced combat gauntlet with short retractable claws, built for close combat.
No firearm, no guns.
Enclosed heavy helmet with a wide glowing blue visor slit.
Color palette: olive drab green armor plates over graphite black undersuit, worn edges,
cyan glowing accents only on the shield emitter, small red blood-drop emblem on each shoulder
(same emblem family as the Neutrophil). Feels like a walking tank: slow, sturdy, protective.

[REGRAS TÉCNICAS]
[NEGATIVO]
```

## 3. Fuzil do NEUTROPHIL (arma separada)

```
Single futuristic military assault rifle, product shot for a 3D game prop reference.
Compact bullpup or modern carbine design, matte graphite black body with sand/tan polymer parts,
small red drop-shaped insignia on the stock, short optic sight on top, magazine inserted.
Side view (left side), orthographic, the whole weapon visible and centered,
neutral flat light gray background, even studio lighting, no shadows, no hands, no person,
no text, no logos, no watermark. Realistic materials, not cartoon.
```

## Invasores: direção de arte (D014)

Os invasores são **criaturas humanoides que mantêm os aspectos de bactéria**. A inspiração é o "enxame alienígena predador" de ficção científica, mas o **design é original**. Não pode copiar criaturas existentes: nada do crânio alongado do Xenomorfo, nada das carapaças dos Zerg, nada de biomecânica estilo Giger.

O que faz cada criatura ler como **bactéria**:
- Corpo formado por segmentos em bastonete (bacilos) fundidos.
- Pele de membrana celular, úmida e brilhante.
- Placas rígidas de parede celular como armadura natural.
- Fileiras de **pili** (cerdas curtas) nas costas e nos antebraços.
- Glândulas de **toxina** com brilho amarelo-esverdeado.
- **Sem olhos** (bactérias não têm), só fendas e poros sensoriais.

Bloco de estilo dos invasores (use no lugar do bloco dos soldados):

```
Style: realistic dark sci-fi creature concept art for a 3D game enemy reference, grounded and
menacing, NOT cartoon, NOT cute. ORIGINAL creature design inspired by the general idea of an
alien swarm predator, but do NOT replicate any existing franchise creature: no elongated
xenomorph skull, no zerg-like carapace, no Giger biomechanical style.
Setting context: pathogenic bacteria represented as humanoid invader soldiers inside the human body;
the creature must clearly read as a BACTERIUM.
```

Regras técnicas dos invasores (as mesmas dos soldados, adaptadas):

```
Technical requirements for image-to-3D conversion:
single creature, full body visible, centered, nothing cropped, standing in a neutral A-pose
(arms held 30-45 degrees away from the body, legs slightly apart), facing the camera,
orthographic front view, neutral flat light gray background, soft even studio lighting,
no cast shadows, no motion blur, no text, no watermark, no weapons, no thin hanging strands
or long tentacles, no long thin flagella, no particles or slime drips.
```

## 4. BACTÉRIA COMUM — infantaria do enxame

```
[BLOCO DE ESTILO DOS INVASORES]

Creature: "COMMON BACTERIUM", lean hunched humanoid skirmisher, slightly shorter than a human soldier.
Digitigrade legs, forward-leaning predatory posture, long arms ending in fused claw-like fingers.
Body visibly built from fused rod-shaped bacillus segments (torso, upper arms and thighs are capsule-shaped
segments joined together). Wet glossy cell-membrane skin in sickly yellow-green with darker olive mottling,
hard pale cell-wall plates as natural armor ridges on the shoulders, spine and shins,
rows of short stubby pili bristles along the back and forearms,
small glowing yellow-green toxin glands on the chest and throat.
Eyeless smooth elongated-oval head with sensory slits and pores, small jaw-like mandible plates.

[REGRAS TÉCNICAS DOS INVASORES]
```

## 5. BACTÉRIA ENCAPSULADA — bruto protegido (inimigo especial)

D010: a cápsula polissacarídica dificulta a fagocitose. Ela precisa ficar **visível** como uma camada translúcida em volta do corpo inteiro.

```
[BLOCO DE ESTILO DOS INVASORES]

Creature: "ENCAPSULATED BACTERIUM", a bulkier, heavier brute version of the common bacterium creature,
taller and wider, slower and tank-like, same bacterial anatomy (fused rod-shaped bacillus segments,
yellow-green membrane skin, cell-wall plates, short pili, glowing toxin glands, eyeless head).
Its WHOLE body is wrapped in a thick, smooth, milky-cream translucent gelatinous capsule layer
(polysaccharide capsule), like a soft glossy outer shell a few centimeters thick that follows the body
shape; the creature's body is clearly visible THROUGH the translucent capsule.
The capsule gives it a rounded, protected silhouette.

[REGRAS TÉCNICAS DOS INVASORES]
```

Dica para o 3D: se o Tripo não conseguir a camada translúcida, gere a criatura **sem a cápsula**. A cápsula pode ser feita no Godot como uma casca transparente, que é como o protótipo já faz.

## 6. Obstáculo de tecido (cenário)

Substitui os blocos marrons do mapa de teste.

```
3D game environment prop reference: a large mass of human connective tissue structure,
dense bundles of collagen fibers and fibrous tissue forming a solid rock-like wall segment,
dark red, maroon and brownish-pink organic colors, wet sheen, sinewy striations,
roughly box-shaped overall silhouette with a flat base (usable as a battlefield obstacle),
realistic, not cartoon, not gory. Three-quarter top view, single object centered,
neutral flat light gray background, even studio lighting, no shadows, no text.
```

## 7. Textura do chão (não é modelo 3D)

Esta vai direto para o material do chão no Godot. Não passa pelo Tripo.

```
Seamless tileable top-down texture of the surface of living human tissue for a strategy game ground,
dark red and maroon organic surface with subtle muscle fiber striations, small capillaries,
moist sheen, low contrast so units remain readable on top of it, even flat lighting,
no shadows, no perspective, straight overhead view, no text. Square image.
```

---

## Checklist antes de mandar para o Tripo

- [ ] Corpo inteiro na imagem, nada cortado (pés e cabeça visíveis).
- [ ] Fundo liso e neutro, sem cenário.
- [ ] A-pose (personagens), de frente, sem perspectiva dramática.
- [ ] Sem arma na mão (as armas são geradas à parte). O Macrophage não usa arma de fogo.
- [ ] Sem partes finas soltas (alças penduradas, flagelos longos, cabos), que viram defeito no 3D.
- [ ] Cores e emblema conferem com a ficha (gota vermelha, sem cruz).
- [ ] Silhueta distinta das outras unidades quando vista de cima e de longe (câmera isométrica).

## Alternativas gratuitas para testar o 3D antes do Tripo

Existem modelos abertos de imagem → 3D com demonstrações públicas, por exemplo **Hunyuan3D-2** (Tencent) e **TRELLIS** (Microsoft), no Hugging Face Spaces. Podem ter fila e limite de uso. Servem para conferir se a imagem de referência converte bem antes de gastar crédito pago.

Rodar esses modelos localmente exige uma GPU NVIDIA com bastante memória. A RX 580 desta máquina não serve para isso.
