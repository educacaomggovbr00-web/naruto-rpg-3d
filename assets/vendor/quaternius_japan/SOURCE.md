# Japanese architecture sources

All runtime files in this folder are CC0 and are kept in Godot-compatible, uncompressed glTF form.

- `torii.gltf` — Quaternius, Sushi Restaurant Kit, CC0 1.0. Official pack: https://quaternius.com/packs/sushirestaurantkit.html. The exact glTF was mirrored from `agentkaerf/FreeModels`.
- `temple_small.gltf` and `temple.gltf` — Quaternius, Ultimate Fantasy RTS, CC0 1.0. Official pack: https://quaternius.com/packs/ultimatefantasyrts.html. Exact glTF mirrors were taken from `laoniutoushx/TD-demo-2024-04-03`.
- `shrine.gltf`, `shrine.bin`, `halloweenbits_texture.png` — Kay Lousberg, KayKit Halloween Bits 1.0, CC0 1.0. Exact source/license mirror: `marinho/godot-visual-effects/addons/kaykit_halloween_bits/Assets`.
- `sakura_tree.gltf` and `bamboo.gltf` — Quaternius, Sushi Restaurant Kit, CC0 1.0. Official pack: https://quaternius.com/packs/sushirestaurantkit.html. Exact glTF mirrors were taken from `agentkaerf/FreeModels`.

The previous optimized `arch.glb` bundle was removed because it required `EXT_meshopt_compression`, which Godot 4.7.2's importer rejected in CI.

Runtime changes are placement, scale normalization, visibility culling and the project's anime material adaptation. No Naruto/Shinobi Striker meshes or textures are present in this folder.
