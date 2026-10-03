# Matriz de implementação de personagens

Atualização: 2026-10-03. Modelos de Naruto/Sasuke/Kakashi/Gaara comerciais não foram importados. O rig fornecido permanece preservado; quatro meshes autorais estilizadas usam seus 65 joints de corpo, com 27 clips CC0 retargetados. A referência principal é Storm 1; fontes técnicas e diferenças entre versões estão em [STORM_MOVES_DATA.md](STORM_MOVES_DATA.md).

| Personagem | Movimento / combos | Jutsu / projétil | Ultimate / Awakening | Animação / VFX | Implementado agora / falta |
|---|---|---|---|---|---|
| Naruto Part 1 | Arena/lock/dash/aéreo existentes; branches neutro/alto/baixo/lateral | Demon Wind, Rasengan, clones/Charging Bullet/Whirlwind/Barrage existentes | Handbook adaptado; base temporária de uma cauda | 27 clips reais; Rasengan multilayer, aura/trails/flash pooled; não coreografia final | Moveset compartilhado jogador/CPU; direção após intro e buffer touch; neutro separado do launcher; projeção configurável; câmera por ataque. Faltam kicks/clones das branches, carga/grab/Impact, Sealed Power, suporte e modelo final |
| Naruto adulto / Sage / KCM etc. | Não implementados como variantes | Não inventar seus golpes a partir de Part 1 | Formas/Ultimates próprios pendentes | Sem clips/modelos próprios | Comparação por jogo/build e CharacterDefinition/variante antes de implementar |
| Sasuke Part 1 (base) | Selecionável; stats/moveset separado, terceiro golpe kick real | Fireball swept + Chidori hand Area, custo/recovery | Desabilitados; pendentes próprios de Sasuke | Modelo próprio estilizado; elétrico/fogo originais; clips ainda adaptados | Falta polimento visual, coreografia exclusiva, costumes/desbloqueio, Phoenix Flower, Ultimate e Awakening |
| Kakashi (base) | Selecionável; Resource separado, combos reais compartilhados | Mecânica física de Chidori como aproximação inicial de relâmpago; Raikiri completo/clones pendentes | Desabilitados; pendentes | Modelo próprio estilizado com máscara/vest/hair; 27 clips e VFX elétrico compartilhados | OUR_APPROXIMATION: polir visual, animações/moveset Storm e Raikiri antes de declarar personagem completo |
| Gaara | Sem moveset próprio | Sand Shower/Tsunami/Coffin/Burial: metas a verificar por versão | Pendentes | Sem areia/rig/animações próprias | Não tratar como Naruto com material diferente; necessidade de hitboxes/VFX/ações específicas |
| Sakura (base) | Selecionável; Resource com melee pesado, finalizador 17 em vez de 15 (OUR_APPROXIMATION) | Sem jutsu; controles correspondentes desabilitados | Desabilitados; pendentes | Modelo próprio estilizado com cabelo rosa/roupa vermelha; 27 clips compartilhados | Faltam jutsu/coreografia Storm e polimento visual; não é personagem completo |
| CPU atual | Humanoide selecionável; profile/moveset, branches, dash/pursuit, charge, guarda/sub/KO | Shared CombatSpecials/clones, jutsu profile, tools reais | Naruto: shared Ultimate com entry física/clash e Awakening; Sasuke/Sakura/Kakashi desabilitados | AnimationTree independente, clips preparados compartilhados | Estratégia probabilística atrasada; observação de projéteis lançados com guarda/esquiva/falha implementada; faltam perfis táticos específicos e polimento competitivo |

## Contratos e integração

- `AttackDefinition` consome dano/impulso/stun/animação/evento; startup/active/recovery/cancel vêm do manifesto real, preservando rig adapter e AnimationTree.
- `MovesetDefinition` escolhe chain/branch; ambos os controladores utilizam o mesmo Resource imutável. Estado de cada luta fica nos controladores, nunca no Resource compartilhado.
- `ProjectileDefinition` configura Demon Wind no sweep existente, sem dependência externa no Android.
- `CameraEventDefinition` controla impactos do jogador; CPU usa feedback existente. Ultimate/câmera são compartilhados, mas nem todos os parâmetros migraram para Resources.
- `CharacterDefinition` configura modelo/stats/moveset/jutsus/capabilities. UltimateDefinition continua; Jutsu/Awakening ainda são módulos compartilhados, não uma migração completa a Resources.
- `moves_data_contract.gd`: seleção das quatro branches, timings reais, buffer touch, guard-break sem confirmação, recurso do projétil, cleanup. Suítes anteriores continuam obrigatórias.

## Checklist Android deste incremento

1. ATK ×2, depois analógico para cima + ATK: final lança; neutro afasta e baixo derruba.
2. Segurar direção cedo e soltar antes do terceiro golpe: resultado segue direção na branch, não no início; toque buffered conserva a direção do comando.
3. Quebrar guarda: não ganhar cancel de acerto limpo; errar não causar HP por distância.
4. Demon Wind/Rasengan/clones/ULT e treino→aldeia continuam funcionando.
5. Observar zoom/shake do finalizador neutro e FPS com dois rigs + clones; perfil LOW/MED/HIGH. Sem teste físico/GPU Android nesta sessão.
