# Seleção, arsenal CPU, áudio e orçamento mobile

2026-10-03 — Godot 4.7.2, Android landscape, gl_compatibility. Preservados o rig/27 clips, AnimationTree, combate e aldeia/save; não houve rebuild do projeto.

## Resultado implementado

- Boot → seleção com os **25 lutadores jogáveis do Storm 1**, preview 3D e CPU com qualquer slot do elenco → combate existente → resultado → revanche/seleção. Naruto/Sasuke/Sakura/Kakashi têm perfis visuais próprios; os outros 21 usam temporariamente o rig e combo-base compartilhados. Dois presets reutilizam geometria da arena atual e diferem na paleta/luz. Não são dois mapas finais de Storm. Treino da aldeia mantém sua recompensa/save e volta ao mundo.
- CharacterDefinition configura modelo, stats, moveset, jutsus e capabilities. Sasuke usa Fireball/Chidori e kick real no terceiro golpe; Naruto mantém seu arsenal. Capabilities desabilitam ULT/AWK/CLONE/BARR indisponíveis no touchscreen. Sakura tem melee pesado e Booby Trap (fio e bola de ferro); Kakashi usa Raikiri com parâmetros próprios e Fireball. Os 21 slots restantes entram sem jutsu/Ultimate/Awakening até receberem kits próprios; Gaara agora está selecionável como slot de desenvolvimento.
- CPU usa CombatSpecials, Ultimate, Awakening e NinjaTools compartilhados. Chakra/custo/recovery, dash com startup/accel/tracking/Area/recoil e perseguição aérea; charge; probabilidades com decisão atrasada, sem input reading. Jutsu/clones/Ultimate usam máscara do time. Clean entry inicia cinematic, block/miss não; ATK defende clash contra CPU; SUB e watchdog restauram câmera/controle. KO/revanche limpam pools e restauram hit-stop.
- OGG CC0: impactos, bloqueio, passos, energia/carga, dash e fumaça. Pool oito vozes SFX e um loop de carga, rate-limit, mute persistido, cleanup/pausa. Música/ambiente/vozes/coreografia sonora final ainda pendentes. Headless mantém banco/pool mas não toca stream em driver dummy; som real precisa teste no telefone.
- Elétrico autoral Chidori: 16 segmentos MultiMesh em uma draw, sem transparência. Fireball: shader de fluxo de fogo opaco + orb/trail existente; sem bloom obrigatório. LOW remove shell aditiva via orçamento existente; qualidade aplicada também aos efeitos CPU/projéteis existentes no setup.

## Custo e limites reais

Dados dos 27 clips, após reescrever caminhos relativos do skeleton, agora são compartilhados quando hierarquia/bones/rest transforms coincidem, mesmo com meshes diferentes. AnimationTree/playback continuam independentes. Clones já compartilham clips e mantêm pool limitado a três por Naruto. Sasuke não cria clones; CPU Naruto aquece seu pool uma vez ao precisar de clones/Ultimate (pode causar hitch de primeira utilização; medir no G22). HUD atualiza a cada 100 ms e mostra FPS/DC. Nenhuma regra de dano/colisão foi reduzida no LOW.

Não há medição de GPU/thermal/RAM/FPS Android nesta execução, nem AAB/APK instalável gerado. Headless/import/PCK não demonstram 60 FPS. Ainda é necessário profile no G22 para escolher mesh/material/LOD reductions; não atribuímos o print de 36 FPS a uma causa que não medimos.

## Não concluído

Polimento final dos quatro modelos próprios; modelos e movesets próprios para os outros 21 slots; coreografias exclusivas e sand system do Gaara; variantes/costumes; Ultimates/Awakenings individuais; sprites/áudio final; landmarks/interiores/NPCs/missões adicionais e wall-run na aldeia. A seleção identifica explicitamente os slots que ainda usam o rig compartilhado. O model_path está preparado para GLBs compatíveis fornecidos/autorizados; modelos extraídos de Storm não foram adquiridos.

## Validação

Contratos anteriores + selection_arsenal_contract: seleção/param inválido/viewport, resources/rig cache/playback independente, jutsu/custo/startup/mão/colisão Fireball, CPU dash/guard/Rasengan/interrupção, clone pool/time, Ultimate entry física/clash/SUB/câmera, Awakening/KO, vozes/cleanup, resultado durante hit-stop/revanche. Export payload isolado confere seleção/Sasuke/VFX/áudio e mundo; gate público continua fail-closed.

## Checklist Moto G22

1. SELEÇÃO: selecionar os quatro, jogador e CPU; verificar cabelo/roupa/rosto, idle/combo/launcher/KO, depois revanche; botões cabem e jutsu escolhido muda. ULT/AWK indisponíveis no Sasuke/Sakura/Kakashi ficam cinza; Sakura não habilita JUT.
2. FIRE/CHID: projétil bate em guarda/parede e desaparece; Chidori acompanha a mão, não tira HP ao errar; alternar jutsu funciona multitouch.
3. CPU: observar dash/recoil, charge/jutsu/clones, ULT quando tem recurso. No ULT dela, ATK disputa ou SUB escapa; câmera e controles voltam. Naruto com pouca vida/full chakra pode transformar.
4. RESULTADO: KO durante hit-stop; seleção/revanche sem tela presa, sons presos ou clones da luta anterior.
5. SOM: passos/impactos/bloqueio/carga/dash/fumaça, volume aceitável; SOM OFF permanece após reabrir; pausar app para loop parar.
6. FPS: cenário novo; LOW/MED/HIGH por 60 s, dois Narutos e vários clones/jutsus; anotar FPS/DC e hitch no primeiro clone. Repetir após 5 min para thermal. Conferir aldeia/save/treino continuam funcionando.

## Continuação: CPU observa projéteis

A CPU examina somente entidades lançadas no mundo, no tick de decisão atrasado existente. Ignora tiros do próprio time, reciclados, trajetórias que se afastam/passam ao lado, objetos além de 10 m e chegada prevista após 0.65 s. Ao perceber ameaça, há 30% de falha; pode guardar ou deslocar-se de lado com esquiva real/invulnerabilidade curta. Guarda baixa favorece esquiva. Não cancela hitstun/ataque e não lê input queue. Valores OUR_APPROXIMATION; varredura limitada aos pools da arena em ticks de decisão, sem criar nodes. CPU_THREAT_CONTRACT cobre trajetória, time, atraso/estado, probabilidades, recurso de guarda, invulnerabilidade contra sweep e cleanup. No Android: lançar FIRE/SHUR da média distância; CPU deve alternar guarda/esquiva e também tomar alguns tiros.

A continuação visual e suas limitações estão em [STYLIZED_PRESENTATION.md](STYLIZED_PRESENTATION.md).
