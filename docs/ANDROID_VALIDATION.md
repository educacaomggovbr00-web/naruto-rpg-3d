# Validação no Android — fase Storm 1

Engine alvo: Godot 4.7.2, gl_compatibility, landscape, 60 FPS como meta (não medido nesta máquina). Atualizar main e reimportar; preset Android inclui JSON. Pacote PCK Android exportado e executado headless separadamente, com manifesto/rig e sem fontes/testes. O APK não foi produzido nesta sessão: SDK/templates/assinatura/aparelho não foram disponibilizados.

## Testes automáticos

Importação sem parser errors; contrato de 27 clips (130 canais, quaternions e poses) e contrato da fase Storm (movimento, confirms, dash, guarda, projétil, Rasengan, clones e Barrage). CI executa os três contratos na versão fixada e testes do gate de release. Hit-stop é desabilitado somente na suíte da fase para assertions de tempo determinísticas; permanece habilitado no jogo e no contrato anterior.

## Roteiro no aparelho

| Ação | O que observar |
|---|---|
| LOCK, joystick lateral/baixo, correr e pular | Orbitar sem virar as costas; intensidade do stick controla velocidade; comparar deslizamento dos pés (clips direcionais ainda adaptados) |
| Afastar lutadores, circular perto das quatro paredes | Dois corpos visíveis; distância/FOV graduais; câmera não entra nas paredes nem oscila sem impacto |
| ATK ×2, direção alto/baixo/lateral ao terceiro | Neutro afasta; alto lança, baixo derruba, lateral afasta; sem dano quando o braço passa longe |
| ATK durante recovery; DASH após acerto e após erro | Entrada pode ficar em buffer; whiff não cancela; contato com guarda dá recoil; dash fecha ao tocar e ATK continua |
| Launcher → DASH → aéreo → slam | Tracking acompanha altura; duas perseguições máximas no mesmo voo; CPU recupera de cadeias longas |
| DEF contra vários golpes e soltar | Meter desce, bloqueio tem feedback azul, esgotamento causa stun; meter recupera após pausa |
| SUB durante combo, perto da parede | Fumaça e breve desaparecimento; surge atrás do alvo sem sair da arena; cargas voltam de uma em uma |
| Selecionar DWB e JUTSU a média distância | Clone lançador, fūma giratório, personagem representado pelo projétil, colisão e golpes com clones após confirm; erro/parede não causa dano |
| Selecionar RAS e JUTSU | Núcleo com fluxo, camada externa e órbitas acompanham mão direita; corrida aproxima sem atravessar cenário; fora da trajetória não acerta; ataque interrompido dissipa |
| CLONE no chão e no ar | Duas cópias rigadas, golpes escalonados, fumaça ao sair; interromper com SUB antes do golpe deve recolher clones e impedir acerto atrasado; observar se punhos encostam no alvo e se poses/interseções precisam de ajuste |
| BARR perto do alvo, longe e contra defesa | Só acerto limpo inicia sequência; clone lança, intermediário e slam; erro/bloqueio não abre câmera; SUB/KO restaura controles |
| Repetir especiais por dois minutos | Sem crescimento de clones/efeitos, sem objetos esquecidos, sem erro de log; observar aquecimento e FPS |

Registrar modelo do aparelho, FPS mínimo durante 3 clones/Rasengan/trails, atraso de toque e vídeo curto de qualquer golpe que pareça sem contato. Poses foram inspecionadas via render CPU, não captura OpenGL do Android.

## Limitações deliberadas desta fase

Rig/modelo existente preservado. Golpes da mão substituem provisoriamente chutes específicos; Rasengan usa cross adaptado; guarda/shield e spell gestures ainda precisam de acabamento. A CPU já usa o rig existente e clips reais; chakra/dash/jutsus/Ultimate próprios ainda estão pendentes. A base de ferramentas/Ultimate/Awakening está implementada, com as limitações abaixo; áudio/outros personagens e moveset completo da CPU permanecem pendentes.


## Novos testes no aparelho

| Ação | O que observar |
|---|---|
| ULT a média distância e ATK repetidamente | Clone lançado conecta antes da cinematic; QTE mostra VOCÊ/CPU/tempo: vencer exige mínimo 4 e mais toques que CPU, empate perde; dogpile/corrente/finalizador; controle e câmera voltam. Repetir errando, contra DEF, usando SUB e perto da parede |
| Vida ≤30%, encher CHK e continuar segurando / AWK | Transição interrompível, aura deixa modelo visível, uma cauda, velocidade/dano maiores, Rasengan vermelho; após 18 s volta ao normal sem buff acumulado |
| ITEM → botão do item: SHUR/RAMEN/PILL/KUNAI/BOMB | Quantidades/CD, shuriken/projéteis bloqueados por cenário, bomba atinge apenas seu volume; ramen repõe chakra, buff expira |
| LOW → MED → HIGH com Rasengan/clones | Touch continua nítido/na posição; LOW reduz sombras/camada externa; comparar FPS/temperatura. HUD não deve cobrir QTE ou botões |
| Minimizar e voltar durante CHK/DEF/joystick | Não continuar carregando, defendendo ou andando por dedo preso |

