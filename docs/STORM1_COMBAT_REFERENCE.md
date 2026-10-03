# Referência de combate — Naruto: Ultimate Ninja Storm (2008)

Pesquisa: 2026-10-02/03. Escopo atual: Naruto, base de Ultimate/Awakening/ferramentas além do slice até Barrage. Nenhum código, áudio, modelo ou animação do jogo comercial foi extraído.

## Fontes e confiança

- [Guia PS3 de des326, 2008](https://gamefaqs.gamespot.com/ps3/943434-naruto-ultimate-ninja-storm/faqs/54663): controles, combos de Naruto, ferramentas, chakra, guard break, Awakening, Ultimate. Guia comunitário contemporâneo; não é frame data oficial.
- [Guia PS3 Ashurii](https://gamefaqs.gamespot.com/ps3/943434-naruto-ultimate-ninja-storm/faqs/54852): chakra load/charge, dash, defesa, Ultimate e suporte.
- [Review contemporâneo GameSpot](https://www.gamespot.com/reviews/naruto-ultimate-ninja-storm-review/1900-6200864/): corrida livre, câmera dos dois lutadores, guarda que quebra, substituição por timing atrás do atacante.
- [Moveset Naruto Part 1 — seção Storm 1](https://naruto-ultimate-ninja-storm.fandom.com/wiki/Naruto_Uzumaki_(Part_1)/Move_List): nomes e função de combos/jutsus. Não confundir a seção inferior de Storm 3/4.
- [Demon Wind Bomb](https://naruto-ultimate-ninja-storm.fandom.com/wiki/Demon_Wind_Bomb): Naruto/clone transforma-se em fūma shuriken, lançado; contato confirma sequência com clone e knockback.
- [Vídeo comparativo de movesets Storm 1–4](https://www.youtube.com/watch?v=sfYueIOlvFE): referência visual adicional para inspeção manual; não foi possível extrair/assistir quadros nesta sessão. Não usado para alegar timings medidos.

## Estrutura da referência e adaptação

| Sistema | Storm 1 / evidência | Implementação desta fase |
|---|---|---|
| Movimento | Arena 3D livre; orientação e enquadramento seguem confronto | Livre sem lock; radial/tangencial com lock, analógico proporcional, corrida, ar limitado |
| Lock/câmera | Dois lutadores enquadrados, perspectiva acompanha distância/posição | Lock explícito mobile; pivô suavizado, braço com colisão volumétrica, FOV/distância por separação |
| Salto/ninja move | X; X duplo ninja dash; direção permite evasão | PULO, ESQ, DASH separados para touch; não replica todas combinações PS3 |
| Chakra | Segurar triângulo carrega; toque prepara ação | CHK segurado, DASH/JUTSU diretos; carga vulnerável |
| Chakra dash | Aproximação rápida rastreada, atravessa projéteis, flinch sem dano, recoil na guarda | Startup/aceleração/tracking limitado; contato físico abre combo, bloqueio repele |
| Combo | Um botão, direção muda finalizador; clones integram moveset | Cadeia de quatro clips reais, neutro/alto/baixo/lateral; buffer e janelas de confirmação |
| Launcher/aéreo | Skyrocket lança; Whirlwind Strike aéreo com clone e golpe descendente | Launcher → dash → aéreo/slam; limite de perseguições e recuperação forçada |
| Recovery | Janelas puníveis; reação/evasão permite retomar neutral | Recovery explícito, whiff não permite cancel por hit confirm |
| Guarda | Segurada, azul→vermelho, quebra deixa vulnerável | Meter contínuo, stun, break, regen após pausa; feedback próprio |
| Substituição | Timing do botão de defesa, aparece atrás do oponente | Quatro cargas solicitadas pelo usuário (adaptação, não mecânica exata de Storm 1), recarga, cooldown curto, invulnerabilidade e posição validada |
| Ferramentas | Shuriken, chakra shuriken e quatro itens direcionais | Shuriken + ramen/food pills/kunai rain/bomb ball, estoque/cooldown e colisão física |
| Demon Wind Bomb | Fūma shuriken de longo alcance; hit confirma golpes com clone | Projétil varrido, trajetória, bloqueio/cenário/timeout; clone após confirmação |
| Rasengan | Jutsu selecionável, aproximação e esfera na mão | Esfera/área presa ao osso, janela ativa, corrida rastreada, colisão e dissipação |
| Charging Bullet | Tilt invoca dois clones de médio alcance, entradas adicionais | Dois clones com ataques escalonados e confirmação física |
| Whirlwind Strike | Combo aéreo de clones, final descendente | Clones com pernas aéreas e slam final |
| Naruto Uzumaki Barrage | Clone lança; Naruto termina com golpe descendente | Entrada precisa conectar, clone launcher e golpe final do jogador; câmera temporária segura |
| Ultimate | Naruto's Ninja Handbook; hit abre sequência/QTE, chakra alto | Clone lançado confirma QTE mash disputado com a CPU; dogpile/corrente/finalizador adaptados, cleanup por token/watchdog. Não confundir com 2K Barrage de jogos posteriores |
| Awakening | Vida baixa habilita indicador; carregar chakra até máximo transforma | Uma cauda temporária, Vermillion, wind wave/imunidade a ferramentas; limiar/duração próprios. Sealed Power ainda não implementado |
| Impactos | Lançamento, queda, pancada forte, parede; alguns palcos permitem combate na parede | Preserva bounce existente; não implementa troca do plano de combate |
| CPU | Quatro dificuldades; fontes não expõem algoritmo interno | IA atual preservada; guarda/sub probabilísticas com atraso. Não lê input do jogador |

## Valores aproximados, sem frame data oficial

Timings usam segundos no relógio de física; startup/active/recovery derivam dos clips retargetados e ajuste de gameplay. Distâncias, velocidade, custos, dano, cooldowns, guard meter, cargas e limite de juggle são parâmetros de balanceamento próprios. Dash cancels/hit confirms solicitados são uma adaptação explícita: não atribuir automaticamente os cancels de Storm 4 ao Storm 1. Não há alegação de réplica frame-perfect.

## Restrições visuais

O rig existente e os clips CC0 continuam sendo a base. Punch/hook e spell clips não equivalem às coreografias autorais de Naruto. Barrage usa golpe descendente real disponível, temporariamente com a mão; axe kick, double dropkick, transições animadas da transformação em shuriken e animações de selos precisam de clips licenciados/autoria dedicada para fidelidade final. Esta fase replica estrutura e colisões, sem anunciar esses placeholders como animações finais de Storm.


## Ultimate/Awakening/ferramentas — revisão 2026-10-03

[Handbook Storm wiki](https://naruto-ultimate-ninja-storm.fandom.com/wiki/Naruto%27s_Ninja_Handbook): entrada por clone lançado; clones se acumulam no adversário e formam uma corrente pelos tornozelos; derrota na disputa permite substituição. O texto foi recuperado por busca; página completa/vídeo não tiveram quadros verificáveis nesta sessão. [Compilação de Ultimates Storm 1](https://www.youtube.com/watch?v=Pjm4r0cMqtI) e [evolução do Ultimate, Storm em 2:53](https://www.youtube.com/watch?v=ANb2eR8moBE) são referências pendentes de inspeção visual, não de timings medidos.

[Guia Ashurii](https://gamefaqs.gamespot.com/ps3/943434-naruto-ultimate-ninja-storm/faqs/54852) confirma Ultimate por chakra load duplo + ataque e modos command/mash/spin; Awakening por carregar além do máximo quando o indicador surge. O projeto expõe ULT/AWK diretamente no touch; mash adaptado exige pelo menos 4 toques em 1 s e superar a pontuação da CPU; empate favorece o defensor. A CPU usa atraso inicial aleatório (.18–.30 s) e intervalos independentes (.18–.28 s), sem ler input/pontuação do jogador. Ritmo e regra de empate são ajustes próprios para mobile, não dados medidos do original. Não é jutsu clash simultâneo, nem implementação de todos os formatos de QTE. Não há Storm Gauge ainda.

[Storm 1 Naruto Part 1](https://naruto-ultimate-ninja-storm.fandom.com/wiki/Naruto_Uzumaki_(Part_1)): uma cauda, mudanças de moveset, wind waves, resistência a ferramentas, Vermillion Rasengan e Sealed Power. Não misturar 2K Barrage de jogos posteriores. A base implementa temporização/recursos/efeitos e modifica movimento/dano/jutsu/projétil; combos de garras e Sealed Power precisam de fase adicional e animação dedicada.

Valores próprios: Ultimate 80 chakra, CD 12 s; entry conforme manifest jutsu (.24 s); dogpile .9 s, corrente .65 s, finisher conforme attack_4; Awakening HP ≤30%, chakra cheio, carga extra .6 s, transição 1 s, duração 18 s, cooldown 20 s, movimento ×1.2/dano ×1.35. Estoques: ramen 1, pills/kunai/bomba 2; ramen chakra +30%, buff ×1.2 por 20 s. Quantidades/função dos itens são referências do guia des326; multiplicadores e tempos restantes são aproximações de balanceamento, não números oficiais.
