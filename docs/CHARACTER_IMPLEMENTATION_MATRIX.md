# Matriz de implementação de personagens

Atualização: 2026-10-04. Modelos de Naruto/Sasuke/Kakashi/Gaara comerciais não foram importados. O rig fornecido permanece preservado; quatro meshes autorais estilizadas usam seus 65 joints de corpo, com 27 clips CC0 retargetados. A referência principal é Storm 1; fontes técnicas e diferenças entre versões estão em [STORM_MOVES_DATA.md](STORM_MOVES_DATA.md).

| Personagem | Movimento / combos | Jutsu / projétil | Ultimate / Awakening | Animação / VFX | Implementado agora / falta |
|---|---|---|---|---|---|
| Naruto Part 1 | Arena/lock/dash/aéreo existentes; branches neutro/alto/baixo/lateral | Demon Wind, Rasengan, clones/Charging Bullet/Whirlwind/Barrage existentes | Handbook adaptado; base temporária de uma cauda | 27 clips reais; Rasengan multilayer, aura/trails/flash pooled; não coreografia final | Moveset compartilhado jogador/CPU; direção após intro e buffer touch; neutro separado do launcher; projeção configurável; câmera por ataque. Faltam kicks/clones das branches, carga/grab/Impact, Sealed Power, suporte e modelo final |
| Naruto adulto / Sage / KCM etc. | Não implementados como variantes | Não inventar seus golpes a partir de Part 1 | Formas/Ultimates próprios pendentes | Sem clips/modelos próprios | Comparação por jogo/build e CharacterDefinition/variante antes de implementar |
| Sasuke Part 1 (base) | Selecionável; stats/moveset separado, terceiro golpe kick real | Fireball swept + Chidori hand Area, custo/recovery | Desabilitados; pendentes próprios de Sasuke | Modelo próprio estilizado; elétrico/fogo originais; clips ainda adaptados | Falta polimento visual, coreografia exclusiva, costumes/desbloqueio, Phoenix Flower, Ultimate e Awakening |
| Kakashi (base) | Selecionável; Resource separado, combos reais compartilhados | Raikiri na mão com Resource próprio; Fireball swept alternativo | Desabilitados; pendentes | Modelo próprio estilizado com máscara/vest/hair; 27 clips e VFX elétrico compartilhados | OUR_APPROXIMATION: Raikiri tem dano/tracking/velocidade próprios; faltam coreografia Storm, Water Shark, hounds e polimento |
| Gaara | Perfil-base próprio de combo/launcher/aéreo via RosterMovesetFactory (OUR_APPROXIMATION) | Sand Shower/Tsunami/Coffin/Burial: metas a verificar por versão | Pendentes | Sem areia/rig/animações próprias | Já não herda combo do Naruto; ainda precisa de hitboxes/VFX/ações de areia e coreografia específica |
| Sakura (base) | Selecionável; Resource com melee pesado, finalizador 17 em vez de 15 (OUR_APPROXIMATION) | Booby Trap: fio físico → bola de ferro com sweep; pool de três, custo/cooldown | Desabilitados; pendentes | Novo GLB texturizado fornecido pelo usuário: 27-bone Mixamo compacto, ~35,7k triângulos, texturas mobile 1024; Idle/Walk/Run nativos + 27 clips CC0 retargetados por Bone Rest para combate; fallback autoral se o arquivo não estiver instalado | Novo visual integrado tecnicamente e com grounding/autoescala. Origem/licença ainda UNKNOWN, então é desenvolvimento apenas. Faltam Fairy Tale, Great Sakura, Maiden’s Anger e coreografia final |
| CPU atual | Humanoide selecionável; profile/moveset, branches, dash/pursuit, charge, guarda/sub/KO | Shared CombatSpecials/clones, jutsu profile, tools reais | Naruto: shared Ultimate com entry física/clash e Awakening; Sasuke/Sakura/Kakashi desabilitados | AnimationTree independente, clips preparados compartilhados | Estratégia probabilística atrasada; observação de projéteis lançados com guarda/esquiva/falha implementada; faltam perfis táticos específicos e polimento competitivo |

## Contratos e integração

