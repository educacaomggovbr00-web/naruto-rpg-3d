# Animações reais incorporadas

## Origem e direitos

Universal Animation Library 1 e 2, por Quaternius, **CC0 1.0 Universal**. Fontes primárias:

- https://quaternius.com/packs/universalanimationlibrary.html
- https://quaternius.itch.io/universal-animation-library
- https://quaternius.com/packs/universalanimationlibrary2.html
- https://quaternius.itch.io/universal-animation-library-2

As páginas do autor permitem uso pessoal, educacional e comercial e declaram compatibilidade/retarget para Mixamo. Foram usados somente arquivos da edição gratuita **Standard**. Não foram baixados assets de Naruto/Storm nem arquivos do Mixamo.

Espelhos usados para aquisição reproduzível:

- UAL1: https://github.com/J-Ponzo/gltf-universal-animation-library — commit `e24c23cf2a1323488a3faa226ea7ea21f644b73e` (distribuição de 2025-06-10).
- UAL2: https://github.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender — commit `5821923af517ac5fdc82505faa92a0d575fc1b1a`, somente `Universal Animation Library 2[Standard]/Universal Animation Library 2[Standard]/Unreal-Godot/UAL2_Standard.glb` e sua licença. Nenhum código do espelho foi usado.

Extratos dos clips originais, sem meshes/texturas nem animações não utilizadas, estão em `assets/animations/source/`, com `.gdignore`, licenças e SHA-256 registrados no manifest. A biblioteca pré-bakeada fica em `assets/animations/combat_mixamo.tres`. 22 clips de jogo são derivados de 19 clips-fonte (contando a recuperação do hook); variantes não são apresentadas como mocap independente.

## Mapeamento exato

| Clip de jogo | Fonte real | Adaptação |
|---|---|---|
| idle | UAL1 Idle_Loop | retarget, loop |
| run | UAL1 Jog_Fwd_Loop | retarget, in-place |
| sprint | UAL1 Sprint_Loop | retarget, in-place |
| jump | UAL2 NinjaJump_Start | recorte, velocidade; deslocamento vertical pela física |
| fall | UAL2 NinjaJump_Idle_Loop | loop, física vertical |
| land | UAL2 NinjaJump_Land | pouso recortado |
| attack_1 | UAL1 Punch_Jab | jab **esquerdo**, 0,28 s |
| attack_2 | UAL1 Punch_Cross | cross **direito**, 0,30 s |
| attack_3 | UAL2 Melee_Hook + Melee_Hook_Rec | hook direito, 0,34 s |
| attack_4 / launcher | UAL2 Melee_Hook + Melee_Hook_Rec | trajetória do braço elevada, 0,40 s |
| air_attack_1 | UAL1 Punch_Jab + UAL2 NinjaJump_Idle_Loop | soco superior + pernas aéreas |
| air_attack_2 | UAL1 Punch_Cross + UAL2 NinjaJump_Idle_Loop | soco superior + pernas aéreas |
| air_attack_3 | UAL2 Melee_Hook/Rec + NinjaJump_Idle_Loop | hook superior + pernas aéreas |
| air_attack_4 / slam | UAL2 Sword_Heavy_Combo + NinjaJump_Idle_Loop | golpe descendente final; sem espada |
| guard | UAL2 Idle_Shield_Loop | postura defensiva sem escudo |
| dodge | UAL1 Roll | roll em 0,24 s; deslocamento pelo controlador |
| chakra_dash | UAL2 Sword_Dash | rush sem espada; deslocamento pelo controlador |
| chakra_charge | UAL1 Spell_Simple_Idle_Loop | gesto contínuo de magia + aura original |
| jutsu | UAL1 Spell_Simple_Shoot | disparo de magia, impacto em 0,24 s |
| hit | UAL1 Hit_Chest | reação a hit |
| knockback | UAL2 Hit_Knockback | disponível para futuras reações fortes |
| defeat | UAL1 Death01 | queda + pose final sem loop |

Durações de origem, recortes, amostras e bone de impacto estão no manifest gerado pelo bake. A inspiração de arena fighter orienta ritmo e encadeamento; esses movimentos não reproduzem animações proprietárias ou técnicas específicas de personagens de Storm.
