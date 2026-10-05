# Shinobi RPG 3D

Projeto Android que busca a maior fidelidade prática possível a **Naruto: Ultimate Ninja Storm 1**, em combate e, na fase do mundo, exploração física de Konoha. A direção completa está em [PROJECT_DIRECTION](docs/PROJECT_DIRECTION.md).

> Projeto independente em desenvolvimento. Nenhum arquivo proprietário de Storm foi baixado ou extraído. A origem/licença do modelo previamente fornecido ainda não foi comprovada; desenvolvimento e publicação têm gates separados.

## Engine e alvo
- Godot 4.7.2
- mobile-first
- orientação horizontal (landscape)
- alvo de 60 FPS
- renderer `gl_compatibility`

## Gráficos anime

Primeiro incremento visual inspirado em Genshin Impact: iluminação em faixas,
sombras azuladas, luz de contorno, céu/paleta renovados e névoa leve na arena e
aldeia. Texturas do Naruto preservadas; seleção/CPU/clones usam a mesma camada.
LOW/MED/HIGH continuam disponíveis. Implementação autoral, ainda sem acabamento
equivalente ao jogo de referência nem medição no Android. [Detalhes e validação](docs/ANIME_GRAPHICS.md).

## Seleção e batalha

O jogo abre em seleção de jogador, CPU e arena, com preview 3D. O **elenco jogável completo de 25 lutadores do Storm 1** já aparece na seleção. Naruto, Sasuke, Sakura e Kakashi possuem modelos próprios estilizados e perfis Resources separados; os outros 21 usam temporariamente o rig compartilhado, mas já possuem perfis independentes de combo terrestre/aéreo, velocidade, vida, knockback e launcher. Todos os 25 possuem pelo menos dois jutsus selecionáveis e acesso a Ultimate/Awakening; Naruto preserva os controladores específicos existentes e os demais usam perfis data-driven. Os números, nomes de desenvolvimento e coreografias compartilhadas dos kits novos são OUR_APPROXIMATION e ainda exigem passes autorais específicos por personagem. As animações reais ainda são compartilhadas e não equivalem às coreografias completas do Storm. As duas variantes da arena têm cenário autoral de treino/pátio com luz de entardecer; nenhum mapa de Storm foi importado. Veja [elenco](docs/STORM1_CHARACTER_ROSTER.md) e [modelos/apresentação](docs/STYLIZED_PRESENTATION.md).

Sasuke tem Fireball com sweep e Chidori preso à mão; Sakura combina Booby Trap e Cherry Blossom Impact; Kakashi mantém Raikiri/Fireball. Os três agora também recebem Ultimate/Awakening próprios de desenvolvimento via perfis compartilhados, sem reutilizar a coreografia exclusiva do Naruto. Naruto conserva seu arsenal. A CPU usa os mesmos módulos de chakra/dash/jutsu/clones/Ultimate/Awakening/tools, com decisões atrasadas e probabilísticas. KO em versus abre vitória/derrota, seleção e revanche. A aldeia/treino e o save existente continuam disponíveis.

Áudio CC0 Kenney, oito vozes SFX + um canal de carga; SOM ON/OFF salva a preferência. LOW/MED/HIGH mantém regras de colisão/timing iguais. FPS/DC ajudam a comparar no Moto G22; não houve medição real de FPS/GPU Android nesta sessão. Ver [validação e pendências](docs/SELECTABLE_FIGHTERS.md).

## Combate atual
- movimentação 3D e corrida
- pulo
- lock-on e strafe
- câmera automática de combate
- combo terrestre de 4 golpes
- hitbox/hurtbox 3D separadas por camada de colisão
- janelas de impacto sincronizadas com o estado do golpe
- finisher terrestre alto lança; neutro afasta, baixo derruba e lateral desloca
- chakra dash persegue alvo lançado no ar
- combo aéreo
- pequena suspensão aérea durante ataques para facilitar continuidade
- 4º golpe aéreo derruba o oponente
- chakra dash
- carregamento manual de chakra
- defesa segurando botão
- esquiva com invulnerabilidade curta
- substituição com 4 cargas e cooldown
- pelo menos dois jutsus selecionáveis por personagem, com custo/cooldown/dano próprios
- Ultimate confirmado por hit para os 24 não-Naruto; Naruto mantém seu Ultimate específico
- Awakening temporário para os 25, com multiplicadores e VFX por perfil
- vida do jogador, stagger, derrota e respawn
- inimigo rigado com IA de perseguição, combos, defesa, substituição e arsenal compartilhado
- ataques da IA também usam janela de hitbox
- K.O. e respawn do inimigo
- HUD de vida, chakra, substituições, cooldowns, estado de animação e FPS
- contador de combo com HITS e dano acumulado
- hit-stop curto apenas quando o golpe conecta
- VFX leves para impacto normal, defesa, launcher, slam e bounce
- zoom de impacto e camera shake por intensidade do golpe
- ground bounce depois de slam
- wall bounce em golpes fortes contra as paredes da arena
- efeito visual leve de chakra dash
- efeito de fumaça na substituição
- arena fechada com quatro paredes físicas
- controles multi-touch

