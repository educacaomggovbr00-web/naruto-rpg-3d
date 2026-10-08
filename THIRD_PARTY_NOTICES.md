# Third-party notices

## Quaternius — Universal Animation Libraries 1 and 2

Author: Quaternius. UAL2 also credits animator Gonzalo Furnier on its official page.
License: CC0 1.0 Universal (public domain dedication).

https://quaternius.itch.io/universal-animation-library
https://quaternius.itch.io/universal-animation-library-2
https://creativecommons.org/publicdomain/zero/1.0/

Vendored free Standard animation source files and their retargeted/adapted derivatives are included in this repository. Source license copies: `assets/animations/source/CC0-1.0.txt` and `UAL2-License.txt`. Acquisition revisions, SHA-256 checksums and modifications are documented in `docs/ANIMATION_SOURCES.md` and `assets/animations/combat_manifest.json`.

## avatar-stage (historical reference)

Copyright (c) 2026 Jatin Rana. MIT.
https://github.com/rana-jatin/avatar-stage

Earlier procedural implementations cited this project for design/reference concepts. The obsolete procedural rig library has been removed; the current animation data is from the CC0 Quaternius sources above.

## Previously supplied character

The existing `assets/characters/rigged.glb` is unchanged. These animation licenses do not establish or alter ownership or licensing of that previously supplied model.

## Fase Storm 1

Nenhum asset proprietário novo foi adquirido. Clones compartilham o modelo previamente fornecido e a biblioteca CC0. As variantes de jog/strafe/recuo, guard break e Rasengan são adaptações das mesmas fontes Quaternius, registradas no manifesto. Fūma shuriken, esfera/anéis de chakra, fumaça e trails são meshes originais do código do projeto. Kenney Particle Pack (CC0) foi pesquisado, mas não distribuído nesta revisão. Ver `docs/ASSET_SOURCES.md`.


## Revisão Ultimate/Awakening/ferramentas

