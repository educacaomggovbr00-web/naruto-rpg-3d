# Modelos base_basic fornecidos pelo usuário

Os dois GLBs estáticos originais do ZIP `635d8c0a-27cc-4eb0-90b0-2f3ba33d2bfc (1).zip` **não ficam mais no Git**, porque juntos ocupavam cerca de 77 MB e não são usados em runtime. Os hashes/tamanhos esperados ficam em `source_manifest.json`; mantenha uma cópia local dos originais apenas se precisar reconstruir as versões rigadas.

| Fonte externa | Tamanho em bytes | Texturas embutidas |
| --- | ---: | --- |
| `base_basic_pbr.glb` | 42975656 | Diffuse, normal e metallic/roughness |
| `base_basic_shaded.glb` | 37620980 | Shaded |

Ambos são GLB 2.0, com uma malha/material e sem skin, esqueleto ou animações. As versões que permanecem no repositório e são usadas pelo jogo são `base_basic_pbr_rigged.glb` (padrão do Naruto) e `base_basic_shaded_rigged.glb` (alternativa de material).

## Preparação para animações

Cada versão rigada usa uma superfície, 46513 vértices, 39998 triângulos, texturas de até 1024 px e os 65 ossos corporais Mixamo compatíveis com `assets/animations/combat_mixamo.tres`. O ajuste de pose e os pesos são feitos offline, antes da importação. Os 27 clips existentes controlam o modelo pela mesma AnimationTree, com hitboxes seguindo os ossos, instâncias independentes para a CPU/clones e apoio visual na cápsula física.

Para reconstruir, instale numpy, scipy e Pillow e disponibilize **gltfpack 1.3** (MIT, ferramenta externa de desenvolvimento). Execute:

```sh
python tools/rig_base_basic_models.py \
  --gltfpack /caminho/para/gltfpack \
  --pbr-source /caminho/para/base_basic_pbr.glb \
  --shaded-source /caminho/para/base_basic_shaded.glb
godot --headless --path . --editor --import
python tools/validate_release_assets.py
godot --headless --path . --script res://tests/base_basic_visual_contract.gd
```

`rig_profile.json` registra os hashes das fontes/resultados e os landmarks da pose fornecida. O script reduz a geometria preservando os UVs, ajusta a malha da pose original assimétrica para o bind do combate e gera pesos suaves entre ossos vizinhos. Cabeça/cabelo seguem Head; as mãos fechadas seguem Hand. A geometria original de punhos fechados não permite abrir dedos individualmente; sinais de mão e outras poses específicas podem exigir retoque de malha/pesos. As animações são os clips CC0 adaptados do projeto, não coreografias oficiais de Storm. Desempenho real no Android ainda depende do aparelho.

Os hashes dos arquivos e das texturas extraídas pelo Godot constam em `../../asset_registry.json`. O ZIP não informa autor, origem ou licença; o registro mantém `UNKNOWN_LICENSE`, conforme o fluxo de desenvolvimento do projeto.