## Máquina de estados de animação
O controlador expõe estados explícitos:

- `idle`
- `run`
- `air`
- `attack`
- `air_attack`
- `guard`
- `dodge`
- `chakra_dash`
- `chakra_charge`
- `jutsu`
- `hit`
- `defeat`

O projeto agora possui um adapter real para `Skeleton3D + AnimationTree`. Quando existe `res://assets/characters/rigged.glb`, o modelo é instanciado automaticamente, o humanoide procedural é ocultado e os estados do combate passam a controlar uma máquina de estados de animação.

O combate usa **27 clips reais retargetados e pré-bakeados**, derivados das Universal Animation Libraries 1 e 2 do Quaternius (CC0). O `happy` permanece no GLB original, mas não participa do combate. Não há geração procedural de animações do rig em runtime.

Inclui idle, jog/sprint, salto, queda, pouso, jab, cross, hook, launcher, quatro golpes aéreos (incluindo slam), guarda, roll/dodge, chakra dash, carregamento, jutsu, hit reaction, knockback e KO. Launcher e variantes aéreas são adaptações de animações do pacote, documentadas em `docs/ANIMATION_SOURCES.md`; não são mocap dedicado nem movimentos extraídos de Storm.

A biblioteca `assets/animations/combat_mixamo.tres` contém movimentos reais em 65 ossos. O AnimationTree tem estados e crossfades explícitos, relógio de física compartilhado com o combate, reinício de ataques repetidos e velocidade de locomoção ajustável. Startup, duração e mão de impacto vêm de `combat_manifest.json`.

## Controles mobile
- **Joystick esquerdo:** mover; perto da borda corre
- **Arrastar lado direito:** girar câmera sem lock
- **ATK:** combo terrestre/aéreo
- **JUTSU:** usar jutsu
- **DASH:** chakra dash e perseguição aérea
- **PULO:** pular
- **ESQ:** esquiva
- **SUB:** substituição
- **CHK (segurar):** carregar chakra
- **DEF (segurar):** defender
- **LOCK:** ativar/desativar lock-on

## Como testar o combo aéreo
1. Trave no inimigo com **LOCK**.
2. Use **ATK** até o 4º golpe.
3. O 4º golpe terrestre lança o inimigo.
4. Aperte **DASH** enquanto ele está no ar para persegui-lo.
5. Use **ATK** no ar para continuar o combo.
6. O 4º golpe aéreo aplica o slam para baixo.

## Controles de teste no PC
- WASD: mover
- Mouse: câmera
- Tab: lock-on
- Clique esquerdo: ataque
- Q: chakra dash/perseguição
- E: jutsu
- F: substituição
- Alt: esquiva
- C segurado: carregar chakra
- R segurado: defender
- Shift: correr
- Espaço: pular

## Arquitetura de hitbox/hurtbox
O jogador e o inimigo usam `Area3D` separadas para ataque e dano. A hitbox só processa acertos durante uma janela curta aberta pelo golpe. Cada alvo só pode ser acertado uma vez por janela. As hitboxes do jogador e dos clones já acompanham mãos/pés do Skeleton3D após avaliação da pose.

## Combat Polish
O feedback de combate agora é disparado pelo acerto real da hitbox. Golpes no vazio não aumentam o contador nem acionam hit-stop.

- golpes normais: impacto curto
- defesa: impacto mais leve
- launcher: impacto e zoom maiores
- slam: impacto forte e ground bounce
- golpes fortes próximos da borda: wall bounce
- bounces prolongam brevemente a janela visual do combo

