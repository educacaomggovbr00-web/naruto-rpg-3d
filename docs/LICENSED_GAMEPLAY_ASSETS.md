# Licensed gameplay asset integration — 2026-10-06

Baseline: main `3c119544eeaf06482338d757b83c981119ff105b`; latest Actions run 37480544563 succeeded before changes. Baseline import and all 23 in-project Godot contracts passed. `export_payload_contract.gd` must run against exported PCKs outside the checkout, not directly against project files.

## Integrated assets

| Pack / author | License | Actual runtime use |
| --- | --- | --- |
| Nature Kit 2.1 / Kenney | CC0-1.0 | oak + shrubs + rocks in village, tall pines/boulders behind arena boundary, detailed broadleaf trees in forest/river |
| Particle Pack 1.1 / Kenney | CC0-1.0 | star impact/trails and smoke substitution, depth-tested billboards |
| 3D Shuriken Pack v2 / mehrasaur | CC0-1.0 | pooled kunai and four-point shuriken projectiles, arena target boards |
| Ultimate Animated Character Pack Nov 2019 / Quaternius | CC0-1.0 | male/female ninja battle skins and village NPCs, original rigs and native animations |

Exact file names, byte sizes, triangle counts, source URLs, archive hashes and runtime hashes: `assets/vendor/sources.json`. Total new runtime source assets: 1,971,951 bytes (~1.88 MiB). Kenney vegetation meshes: 72–402 triangles each. NPC meshes: male 2,720, female 7,104 triangles. Particles are 512x512; no large texture pack is bundled.

## Runtime changes

`licensed_scenery.gd` caches imported meshes and emits MultiMeshes in spatial cells, sharing meshes/materials. The arena/village use 24m cells; regions use 48m cells to preserve their <=10 draw-group contract. Imported GLB local transforms are retained and bounds normalized to target height, with the lowest point on the ground. LOW/MED/HIGH vegetation ranges are 48/78/112m. Scenery casts no additional shadows. Existing trunks/building/roof/ramp collisions remain unchanged.

`licensed_ninja_tools.gd` shares imported meshes and a metal material. Visual sizes are 0.48m for both shuriken and kunai; projectiles start just beyond the fist to stay readable against the fighter silhouette. The six-projectile pools, swept hit detection, damage and lifetimes are preserved. Decorative boards stay behind the arena boundary.

`combat_feedback.gd` replaces faceted spherical flashes with camera-facing textured quads in the same 32-slot pool. Active budgets remain 8/16/28. Smoke/impact textures respect depth and fade over their original lifetimes. No particle emitter or unbounded allocation per hit is introduced.

`licensed_ninja_actor.gd` is a dedicated world-NPC adapter with original native animation. It samples the native Idle skin once per model to normalize height to 1.72m and ground the feet; the bind-pose AABB produces visibly floating feet for these source rigs. It shares source resources, retains per-instance AnimationPlayer playback, and preserves world-manager mesh culling and interactions. Native skeleton evaluation pauses outside the existing 16/22/30m proximity budget, including its emergency reduction.

`licensed_combat_ninja.gd` instantiates the CC0 male/female meshes on the visible player and CPU in the battle scene. Its native idle, locomotion, punch, hit and defeat clips mirror the live combat state while the original Mixamo skeleton and all 27 retargeted clips stay active for hitboxes, hand sockets, combat timing and roster logic. Ninjas are grounded from the fighter capsule and normalized to 1.75m. Their shared toon materials use one pass; the player outline hull is omitted because its fixed local-space width creates fragments on these centimeter-scale source meshes. Generic CC0 skins replace only the rendered silhouette: roster-specific Naruto/Sasuke/Sakura faces and proprietary assets are not relabeled as CC0.

## Rebuild / validation

Download the original author upload `ultimate_animated_character_pack_by_quaternius.zip` and extract its FBX directory. Rebuild with:

```sh
godot --headless --path . --script res://tools/convert_licensed_ninjas.gd -- '/path/to/FBX'
```

The new `licensed_gameplay_assets_contract.gd` checks imported meshes, actual smoke texture, native animated NPCs, player clips, all quality levels, depth and fixed pool budgets. It is required in Actions alongside every existing gate. Provenance validation remains mandatory. Android PCK validation must use an isolated working directory.

## Research decisions / next stage

Storm 4 and Shinobi Striker remain presentation references; no proprietary model, texture, code or animation is imported. Quaternius Universal Animation Libraries 1/2 were already integrated and remain the existing combat source. Mini Japan by Ely Dev is stylistically relevant, but its public page did not state a reuse/redistribution license, so it was not integrated. Sketchfab Japanese village requires an attributable license and an obtainable authorized download; none was bundled. The official Ultimate Stylized Nature pack was reviewed, but the directly downloadable, small CC0 Kenney meshes were selected for this pass.

Village architecture remains the existing original walkable geometry. Next: select a proven licensed Japanese architecture kit, retarget higher-quality licensed playable ninja meshes without losing roster identity, and profile an actual Android device (GPU time, overdraw, memory and sustained frame rate). Desktop software rendering/headless checks do not establish Android performance or visual parity with commercial games.
