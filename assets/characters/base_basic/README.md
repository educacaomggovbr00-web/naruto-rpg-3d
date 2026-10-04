# Modelos base_basic fornecidos pelo usuário

Os dois GLBs do ZIP `635d8c0a-27cc-4eb0-90b0-2f3ba33d2bfc (1).zip` foram adicionados sem alterar os arquivos originais.

| Arquivo | Tamanho em bytes | Texturas embutidas |
| --- | ---: | --- |
| `base_basic_pbr.glb` | 42975656 | Diffuse, normal e metallic/roughness |
| `base_basic_shaded.glb` | 37620980 | Shaded |

Ambos são GLB 2.0, exportados pelo Blender, com uma malha e um material. Cada malha tem 698752 vértices e aproximadamente 1,70 m de altura. Não possuem skin, esqueleto ou animações.

Abra os arquivos no Godot para inspecionar as variantes de material. Eles ficam disponíveis como modelos estáticos; a definição do Naruto e o rig de combate existentes foram preservados. Para usá-los como personagem animado, será necessário preparar skin/rig e retarget compatíveis com a biblioteca de combate.

Os hashes dos arquivos e das texturas extraídas pelo Godot constam em `../../asset_registry.json`. O ZIP não informa autor, origem ou licença; o registro mantém `UNKNOWN_LICENSE`, conforme o fluxo de desenvolvimento do projeto.