Os VFX usam meshes simples criadas em runtime, sem texturas ou sistemas pesados de partículas.

## Mobile
O Player usa o GLB rigado; o inimigo ainda usa o dummy original. VFX continuam simples. Clips são pré-bakeados: Android não precisa de Python, Blender, FBX ou download em runtime. As fontes ficam em uma pasta com `.gdignore` e não entram na exportação.

## Personagem rigado
O adapter procura `res://assets/characters/rigged.glb`.

O GLB analisado nesta etapa possui rig Mixamo, ossos de mãos/pés compatíveis com o sistema de hitbox e uma animação `happy` de aproximadamente 3 segundos. A hitbox do jogador passa a seguir os ossos `mixamorig:RightHand`, `mixamorig:LeftHand`, `mixamorig:RightFoot` e `mixamorig:LeftFoot` quando o rig está carregado.

O HUD mostra `RIG: OK` quando o asset foi importado corretamente. Sem o arquivo, o boneco procedural continua funcionando como fallback.

## Próximas melhorias
- refinar guarda sem escudo e movimentos autorais específicos de chakra/jutsu
- substituir variantes adaptadas de strafe/recuo por animações direcionais dedicadas
- avaliar desempenho e aparência em aparelhos Android reais
- refinar coreografia autoral de Rasengan/clones/Barrage
- seleção de personagem
- arena temática maior com obstáculos
- áudio de golpes, dash, chakra e jutsu
- validar os perfis LOW/MED/HIGH em celulares reais


## Fontes de animação pesquisadas

As decisões de animação e licenciamento estão documentadas em `docs/ANIMATION_SOURCES.md` e `THIRD_PARTY_NOTICES.md`.