- `AttackDefinition` consome dano/impulso/stun/animação/evento; startup/active/recovery/cancel vêm do manifesto real, preservando rig adapter e AnimationTree.
- `MovesetDefinition` escolhe chain/branch; ambos os controladores utilizam o mesmo Resource imutável. Estado de cada luta fica nos controladores, nunca no Resource compartilhado.
- `ProjectileDefinition` configura Demon Wind no sweep existente, sem dependência externa no Android.
- `CameraEventDefinition` controla impactos do jogador; CPU usa feedback existente. Ultimate/câmera são compartilhados, mas nem todos os parâmetros migraram para Resources.
- `CharacterDefinition` configura modelo/stats/moveset/jutsus/capabilities. UltimateDefinition continua; JutsuDefinition configura todos os IDs selecionáveis, custo/cooldown e ataques de mão/armadilha; timelines de clones/Barrage e Awakening ainda precisam migração completa.
- `moves_data_contract.gd`: seleção das quatro branches, timings reais, buffer touch, guard-break sem confirmação, recurso do projétil, cleanup. Suítes anteriores continuam obrigatórias.

## Checklist Android deste incremento

1. ATK ×2, depois analógico para cima + ATK: final lança; neutro afasta e baixo derruba.
2. Segurar direção cedo e soltar antes do terceiro golpe: resultado segue direção na branch, não no início; toque buffered conserva a direção do comando.
3. Quebrar guarda: não ganhar cancel de acerto limpo; errar não causar HP por distância.
4. Demon Wind/Rasengan/clones/ULT e treino→aldeia continuam funcionando.
5. Observar zoom/shake do finalizador neutro e FPS com dois rigs + clones; perfil LOW/MED/HIGH. Sem teste físico/GPU Android nesta sessão.


## Perfis-base do restante do elenco — 2026-10-05

Os 21 slots que antes apontavam para `NARUTO.moveset` agora recebem `MovesetDefinition` independente em runtime por `RosterMovesetFactory`. Cada perfil possui quatro ataques terrestres, quatro aéreos, branches neutro/cima/baixo/lateral e parâmetros próprios de mobilidade/vida. Rock Lee/Guy priorizam velocidade, Choji/Tsunade/Kisame peso e knockback, Gaara/Kankuro/Temari controle pesado, e os demais recebem variações coerentes apenas como balanceamento provisório.

Esses dados **não são frame data oficial nem coreografia final do Storm 1**. O objetivo é permitir testar todo o roster sem emprestar o kit do Naruto enquanto jutsus, Ultimate, Awakening, VFX, CPU profile e animações exclusivas são implementados em lotes.


## Ataques-base e especiais do elenco completo — 2026-10-05

Todos os 25 lutadores selecionáveis agora possuem `MovesetDefinition` válido e pelo menos um jutsu selecionável. Naruto, Sasuke, Sakura e Kakashi preservam os kits específicos já existentes. Os 21 slots restantes usam o rig compartilhado temporário, porém não herdam mais ataques ou jutsus de Naruto.

| Lutador | Especial atual de desenvolvimento | Família runtime |
|---|---|---|
| Naruto | Demon Wind / Rasengan / Clones / Whirlwind / Barrage | projétil / mão / clones |
| Sasuke | Fireball / Chidori | projétil / mão |
| Sakura | Booby Trap | armadilha |
| Shikamaru | Shadow Bind | projétil de controle |
| Choji | Human Boulder | rush |
| Ino | Mind Transfer | projétil de controle |
| Rock Lee | Leaf Whirlwind | rush |
| Neji | Eight Trigrams Rotation | área |
| Tenten | Weapon Volley | projétil |
| Shino | Insect Swarm | projétil |
| Kiba | Fang Over Fang | rush |
| Hinata | Gentle Fist | rush |
| Gaara | Sand Coffin | área |
| Kankuro | Puppet Strike | projétil |
| Temari | Wind Scythe | projétil |
| Kakashi | Raikiri / Fireball | mão / projétil |
| Might Guy | Dynamic Entry | rush |
| Jiraiya | Toad Oil Bullet | projétil |
| Tsunade | Heaven Kick | rush pesado |
| Hiruzen | Fire Dragon | projétil |
| Orochimaru | Snake Bind | projétil de controle |
| Kabuto | Chakra Scalpel | rush |
| Kimimaro | Bone Dance | área |
| Itachi | Fire Style | projétil |
| Kisame | Water Shark | projétil |

Os 21 novos especiais são uma camada jogável **OUR_APPROXIMATION** usando animações compartilhadas e VFX leves compatíveis com mobile. Os nomes representam a direção do kit; coreografia, timing, modelo, VFX e comportamento finais ainda exigem pesquisa e passes próprios por personagem. O runtime comum possui estratégias `hand`, `projectile`, `burst`, `trap`, `clones` e `barrage`, permitindo evoluir personagens sem duplicar controladores.

O contrato `full_roster_specials_contract.gd` exige que todos os 25 tenham combo terrestre, combo aéreo e jutsu resolvível, além de executar em arena um projétil genérico e um golpe em área.