Não houve inspeção do shader em GPU Android nem medição de FPS nesta sessão. Headless validou a estrutura e recursos carregados; núcleo/shell/cauda precisam de avaliação visual no aparelho. Handbook usa a coreografia adaptada e limitada a três clones, não a sequência comercial final. Awakening ainda usa combos do rig existente e não implementa Sealed Power. A aldeia agora tem um primeiro trecho autoral jogável; ainda não reproduz o layout completo/visual do Storm.

## Aldeia — teste no aparelho

1. Toque **ALDEIA** no topo do combate. Ande na avenida; segure **CORRER**, arraste a câmera e use **PULO** duas vezes. Os dedos devem funcionar simultaneamente.
2. Abra **MAPA**. Movimento deve parar; feche e retome. Visite a **academia ao norte**, fale com o instrutor usando **AÇÃO** e aceite o percurso.
3. Recolha os três pergaminhos marcados no mapa. Escadas a oeste do telhado sul e da academia devem permitir subida sem travar; use salto duplo para o telhado leste. Volte ao instrutor: **150 ryō**, sem recompensa duplicada.
4. Visite **FERRAMENTAS**, compre um pacote, fale com o **TREINADOR** na praça. Combate deve ter uma bomba/food pill extra. Vença ou perca: resultado → voltar/repetir; câmera, controles e posição devem retornar corretamente.
5. Minimize durante joystick/corrida, volte e reinicie o aplicativo. Dedos não devem ficar presos; pergaminhos, dinheiro, missões e pacotes devem permanecer. Toque ALDEIA para retornar ao mundo após reiniciar.
6. Alterne **LOW/MED/HIGH**, percorra do portão à academia e rode a câmera perto das fachadas. Observar FPS mínimo, aquecimento, tempo de entrada/saída, pop-in dos setores/NPCs e câmera atravessando paredes.

Registrar aparelho, perfil gráfico, FPS mínimo, tempo de transição e vídeo de travas/interseções. Não foi executada GPU Android, AAB/APK nem captura de performance nesta sessão. O mapa é um primeiro trecho autoral, NPCs usam o modelo existente e a CPU ainda não é o lutador humanoide final.

## CPU humanoide: validar no aparelho

- Confirmar os dois modelos animados ao entrar na arena e no treino pela aldeia.
- Parado perto da CPU, observar aproximação e golpes com contato; afastado, não perder HP por distância.
- Defender o primeiro golpe: a CPU deve encerrar a sequência; deixar acertar: ela pode continuar os quatro golpes.
- Interromper com golpe/SUB, aplicar launcher/slam e KO: verificar reação, fechamento das hitboxes e reinício.
- Medir FPS com dois rigs, clones e Rasengan nos perfis LOW/MEDIUM/HIGH; enviar vídeo se houver pé deslizando ou golpes sem contato aparente.


## Sakura rigada + resolução adaptativa — 2026-10-04

Quando `assets/characters/sakura_user/sakura_mobile_rigged.glb` estiver instalado:

1. Na seleção, escolha Sakura como jogador e CPU. Confirmar textura rosa/vermelha, escala semelhante aos demais lutadores e pés apoiados no chão.
2. Andar/correr por 20 s: Idle/Run nativos devem assumir a locomoção; ataques, guarda, hit, dodge e especiais continuam usando os 27 clips de combate.
3. Executar ATK ×4, combo aéreo, DEF, ESQ e TRAP. Punhos/pés precisam continuar alinhados às hitboxes apesar do rig compacto de 27 bones.
4. Repetir Sakura vs Naruto com MED e HIGH por dois minutos. A resolução 3D pode cair gradualmente se o FPS ficar abaixo de 48 e deve recuperar lentamente acima de 57; HUD/touch permanecem na resolução nativa.
5. Fazer o mesmo na aldeia. Observar pop-in, câmera e aquecimento enquanto a resolução adaptativa atua apenas no 3D.