## Validação e reprodução do bake

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/animation_contract.gd
```

O teste verifica os 27 clips, ossos/canais/quaternions, estados exatos, combo terrestre, launcher, combo aéreo/slam, interrupções, reinício de golpes, jutsu e KO/respawn. CI usa Godot **4.7.2**. A validação local foi feita nessa mesma versão, em modo headless; não substitui testes no renderer e em dispositivo Android.

Para regenerar após trocar o personagem ou ajustar os recortes (Python com `numpy` e `scipy`):

```sh
python tools/bake_combat_animations.py
```

Para revisar as silhuetas do mesh efetivamente deformado pelas poses avaliadas no AnimationTree (com `Pillow`):

```sh
godot --headless --path . --script res://tests/animation_contract.gd -- --dump-poses
python tools/preview_combat_poses.py
```

O preview é um render diagnóstico por CPU, não uma captura do renderer do jogo. Histórico auditado e limitações estão em `docs/ANIMATION_IMPLEMENTATION.md`.

## Vertical slice Storm 1 — Naruto, fase 1

Pesquisa, diferenças de versões e aproximações: [STORM1_COMBAT_REFERENCE](docs/STORM1_COMBAT_REFERENCE.md). Novos sistemas: movimento orbital analógico, câmera volumétrica suavizada, combo com buffer/confirm/cancel, dash rastreado com contato físico e recoil, guard meter/break, cargas de substituição com recarga, Demon Wind Bomb, Rasengan, clones roteirizados e Barrage confirmado. Recursos de terceiros: [ASSET_SOURCES](docs/ASSET_SOURCES.md).

### Novos controles

- Toque **DWB/RAS** para alternar o jutsu selecionado; **JUTSU** executa.
- **CLONE**: Charging Bullet no chão, Whirlwind Strike no ar.
- **BARR**: Naruto Uzumaki Barrage; só continua se o primeiro golpe acertar.
- PC: **1** seleciona Demon Wind, **2** seleciona Rasengan, **E** executa; **3** clones; **4** Barrage.
- Direção no terceiro golpe (após a introdução): baixo derruba, lateral afasta, alto lança; neutro termina em knockback. O buffer touch conserva a direção do comando.
- Aperte ATK durante recovery para buffer; DASH cancela golpes 1–3 somente após acerto e fechamento da janela ativa. Máximo duas perseguições por voo.

```sh
godot --headless --path . --script res://tests/storm_slice_contract.gd
```

[ANDROID_VALIDATION](docs/ANDROID_VALIDATION.md) contém a lista exata de observações no aparelho. Preset Android arm64 inclui o manifesto e exclui fontes/ferramentas/testes. Exportação APK necessita templates/SDK/assinatura no ambiente de exportação; nenhum segredo foi colocado no repositório. Renderer e landscape preservados.

Esta fase implementa a estrutura de gameplay com coreografias CC0 adaptadas e meshes temporárias. O modelo continua sendo o arquivo fornecido: não foi substituído por um Naruto comercial. A base de Ultimate/Nine-Tails e ferramentas descrita abaixo foi acrescentada. CPU rigada completa, áudio e outros personagens continuam nas fases seguintes. Não se considera concluído o acabamento visual fiel ao Storm 1 nem a medição de 60 FPS no aparelho.


## Naruto — Ultimate, Awakening e ferramentas

- **ULT** (PC 5): lança um clone físico após startup. Erro, cenário, invulnerabilidade e bloqueio não abrem cinematic; bloqueio que quebra guarda também não confirma. Após hit, toque **ATK** repetidamente no QTE: mínimo de quatro toques e pontuação maior que a CPU em 1 s; empate perde. O HUD mostra as duas pontuações e o tempo. O ritmo da CPU é independente dos inputs do jogador. Clones/finisher usam colisões reais; escape, interrupção, KO, watchdog e remoção de cena liberam câmera/controles/pools.
- **AWK** (PC 6 ou segurar CHK além do máximo com vida baixa): transformação vulnerável → modo de uma cauda temporário. Aura/cauda originais, multiplicadores sem alterar stats-base, chakra vermelho no Rasengan, Vermillion substitui o jutsu escolhido, resistência a ferramentas e wind wave. Término/KO restaura estado.
- **ITEM** (PC 7): alterna shuriken, ramen, food pills, kunai rain e bomb ball. Botão ao lado (PC 8) usa. Estoques finitos nos quatro itens; projéteis varridos e explosão por volume físico; ramen repõe chakra, pills concedem buff de 20 s.
- **MED/LOW/HIGH** no topo: alterna resolução 3D, sombras e orçamento de efeitos. Salvo em user://graphics.cfg. Pools, animações, timing e touch viewport não mudam. Perda de foco libera dedos/holds/filas.

O Ultimate está configurado em Resource próprio para reutilização futura. Esta é uma **implementação funcional adaptada**, ainda não a coreografia visual final do Handbook: lançamento/dogpile/corrente usam 3 clones e os clips CC0 existentes; poses de agarrar tornozelos/arremesso ainda faltam. QTE usa disputa mash touch contra CPU, sem modos command/spin nem Storm Gauge. Tempos, ritmo e regra de empate são balanceamento próprio, não frame data oficial. Interrupções recolhem clones da sequência responsável; o fim normal do jutsu deixa os ataques já liberados terminarem. Sealed Power não foi implementado: Handbook fica desabilitado durante Awakening para não substituir silenciosamente o Ultimate correto. Modo de uma cauda ainda requer modelo/combos/animações autorais próprios; aura/cauda não tornam o modelo fornecido um Naruto final. Não declarar Naruto completo ou Play Store pronto por estes testes.

```sh
godot --headless --path . --script res://tests/naruto_phase1_contract.gd
python -m unittest discover -s tests -p 'test_release_assets.py'
python tools/validate_release_assets.py
```

Exportação de desenvolvimento: `python tools/export_android.py --godot /caminho/godot --output build/dev.apk`. Publicação exige `--release` e passa pelo gate **antes** de iniciar Godot. O preset separado Android (Play Store) usa public_release/AAB; o plugin do editor recusa incluir payload quando o registro não está liberado, mesmo ao exportar diretamente pelo editor. Um backend pode gravar um container vazio com mensagem de erro: não é uma build publicável. Não desabilitar o gate para publicar assets sem autorização. Segredos de signing permanecem fora do Git.

Referências adicionais: [elenco](docs/STORM1_CHARACTER_ROSTER.md), [Mundo Shinobi](docs/STORM1_WORLD_REFERENCE.md), [Play Store](docs/PLAY_STORE_RELEASE_CHECKLIST.md). O pedido mais recente priorizou a aldeia: há agora um primeiro trecho autoral jogável, ligado à batalha existente. Ainda faltam o mapa completo/medido e o acabamento visual fiel ao Storm 1.

## Mundo Shinobi — primeiro trecho jogável

Toque **ALDEIA** no topo do combate (**F10** no PC). O personagem rigado explora ruas, telhados, praça, pontes e pontos de academia/ramen/ferramentas. Analógico + CORRER, PULO duas vezes, arraste para câmera, AÇÃO para conversar e MAPA para localizar objetivos. PC: WASD, Shift, Space, E, M.

- Instrutor na academia: aceitar percurso, recolher três pergaminhos por colisão física, retornar e receber 150 ryō uma vez.
- Ferramentas: pacote por 40 ryō, máximo 3; acrescenta uma bomba e uma food pill ao próximo treino.
- Treinador da praça: usa o mesmo `main.tscn` e combate/27 clips; vitória/derrota abre resultado, repetir ou voltar ao checkpoint. Primeira vitória concede 100 ryō.
- Save versionado em `user://world_save.json`: progresso, ryō, coletas, pacotes e posição. Saves futuros/inválidos são preservados; posição ocupada recupera no portão.
- LOW/MED/HIGH: distância de setores/NPCs, atualização de rig distante, resolução e sombras. Sem downloads runtime.

