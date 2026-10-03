# Dados de movimentos: Storm / Jump Force → Godot

Pesquisa e implementação: 2026-10-03. Este é um incremento verificável, não uma base completa de frame data dos oito jogos. Storm 1 determina o comportamento padrão; diferenças de outros jogos não são aplicadas silenciosamente.

## Confiança e unidades

- `CONFIRMED`: documentação primária do produtor/ferramenta confirma o fato descrito; não implica um número oficial quando a fonte não o fornece.
- `COMMUNITY_RESEARCH`: guia, investigação de formatos ou banco comunitário; pode refletir uma build modificada.
- `VIDEO_ESTIMATE`: exige vídeo e intervalo de quadros identificáveis; nenhum timing recebeu essa classificação nesta sessão.
- `OUR_APPROXIMATION`: valor do nosso rig, animações ou balanceamento. Metros/segundos Godot, sem equivalência automática com unidades PRM/XML.

Campos ainda desconhecidos devem permanecer desconhecidos. Um `damage ID` não é diretamente HP; raio declarado não prova alcance efetivo, e contador de hits não mede startup/recovery.

## Fontes solicitadas: leitura e uso concreto

| Fonte | Evidência recuperada | Uso neste incremento / limite |
|---|---|---|
| [Storm 4 Character Manager](https://github.com/zealottormunds/ns4charactermanager) / `Tools/Tool_MovesetCoder.cs` | README separa PRM, spcload, códigos, costumes e roster; editor manipula seções de movimentos/animações | Separar seleção de moveset de reprodução do rig. Nenhum PRM comercial importado |
| [UNSME](https://github.com/zealottormunds/unsme) | README documenta edição de modelos, pesos, ossos e limites de grupos | Preserve Mixamo e retarget existente; editor não fornece um moveset de Naruto pronto/licenciado |
| [NSC Toolbox](https://github.com/TheLeonX/NSC-Toolbox) / `Model/SkillEditorModel.cs`, `Model/PRMEditorModel.cs`, `XfbinParser.cs` | Modelos expõem animação, listas de ações, hit radius/world radius, damage ID, intervalos; PRM distingue projétil/Skill, colisão por osso e desbloqueio de ação; parser lida com seções Nucc | `AttackDefinition`, `MovesetDefinition`, `ProjectileDefinition`; as nossas janelas continuam no manifesto real. Fonte técnica comunitária, sem conversão de escala/fps validada |
| [NSC Mod Manager](https://github.com/TheLeonX/NSC-ModManager) | Instala/combina categorias de mods e alterna jogos; árvore inclui modelos de parâmetros | Organização de categorias, não prova de algoritmos de reflect/homing. Essas funções ainda exigem investigação específica |
| [Generations competitive](https://unsgv2.com/competitive), [atlas](https://unsgv2.com/guide), [health pilot](https://unsgv2.com/health-pilot) | Índice público expõe Skill/Hit e alerta que unidades de raio/velocidade/argumentos não estão validadas | Separar evidência/escala e não transplantar raio bruto para Godot. Páginas completas excederam limite de leitura; sem extração integral ou valores exatos de Naruto nesta sessão |
| [Road to Connections](https://unsevolution.com/changelog-rtc/) | Changelog v1.12/2023: alterações em PRM, dash, itens, regeneração, awakening e segundo jutsu; adapta Storm 4 | `COMMUNITY_RESEARCH`, não patch oficial nem frame data Storm 1. Não adotar seus custos/durações como universais |
| [Jump Force tools](https://github.com/tge-was-taken/jumpforce-tools) / `templates/jumpforce_anm.bt` | Template descreve duração e controladores de ossos, anexos, câmera/FOV e chaves PRS | Eventos de câmera separados dos golpes; não há tabela completa de habilidades/frame data no README/template lido |
| [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) | Ferramenta genérica UE4/5 de inspeção/reflexão/scripting, MIT | Não é biblioteca Godot nem prova de compatibilidade automática com toda versão de Jump Force. Nenhuma injeção/dump executado |
| [Unverum](https://github.com/TekkaGB/Unverum) | README inclui Jump Force, organiza mods e prioridade; licença GPL-3.0 | Gerenciador, não catálogo de golpes. Não incorporado ao runtime Android |

Snapshot das árvores consultadas: Character Manager e Toolbox/ModManager via `HEAD`; ModManager `276116ebf5ba398a867793cb02ee6c33c0927645` (tree), UNSME `68fb4869549194ce33da507fca01297f134c6032`, Jump Force tools `0987c28912c6435cc64a30483833ba2e1daff1fa`, Unverum `e41b135e8900187b9a7a06f52bf723f4a7ba35e1`. Esses são IDs de árvore, não necessariamente commits. Não foi encontrada licença raiz nas árvores consultadas de Character Manager/UNSME/Toolbox/ModManager/Jump Force tools; leitura pública não autoriza copiar o código inteiro. Nenhum código dessas ferramentas ou asset comercial foi vendorizado.

## Comparação de Naruto e decisões implementadas

| Sistema | Antes | Referência / confiança | Agora / arquivo |
|---|---|---|---|
| Direção de combo | Escolhida no golpe 1 | [Guia Storm 1 Ashurii](https://gamefaqs.gamespot.com/ps3/943434-naruto-ultimate-ninja-storm/faqs/54852): direção depois dos primeiros golpes, `COMMUNITY_RESEARCH` | Escolha no início do golpe 3; direção do buffer preservada no touch. `player_controller.gd`; instante exato é `OUR_APPROXIMATION` |
| Neutro | Quarto golpe lançava verticalmente | Mesmo guia: neutro afasta, cima lança, baixo derruba, lateral abre extensão com suporte | Neutro afasta; cima +8.5; baixo −4; lateral +2/knockback 10. Sem sistema de suporte ainda. `naruto_moveset.tres` |
| Dados de ataque | Arrays e condicionais no controlador | Ferramentas distinguem animação/colisão/ação, `COMMUNITY_RESEARCH` | Resource compartilhado por jogador/CPU; dano, stun, impulso, animação e câmera. Timing deriva do manifesto dos 27 clips |
| Guarda quebrada | Estado de guarda após dano podia confirmar cancel | Regra do nosso hit-confirm exige contato sem bloqueio | Snapshot anterior ao dano passa pelo callback da hitbox; quebra continua sendo bloqueio para confirmação. Teste dedicado |
| Demon Wind | Constantes no script | Separação projétil/Skill nos modelos técnicos | Resource controla velocidade, raio, tracking, vida, dano, impulso/stun/spin. Sweep físico/pool/hit-confirm existentes preservados |
| Impacto neutro | Feedback leve genérico | Finalizador deve comunicar knockback; sem medição visual oficial | Evento de câmera próprio: shake .14, FOV kick 3, hit-stop .05; `OUR_APPROXIMATION`. Continua com flash pooled existente |
| Rasengan | Área na mão, tracking, camadas/trail e recovery já implementados | Storm 1 tem Rasengan carregável; [moveset comunitário](https://naruto-ultimate-ninja-storm.fandom.com/wiki/Naruto_Uzumaki_(Part_1)/Move_List) | Não foi alterado para inventar a duração da carga. Variante carregável e coreografia própria continuam pendentes |
| Ultimate | Handbook adaptado + QTE | Storm 1 distingue Handbook/Sealed Power; jogos posteriores têm outros Ultimates | Preservado; ainda sem coreografia exata nem Sealed Power. Não substituir pelo Ultimate de Naruto adulto |

## Números efetivamente usados no Godot

Todos os números abaixo são `OUR_APPROXIMATION`; timings vieram do bake CC0, não de assets/frame data do Storm. Os finalizadores continuam usando o clip retargetado `attack_4`: kick/dropkick/clones do moveset original ainda precisam de animações próprias.

| Ataque | Startup / ativo / recovery (s) | Dano | Knockback | Lift | Hitstun |
|---|---|---|---|---|---|
| Ground 1 | .12 / .09 / .07 | 7 | 1.8 | 0 | .18 |
| Ground 2 | .14 / .09 / .07 | 8 | 2.4 | 0 | .18 |
| Ground 3 | .10 / .09 / .15 | 10 | 3 | 0 | .18 |
| Ground 4 neutro | .12 / .09 / .19 | 16 | 8 | 0 | .38 |
| Ground 4 cima | mesmo clip | 16 | 5 | 8.5 | .38 |
| Ground 4 baixo | mesmo clip | 16 | 5 | −4 | .65 |
| Ground 4 lateral | mesmo clip | 16 | 10 | 2 | .38 |
| Air 4 | manifesto `air_attack_4` | 16 | 5 | −13 | .42 |
| Demon Wind | startup do jutsu .24 | 10 | 2 | 1 | .65 |

Demon: velocidade 19 m/s, raio .45 m, vida 1.6 s, tracking 1.8/s. Custos de chakra/cooldown foram migrados a JutsuDefinition; não são atribuídos ao formato original. Cancel windows ficam no manifesto e exigem confirmação; anti-infinito/pursuit budget existentes foram preservados.

## Separar as versões dos jogos

- **Storm 1:** guia/moveset comunitários sustentam as diferenças implementadas acima; substituição por quatro cargas permanece adaptação solicitada, não fidelidade literal ao timing de guarda original.
- **Storm 2:** ainda sem comparação específica de Naruto/frame data nesta sessão; não reutilizar automaticamente o Naruto Part 1 como adulto.
- **Generations:** atlas técnico parcial; raio/action/slot ≠ comportamento runtime medido. Ainda sem extrair sequência completa de Naruto.
- **Storm 3 / Revolution / Storm 4:** a página de moveset Part 1 separa essas versões do Storm 1. [Revolution oficial](https://en.bandainamcoent.eu/naruto/naruto-shippuden-ultimate-ninja-storm-revolution) confirma golpes combinados; isso não torna suporte/Team Ultimate implementado aqui.
- **Connections:** [patch oficial 1.20](https://en.bandainamcoent.eu/naruto/news/naruto-x-boruto-ultimate-ninja-storm-connections-patch-120-notes), `CONFIRMED`: altera rotação do Charging Bullet de Naruto Tailed Beast Bomb e recuperação de substituição dependente de FPS. Sem valores de tracking absolutos; não aplica automaticamente à versão Part 1. Timers daqui já usam delta em segundos.
- **Jump Force:** [guia oficial Bandai](https://www.bandainamcoent.com/pt_br/news/jump-force-tips), `CONFIRMED`: quatro habilidades por lutador, recursos compartilhados no trio, gauge de Awakening distinto. Não misturar esse sistema com chakra/HP separados do nosso Storm 1. Template ANM informa estrutura de câmera, não poses/timing de Rasengan específicos.

## Próximas lacunas verificáveis

Grab, Ultimate Impact carregado e Rasengan carregável; Ninja Move/jump cancel; suporte/Storm Gauge; clone dentro das branches terrestres; novas animações; prioridade/armor/reflect; formas próprias de Naruto adulto; medições de vídeo identificadas por jogo/build/quadros. `CharacterDefinition`, jutsus/Awakening completamente orientados a dados e perfis de CPU ainda requerem migração progressiva. Não declarar Naruto completo ou cópia 100% por este incremento.

## Sasuke Part 1 — base selecionável (2026-10-03)

Referência de comunidade: [FAQ de Ashurii, Storm 1](https://gamefaqs.gamespot.com/xboxone/218500-naruto-ultimate-ninja-storm/faqs/54852), seção Sasuke. COMMUNITY_RESEARCH: Fireball é jutsu padrão, Phoenix Flower e Chidori possuem desbloqueio/condição de costume; Awakening depende de roupa (Curse Mark/Sharingan), e não de um Susano'o genérico de versões posteriores.

Implementação OUR_APPROXIMATION: perfil de desenvolvimento reúne Fireball/Chidori para testar ambos; não aplica ainda desbloqueio/costumes. Fireball: speed 17 m/s, raio 0.5 m, vida 1.8 s, tracking 0.65/s, dano 20, knockback 8, lift 1, stun 0.45 s. Chidori: utiliza clip real disponível Rasengan, startup 0.38 s, active até 0.68 s, recovery até 0.95 s; Area na mão, aproximação 13 m/s, custo 32. Timings/danos não são oficiais. A biblioteca de 27 clips não ganhou coreografias comerciais neste incremento.

Diferenças implementadas: CharacterDefinition seleciona stats/moveset/jutsus/model_path; terceiro golpe Sasuke usa kick real air_attack_2, com bone/timing do clip escolhido. Ultimate/Awakening Naruto são bloqueados no perfil Sasuke. Fireball não transporta o corpo nem cria clones como Demon Wind. Elétrico usa MultiMesh autoral de 16 segmentos opacos; Fireball usa shader opaco de fogo, sem exigir bloom.

CPU: os módulos reais dos jutsus, Ultimate, Awakening e tools foram compartilhados. Máscaras de time passam a depender do source. CPU atacante no clash gera seus próprios comandos por RNG/tempo; ATK do jogador alimenta somente a defesa e SUB pode escapar. Decisões não leem filas/input do jogador; valores de chance e reação são OUR_APPROXIMATION.


## Sakura e Kakashi — jutsus próprios (2026-10-03)

COMMUNITY_RESEARCH: o [guia de Ashurii, Storm 1 PS3](https://gamefaqs.gamespot.com/ps3/943434-naruto-ultimate-ninja-storm/faqs/54852) identifica Booby Trap como jutsu padrão de Sakura; Kakashi tem Lightning Blade e Fireball como alternativa desbloqueável. A [observação pública contemporânea de Booby Trap](https://gamefaqs.gamespot.com/boards/943434-naruto-ultimate-ninja-storm/46035411) descreve fio no chão seguido de bola com espinhos. Os nomes não confirmam números runtime.

Implementado: Sakura solta fio entre duas kunai após impacto do clip `jutsu` (0.24 s); interseção de hurtbox ativa uma bola que cai de posição fixa, com sweep contra cenário/hurtboxes. Não há dano por distância. Guarda aplica chip/guard damage; invulnerabilidade/sub e esquiva podem evitar contato. Três traps reutilizados por lutador, expiração e cleanup em KO/saída. OUR_APPROXIMATION: custo 24, cooldown 1.5 s, vida 10 s, fio 2.4 m, queda 22 m/s, raio 0.65, dano 16, knockback 3, slam -8, stun .65 s, aviso .12 s. A bola/kunai são geometria autoral temporária; clip é CC0 adaptado, não coreografia final.

Kakashi Raikiri: Resource distinto do Chidori de Sasuke, embora ambos ainda utilizem o mesmo clip CC0 real disponível. Startup .38 s, active .30 s, recovery .27 s vêm do manifesto do bake. OUR_APPROXIMATION: custo 32, cooldown 1.5 s, velocidade 15 m/s, tracking 5.5/s, dano 24, knockback 9, lift 2, stun .55 s. Mantém hitbox na mão e elétrico MultiMesh. Fireball reutiliza o módulo físico e dados já testados, sem abrir clones ou Demon Wind.

Arquivos: `scripts/jutsu_definition.gd`, `assets/combat/jutsus/*.tres`, `CharacterDefinition.find_jutsu`, `scripts/combat_specials.gd`, `scripts/booby_trap.gd`. Todos os IDs dos quatro perfis possuem dados; states/pools/timers permanecem separados por lutador. Naruto/Sasuke mantêm parâmetros anteriores. Ultimates/Awakenings de Sakura/Sasuke/Kakashi continuam desabilitados: não emprestar golpes de Naruto.

Validação: `tests/character_jutsus_contract.gd` exercita release/interrupção, contato real, miss, guarda/invulnerabilidade, pool cheio, expiração, parede, KO, Resource/máscara CPU e Fireball alternativo. Android: testar Sakura JUT, tocar fio com CPU, esquivar da queda, guardar, repetir três vezes; Kakashi alternar RAI/FIRE; comparar FPS LOW com traps + dois rigs. Sem medição física de FPS nesta sessão.

## Storm 1 — formatos e CommandChartData (2026-10-03)

Nova pesquisa técnica confirmou no código público do [NUNSMOD](https://github.com/roqols/NUNSMOD) que o `CommandChartData.xfbin` contém `nuccChunkBinary` separados por personagem. O próprio `command_chart_tool.py` fornece como exemplos `cmd1nrt` para Naruto e `cmd1ssk` para Sasuke e descreve os payloads como uma sequência de `uint32` big-endian e strings UTF-8. Classificação: `COMMUNITY_RESEARCH`.

Isso **não identifica automaticamente** os inteiros como dano, startup, raio ou chakra. O novo `tools/storm1_command_chart_bridge.py` conserva texto, índice e inteiros vizinhos para que o significado seja validado antes de alimentar Resources do Godot.

O parser XFBIN incluído no mesmo projeto documenta chunks CyberConnect2 e, no modo data-only, cita `NTP3` para `.nut` e `NDP3` para `.nud`. O [NUNS Meshswap Tool](https://github.com/Lyingcake77/NUNS_Meshswap_tool) também procura blocos `NDP3`, reforçando a pista de pesquisa de mesh/modelo. Isso é informação de formato, não licença para assets do jogo.

O mod [Storm 1 PS Icons](https://github.com/AkikoKumagara/Naruto-STORM-1-PS-Icons) confirma a árvore PC `data_win32/interface` com áreas `adv`, `battle`, `battle_mode`, `cmn` e `title_option`. Usar essa organização como referência para decompor HUD/telas; nenhuma textura do mod foi copiada.

Pipeline e comandos: [STORM1_FILE_PIPELINE](STORM1_FILE_PIPELINE.md). Quando houver um `CommandChartData.xfbin` fornecido pelo usuário, Naruto é a primeira extração alvo; só depois de identificar semanticamente cada campo os valores podem migrar para `naruto_moveset.tres` ou jutsus.