O GLB recebido tinha ~35,7 mil triângulos e três texturas 2048. A variante mobile mantém mesh/skin/animações e reduz as texturas para 1024, caindo de 13,6 MB para ~4,37 MB. Isso ainda não substitui medição real de GPU/temperatura no aparelho.


## Roster completo — identidade e performance — 2026-10-05

1. Testar pelo menos Gaara, Rock Lee, Neji, Shikamaru, Temari, Itachi e Kisame como jogador e CPU. Confirmar que a CPU muda de spacing: zoners recuam/strafeiam, rushdown aproxima e counter guarda/esquiva com mais frequência.
2. Alternar os dois jutsus de cada um. Confirmar mudança de pose/coreografia e silhueta do VFX; nenhum golpe deve causar dano por distância sem hitbox/projétil.
3. Ativar Ultimate e Awakening dos personagens não-Naruto. Ultimate só deve continuar após entry hit físico; Awakening precisa mostrar aura/accent sem esconder o modelo.
4. Comparar LOW/MED/HIGH durante Awakening: orbitais devem reduzir para 4/7/10 instâncias sem alterar hitbox/timing.
5. Em telas 16:9 e mais largas, confirmar que a faixa avançada não sobrepõe ATK/JUTSU/joystick. Personagens sem clones não devem mostrar CLONE/BARR; Naruto deve mantê-los.
6. Rodar duas lutas de 2 minutos em MED com efeitos intensos (Gaara/Temari/Kisame) e duas de rushdown (Lee/Guy/Kiba). Registrar FPS mínimo, temperatura, input lag e qualquer queda visual.

Essas validações precisam de aparelho real; headless garante contratos de dados/runtime, mas não mede GPU, thermal throttling nem latência do touchscreen.


## Visuais procedurais — teste Android — 2026-10-05

1. Na seleção, percorrer os 21 slots compartilhados e confirmar mudança visível de paleta/silhueta; nenhum acessório deve ficar parado na origem.
2. Testar Gaara, Temari, Kisame, Tenten, Kabuto, Jiraiya, Itachi e Kimimaro em corrida, dodge, combo aéreo, jutsu e KO. Cabaça/leque/espada/cabelo/coques/óculos/manto/espinhos devem acompanhar o corpo sem "voar".
3. Rodar Gaara vs Temari e Kisame vs Lee em LOW/MED/HIGH por dois minutos. Verificar FPS e clipping; acessórios têm sombra desligada e não podem alterar colisão/dano.
4. Abrir aldeia com um slot compartilhado e confirmar que a mesma identidade visual aparece fora da arena.
5. Se um acessório atravessar demais o corpo, registrar personagem + ação + vídeo; offsets podem ser ajustados sem trocar rig ou combate.

Essa camada não é modelo final. O objetivo deste teste é validar legibilidade, estabilidade dos bone-followers e custo mobile antes de substituir cada slot por um GLB próprio.
# Passe de gameplay — 2026-10-08

- Seleção: entrar em Versus, Treinamento e Sobrevivência em Fácil/Normal/Difícil.
- Treino: alternar dummy parado/defender/lutar em AJUSTES; esgotar chakra, completar combo, causar KO; conferir reposição sem gastar itens da campanha.
- Sobrevivência: vencer com metade da vida, avançar, conferir aproximadamente 70% de vida no duelo seguinte; perder, recomeçar e conferir recorde após reiniciar o app.
- Combate: NINJA → AGARR contra DEF; testar erro fora de alcance, esquiva, interrupção e cooldown. Levantar DEF no impacto e conferir DEFESA PERFEITA sem dano automático.
- Controles: combinar joystick + ATK + DEF/CHK; ajustar escala/opacidade e sensibilidade; minimizar o app durante carga, voltar e CONTINUAR sem dedos presos.
- Gamepad: sticks, X/Y/A/B, LB/RB/LT/RT, R3, direcional e Start; conferir retorno ao touch após desconectar.
- Apresentação: barras de guarda, combo abaixo da vida rival, sons posicionais, arco de espada do Henrique em MED/HIGH e asas em HIGH.
- Medir FPS, memória, aquecimento e consumo durante 10 duelos. Os testes executados em desktop não substituem essa medição.

## Main integrado 0.17.0

Integração de `9e473ab` com a evolução 0.16, sem trocar modelos/rigs. APK local: `shinobi-clash-0.17.0-debug.apk` (versionCode 18). Contrato de gameplay compartilhado executa 54 verificações; exportação, assinatura, alinhamento 16 KB e payload isolado validados. Detalhes e hash em [MAIN_INTEGRATION_0170.md](MAIN_INTEGRATION_0170.md). Teste em aparelho físico continua pendente.