Geometria e colocação são originais do projeto: **não é o mapa comercial extraído, nem Konoha final 100% igual**. O modelo fornecido foi preservado e a CPU agora usa uma instância independente do mesmo rig com 27 clips; não há novos modelos finais de Naruto, Sasuke, Sakura ou Kakashi. Naruto Cannon/wall run, história e missões completas, interiores, streaming/LOD avançados e acabamento dos landmarks continuam pendentes.

```sh
godot --headless --path . --script res://tests/world_contract.gd
godot --headless --path . --script res://tests/world_flow_contract.gd
```

O [roteiro Android](docs/ANDROID_VALIDATION.md) detalha testes de toque, travessia, save e retorno. A [referência do mundo](docs/STORM1_WORLD_REFERENCE.md) separa evidências de Storm, implementação e lacunas.

### CPU humanoide: primeiro incremento

A CPU usa agora o modelo existente com AnimationTree independente, locomoção, guarda, dodge, hit/knockback e KO reais. Seu combo terrestre de quatro golpes usa startup/active/recovery do mesmo manifesto e hitboxes nas mãos/pés. Apenas contato sem bloqueio permite continuar dentro da janela de cancel; erro/bloqueio terminam em recovery, e hit/substituição/KO interrompem o ataque.

Decisões de aproximação, strafe e recuo têm atraso de 0,18–0,32 s e aleatoriedade própria. Guarda baixa incentiva recuo; guarda não segue mais a regra determinística de cada terceiro ataque. Esses valores são ajustes do projeto, não medidas oficiais do Storm. O alcance foi ajustado para haver contato físico, sem dano por distância.

Ainda não é a CPU Fighter completa: chakra, chakra dash, launcher/pursuit deliberados, jutsus, Ultimate, Awakening e perfis por personagem continuam pendentes. O visual usa o modelo fornecido, sem alegar ser um Naruto final. A validação inclui uma CPU ativa aproximando e acertando via sobreposição real, além dos contratos existentes.

### Dados de golpes e branches Storm 1

Combos/projétil Demon Wind agora usam Resources compartilháveis, preservando o manifesto de timing e os 27 clips reais. A direção do combo é escolhida após os dois golpes iniciais: neutro afasta, cima lança, baixo derruba e lateral repele. O buffer touch conserva a direção escolhida; quebra de guarda continua classificada como bloqueio para cancel. Impactos do jogador usam eventos de câmera configuráveis.

Referências e aproximações: [STORM_MOVES_DATA](docs/STORM_MOVES_DATA.md) e [matriz de personagens](docs/CHARACTER_IMPLEMENTATION_MATRIX.md). Este incremento não adiciona modelos comerciais nem completa todos os movesets de Storm/Jump Force.


Atualização de roster (2026-10-05): todos os 25 lutadores possuem dois ou mais jutsus selecionáveis. Sakura mantém Booby Trap física e ganhou Cherry Blossom Impact; Kakashi usa Raikiri/Fireball; Sasuke Fireball/Chidori. Os 24 não-Naruto recebem Ultimate e Awakening data-driven com VFX por elemento/estilo; Naruto mantém os controladores específicos. `JutsuDefinition`, `UltimateDefinition` e `AwakeningDefinition` separam dados de gameplay de coreografia. Os kits novos continuam marcados como OUR_APPROXIMATION até o passe específico de animação/VFX de cada personagem.

