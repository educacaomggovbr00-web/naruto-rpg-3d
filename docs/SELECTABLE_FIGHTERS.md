# Seleção, arsenal CPU, áudio e orçamento mobile

2026-10-03 — Godot 4.7.2, Android landscape, gl_compatibility. Preservados o rig/27 clips, AnimationTree, combate e aldeia/save; não houve rebuild do projeto.

## Resultado implementado

- Boot → seleção real Naruto/Sasuke base, CPU Naruto/Sasuke e arena → combate existente → resultado → revanche/seleção. Dois presets reutilizam geometria da arena atual e diferem na paleta/luz. Não são dois mapas finais de Storm. Treino da aldeia mantém sua recompensa/save e volta ao mundo.
- CharacterDefinition configura modelo, stats, moveset, jutsus e capabilities. Sasuke usa Fireball/Chidori e kick real no terceiro golpe; Naruto mantém seu arsenal. Capabilities desabilitam ULT/AWK/CLONE/BARR indisponíveis no touchscreen. Sakura/Kakashi/Gaara ficam indisponíveis, sem falsos clones de Naruto declarados como personagens completos.
- CPU usa CombatSpecials, Ultimate, Awakening e NinjaTools compartilhados. Chakra/custo/recovery, dash com startup/accel/tracking/Area/recoil e perseguição aérea; charge; probabilidades com decisão atrasada, sem input reading. Jutsu/clones/Ultimate usam máscara do time. Clean entry inicia cinematic, block/miss não; ATK defende clash contra CPU; SUB e watchdog restauram câmera/controle. KO/revanche limpam pools e restauram hit-stop.
- OGG CC0: impactos, bloqueio, passos, energia/carga, dash e fumaça. Pool oito vozes SFX e um loop de carga, rate-limit, mute persistido, cleanup/pausa. Música/ambiente/vozes/coreografia sonora final ainda pendentes. Headless mantém banco/pool mas não toca stream em driver dummy; som real precisa teste no telefone.
- Elétrico autoral Chidori: 16 segmentos MultiMesh em uma draw, sem transparência. Fireball: shader de fluxo de fogo opaco + orb/trail existente; sem bloom obrigatório. LOW remove shell aditiva via orçamento existente; qualidade aplicada também aos efeitos CPU/projéteis existentes no setup.

## Custo e limites reais

Dados dos 27 clips, após reescrever caminhos relativos do skeleton, agora são compartilhados quando modelo/hierarquia/bones coincidem. AnimationTree/playback continuam independentes. Clones já compartilham clips e mantêm pool limitado a três por Naruto. Sasuke não cria clones; CPU Naruto aquece seu pool uma vez ao precisar de clones/Ultimate (pode causar hitch de primeira utilização; medir no G22). HUD atualiza a cada 100 ms e mostra FPS/DC. Nenhuma regra de dano/colisão foi reduzida no LOW.

Não há medição de GPU/thermal/RAM/FPS Android nesta execução, nem AAB/APK instalável gerado. Headless/import/PCK não demonstram 60 FPS. Ainda é necessário profile no G22 para escolher mesh/material/LOD reductions; não atribuímos o print de 36 FPS a uma causa que não medimos.

## Não concluído

Modelos/retratos finais de Naruto/Sasuke/Sakura/Kakashi/Gaara; coreografias exclusivas e sand system; variantes/costumes; Ultimate/Awakening Sasuke; sprites/áudio final; landmarks/interiores/NPCs/missões adicionais e wall-run na aldeia. A seleção identifica explicitamente o rig compartilhado como desenvolvimento. O model_path está preparado para GLBs compatíveis fornecidos/autorizados; modelos extraídos de Storm não foram adquiridos.

## Validação

Contratos anteriores + selection_arsenal_contract: seleção/param inválido/viewport, resources/rig cache/playback independente, jutsu/custo/startup/mão/colisão Fireball, CPU dash/guard/Rasengan/interrupção, clone pool/time, Ultimate entry física/clash/SUB/câmera, Awakening/KO, vozes/cleanup, resultado durante hit-stop/revanche. Export payload isolado confere seleção/Sasuke/VFX/áudio e mundo; gate público continua fail-closed.

## Checklist Moto G22

1. SELEÇÃO: Naruto vs Sasuke, depois inverso; botões cabem e jutsu escolhido muda. ULT/AWK indisponíveis no Sasuke ficam cinza.
2. FIRE/CHID: projétil bate em guarda/parede e desaparece; Chidori acompanha a mão, não tira HP ao errar; alternar jutsu funciona multitouch.
3. CPU: observar dash/recoil, charge/jutsu/clones, ULT quando tem recurso. No ULT dela, ATK disputa ou SUB escapa; câmera e controles voltam. Naruto com pouca vida/full chakra pode transformar.
4. RESULTADO: KO durante hit-stop; seleção/revanche sem tela presa, sons presos ou clones da luta anterior.
5. SOM: passos/impactos/bloqueio/carga/dash/fumaça, volume aceitável; SOM OFF permanece após reabrir; pausar app para loop parar.
6. FPS: LOW/MED/HIGH por 60 s, dois Narutos e vários clones/jutsus; anotar FPS/DC e hitch no primeiro clone. Repetir após 5 min para thermal. Conferir aldeia/save/treino continuam funcionando.

## Continuação: CPU observa projéteis

A CPU examina somente entidades lançadas no mundo, no tick de decisão atrasado existente. Ignora tiros do próprio time, reciclados, trajetórias que se afastam/passam ao lado, objetos além de 10 m e chegada prevista após 0.65 s. Ao perceber ameaça, há 30% de falha; pode guardar ou deslocar-se de lado com esquiva real/invulnerabilidade curta. Guarda baixa favorece esquiva. Não cancela hitstun/ataque e não lê input queue. Valores OUR_APPROXIMATION; varredura limitada aos pools da arena em ticks de decisão, sem criar nodes. CPU_THREAT_CONTRACT cobre trajetória, time, atraso/estado, probabilidades, recurso de guarda, invulnerabilidade contra sweep e cleanup. No Android: lançar FIRE/SHUR da média distância; CPU deve alternar guarda/esquiva e também tomar alguns tiros.