Os efeitos usam `star_01.png` e `smoke_01.png` do Kenney Particle Pack (CC0 1.0), incluídos em `assets/vendor/sources.json`; os shaders e a geometria da arena são originais deste projeto. Animações e cópias do personagem reutilizam as fontes acima. O modelo fornecido e as imagens embutidas nele continuam `UNKNOWN_LICENSE` para publicação até comprovação. Registro com hashes: `assets/asset_registry.json`. Kenney Modular Buildings/KayKit Medieval Hexagon foram pesquisados sob CC0, sem importação. [Godot Engine — licença MIT](https://godotengine.org/license) deve constar nos créditos da distribuição.

## Aldeia autoral e dados de mundo

A geometria de aldeia em `scripts/world/world_mesh_builder.gd` e `scripts/arena_presentation.gd`, pontos/missões em `assets/world`, mapa/UI e prévia diagnóstica em `docs/images/village_layout_preview.png` são conteúdo original deste projeto. A prévia renderiza apenas geometria original em CPU; não contém imagem do Storm nem modelo fornecido. Os ninjas de batalha e NPCs usam os modelos Quaternius CC0 listados abaixo. Nenhuma textura, áudio ou mesh do jogo original foi incorporada. A proveniência dos modelos de personagem fornecidos permanece `UNKNOWN_LICENSE` e o gate público segue ativo.

## Referências técnicas (sem código/asset redistribuído)

Storm Character Manager, UNSME, NSC Toolbox/ModManager, UNSG V2, Road to Connections, jumpforce-tools, UE4SS e Unverum foram consultados em 2026-10-03; fontes e limites em `docs/STORM_MOVES_DATA.md`. Novos Resources/implementações são originais; nenhum PRM/XFBIN/ANM comercial foi incorporado. Licenças das ferramentas não conferem licença dos jogos.

## Kenney — SFX integrados

Autor: Kenney (https://kenney.nl). Impact Sounds e Sci-fi Sounds, CC0 1.0 Universal. Oito arquivos OGG em assets/audio/kenney; arquivos de licença originais LICENSE_impact.txt e LICENSE_scifi.txt preservados. Fontes/nomes/hashes e uso estão em docs/ASSET_SOURCES.md e assets/asset_registry.json. Arquivos inalterados; volume e loop ajustados no runtime. Nenhum som ou música do Storm foi importado.

## Original stylized development characters

Three meshes in `assets/characters/stylized` were authored in this project, not imported from the games. They reuse only the supplied body skeleton transforms to preserve animation compatibility. They depict Sasuke/Sakura/Kakashi and remain DEVELOPMENT_ONLY until character presentation and skeleton distribution are cleared. Existing CC0 animation/audio credits remain applicable. The original user model is preserved unchanged. The new toon material, ground shader and arena geometry are original project content.


A geometria runtime da Booby Trap e configurações JutsuDefinition foram criadas para este projeto; não contêm modelos/texturas/animações extraídos de Storm. Os clips continuam sendo os bakes CC0 já creditados acima.


## Licensed gameplay packs — 2026-10-06

- Kenney Nature Kit 2.1: https://kenney.nl/assets/nature-kit — CC0-1.0. Six original GLBs, normalized and spatially instanced in arena/village/regions.
- Kenney Particle Pack 1.1: https://kenney.nl/assets/particle-pack — CC0-1.0. Original `star_01.png` and `smoke_01.png`, used by bounded combat billboard pools.
- mehrasaur 3D Shuriken Pack v2: https://opengameart.org/content/3d-shuriken-pack — CC0-1.0. `shaken-juji`, `kunai-gata-01`, `aim-board`; OBJ geometry unchanged, unsupported MTL ambient terms removed.
- Quaternius Ultimate Animated Character Pack (Nov 2019 author upload): https://opengameart.org/content/animated-characters-pack — CC0-1.0. `Ninja_Male` and `Ninja_Female`, FBX converted to GLB using Godot 4.7.2, native rig/animations preserved. Used only for village/background NPCs; roster fighters keep their own configured 3D models.

Original Kenney license files and author-upload CC0 evidence notices are in `assets/vendor/*/LICENSE.txt`. Source/archive/runtime hashes and changes are in `assets/vendor/sources.json` and the asset registry. CC0 dedication: https://creativecommons.org/publicdomain/zero/1.0/.

No Storm 4 or Shinobi Striker game files were acquired or included by this change. The pre-existing public-release restrictions remain in force.


## Anime outline — albanogiovanni

Source: https://github.com/albanogiovanni/godot-anime-sdf-shader  
License: MIT. Copyright (c) 2026 albanogiovanni.

The combat character outline in `assets/vfx/anime_outline.gdshader` adapts the source project's distance-aware inverted-hull idea into a clip-space, mobile-oriented pass so outline thickness stays readable across differently scaled imported rigs. The full MIT notice is preserved in `docs/licenses/albanogiovanni-godot-anime-sdf-shader-MIT.txt`.

## Manga combat impact — hailyn / GodotShaders.com

Source: https://godotshaders.com/shader/screen-sampled-black-and-white-manga-hit-impact-post-process-shader/  
License: CC0 1.0 for the shader code/snippets.

`assets/vfx/manga_impact.gdshader` is a lightweight adaptation for short combat impacts and chakra dash emphasis. It preserves scene colour, generates radial lines procedurally, uses no external art, and is only made visible for brief impact windows to keep the mobile cost bounded.


## Kenney — Fantasy Town Kit 2.0

Author: Kenney. Source: https://opengameart.org/content/fantasy-town-kit  
License: CC0 1.0 Universal.

Selected original GLB models and the shared colormap are vendored unchanged under `assets/vendor/kenney_fantasy_town`. The village and combat arena now instantiate the gate, market stalls, carts, benches, lanterns and banners directly in visible gameplay. Runtime changes are limited to scale, placement, culling and the project's anime material adaptation for mobile.


## Japanese architecture — Quaternius / Kay Lousberg

Runtime files: `assets/vendor/quaternius_japan/torii.gltf`, `temple_small.gltf`, `temple.gltf`, and the KayKit `shrine.gltf` dependencies.

- Torii: Quaternius Sushi Restaurant Kit, CC0 1.0 — https://quaternius.com/packs/sushirestaurantkit.html
- Temples: Quaternius Ultimate Fantasy RTS, CC0 1.0 — https://quaternius.com/packs/ultimatefantasyrts.html
- Shrine: Kay Lousberg / KayKit Halloween Bits 1.0, CC0 1.0. License copy/source mirror recorded in `assets/vendor/quaternius_japan/SOURCE.md`.
- Sakura tree and bamboo: Quaternius Sushi Restaurant Kit, CC0 1.0 — https://quaternius.com/packs/sushirestaurantkit.html

The game normalizes scale, applies culling and the anime material pass at runtime. The old meshopt-compressed bundle was removed for Godot 4.7.2 compatibility. No Naruto/Shinobi Striker meshes or textures are included.


## Perfect susanoo — wahidinesport

This work is based on “Perfect susanoo” by wahidinesport, licensed under CC BY 4.0.

- Original: https://sketchfab.com/3d-models/perfect-susanoo-c1ef38744eb64891b26a6f41aac1b199
- Author: https://sketchfab.com/wahidinesport
- License: https://creativecommons.org/licenses/by/4.0/
- Downloaded CC archive: https://mirror.traines.eu/sketchfab-backup/c1/c1ef38744eb64891b26a6f41aac1b199.zip
- Bundled license: `assets/susanoo/LICENSE.txt` (also included in Android export).
- Modifications: glTF to GLB conversion using gltfpack 1.3, reduced from 34,098 to 11,961 triangles; runtime scale, purple chakra material, optional wings and separate project-authored chakra blade.

The original is static, without skin/animations. Geometry and declared uploader license were inspected. The existing release gate retains DEVELOPMENT_ONLY because the model depicts franchise content and upstream ownership/brand authorization is not established.

## Henrique — supplied ZIP and project rig

Source: `3970037e-fd4c-4114-b9f6-75905e547ff4.zip`, `base_basic_pbr.glb` supplied by the player. Source SHA-256: `701a61f74ba02666bd672df53ea88000ccdb71d994e38dfd16dd942ac8505852`.

Provider/generation rights were not supplied; registered as DEVELOPMENT_ONLY. The project fitted the 65-bone combat reference skeleton, normalized weights, retained the chibi head and reposed the mesh offline. Existing CC0 Quaternius combat animations are registered separately; rig reference provenance remains unchanged.