## Storm 1 — bridge de pesquisa de arquivos

A pesquisa recente encontrou ferramentas públicas que documentam XFBIN/nuccChunkBinary e o `CommandChartData.xfbin` do Storm 1. O projeto agora possui um pipeline próprio, sem vendorização de payload comercial:

- `tools/storm1_file_probe.py`: inventaria arquivos fornecidos localmente, hashes e assinaturas `NDP3/NTP3/CPK`;
- `tools/storm1_command_chart_bridge.py`: normaliza o JSON produzido pelo Command Chart Tool do NUNSMOD e preserva contexto numérico sem inventar significado;
- `docs/STORM1_FILE_PIPELINE.md`: fontes verificadas, limites e fluxo para converter descobertas em `AttackDefinition/JutsuDefinition/ProjectileDefinition`.

Uso rápido:

```sh
python tools/storm1_file_probe.py external/storm1_raw
python tools/storm1_command_chart_bridge.py command_chart.json build/research/storm1_command_chart.normalized.json
python -m unittest discover -s tests -p 'test_storm1_research_tools.py'
```

Arquivos brutos ficam em `external/storm1_raw/` e são ignorados pelo Git. O primeiro alvo é transformar dados verificáveis de Naruto em Resources já existentes, sem aplicar números desconhecidos como se fossem frame data oficial.


### Naruto base_basic animado em 3D

Abra `project.godot` no Godot 4.7.2 e execute com F6 em `main.tscn` para ir direto à arena, ou F5 para selecionar personagens e entrar no mundo. Naruto usa por padrão `assets/characters/base_basic/base_basic_pbr_rigged.glb`: modelo 3D com 65 ossos Mixamo, pesos de skin e os 27 clips reais já usados pelo combate. Seleção, jogador, CPU, clones e exploração usam o mesmo perfil.

As duas variantes rigadas têm 39998 triângulos e texturas de até 1024 px. Para usar o visual shaded, altere apenas `model_path` em `assets/characters/definitions/naruto.tres` para `res://assets/characters/base_basic/base_basic_shaded_rigged.glb`. Os GLBs estáticos originais foram preservados; os detalhes de preparação e limitações estão no [README dos modelos](assets/characters/base_basic/README.md).

O atlas 2.5D continua como alternativa: defina `visual_mode = "sprite_2_5d"` no mesmo Resource. Para reconstruir o atlas: `python tools/build_naruto_sprite_atlas.py "/caminho/para/Naruto.zip"` (requer Pillow). O teste de sprites ativa essa alternativa explicitamente; o teste de exportação valida o visual 3D padrão.

`tests/base_basic_visual_contract.gd` verifica a deformação real da skin nos 27 clips, modelos do jogador/CPU, independência dos clones, grounding, preview de seleção e exploração. Nenhum Python, rigging ou download é executado no aparelho.


## Identidade de combate do elenco — 2026-10-05

O roster agora possui uma camada de identidade além dos stats:

- `AIProfileDefinition` + `RosterAIProfileFactory`: os 25 lutadores têm arquétipo, distância preferida, agressividade, tendência de guarda/esquiva/strafe/jutsu/dash/Ultimate/Awakening e ritmo de decisão próprios. Gaara/Temari/Tenten jogam mais à distância; Lee/Guy/Kiba pressionam; Neji/Hinata/Kakashi defendem/reagem mais; Tsunade/Choji/Kisame buscam trocas pesadas.
- `RosterJutsuFactory.CLIP_MAP`: jutsus de desenvolvimento escolhem coreografias diferentes dentro da biblioteca de 27 clips existente. Isso melhora a silhueta de cada kit sem fingir que já existem animações finais exclusivas.
- `RosterVisualStyle`: projéteis, golpes de área e rushes usam formas, cores e movimento diferentes por estilo, misturados com a cor energética do personagem.
- Awakening dos 24 não-Naruto ganhou aura + MultiMesh orbital leve com 4/7/10 instâncias em LOW/MED/HIGH.
- O layout touch escala pela altura da viewport, herda a cor do personagem e remove CLONE/BARR nos lutadores que não usam essas ações.

A coreografia continua baseada nos 27 clips CC0 compartilhados; esses perfis não são animações comerciais reproduzidas. O próximo passe visual real é criar/retargetar animações e modelos específicos por personagem sem substituir a camada funcional já testável.
