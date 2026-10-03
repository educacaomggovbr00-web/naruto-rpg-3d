# Fontes de assets

## Integrados
- Quaternius UAL 1/2 Standard, CC0: clips reais já retargetados. Ver ANIMATION_SOURCES.md e manifestos com hashes. Compartilhados com clones; nenhum download runtime.
- Modelo rigged.glb fornecido anteriormente pelo usuário: licença permanece sob responsabilidade/origem do arquivo; nenhuma aquisição nova de modelo proprietário.
- Fūma shuriken, esfera de chakra, anéis/trails e fumaça: meshes originais geradas pelo código deste repositório, sem asset comercial, shaders unshaded compatíveis com Android.

## Pesquisados, não importados
- [Kenney Particle Pack](https://kenney.nl/assets/particle-pack): 80 sprites de VFX, CC0. Boa opção para acabamento futuro; fase atual prioriza pooling de meshes opacas, sem aumentar overdraw/transparências.
- [Quaternius UAL](https://quaternius.com/packs/universalanimationlibrary.html): animações CC0; as fontes já vendorizadas são suficientes para o protótipo de clones.

Não foi localizado nesta pesquisa um pacote reutilizável com a coreografia exata de Rasengan/Barrage e licença apropriada. Usa-se a animação real disponível como placeholder documentado, nunca download/rip de Storm. Na fase inicial ainda não havia áudio; a revisão de seleção abaixo adiciona SFX. Música permanece pendente.


## Revisão Ultimate/Awakening/mundo

- Shaders chakra_core/chakra_shell/chakra_tail, órbitas instanciadas, cauda contínua, ferramentas e dados de Ultimate: código/meshes originais deste projeto. Sem downloads runtime; 1 shell aditiva no MED/HIGH e nenhuma no LOW. Orçamento de órbitas 4/8/12; efeitos ativos 12/24/32; pools não crescem.
- [Kenney Modular Buildings](https://kenney.nl/assets/modular-buildings): autor Kenney, CC0 indicado na página primária. Pesquisado, não importado; não equivale ao mapa de Konoha.
- [KayKit Medieval Hexagon Pack](https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0): autor Kay Lousberg, [licença CC0 no repo](https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0/blob/main/LICENSE.txt). Pesquisado, não importado; arquitetura temática distinta.
- [Godot demo projects](https://github.com/godotengine/godot-demo-projects): MIT, referência técnica para resolução/renderização, não copiado nesta revisão.

O registro `assets/asset_registry.json` cobre arquivos runtime e hashes das texturas extraídas do GLB. Essas texturas herdam UNKNOWN_LICENSE do arquivo fornecido; sua ausência antes de importar é esperada. Arquivos novos/alterados exigem registro/revisão. Python valida o gate antes do export; plugin do editor protege o preset public_release. Nenhum modelo/animação de Naruto, Sasuke, Sakura, Kakashi ou Konoha foi encontrado com proveniência apropriada para importação nesta pesquisa. Assets genéricos CC0 não comprovam autorização de distribuição de personagens/marcas; o campo de apresentação pública continua não autorizado.

## Aldeia — revisão 2026-10-03

- `scripts/world/world_mesh_builder.gd`: geometria autoral do projeto, cores por vértice, fachadas, telhados, escadas, pontes, balcão e relevos; nenhuma mesh/textura do Storm foi importada. Conteúdo original, SAFE_FOR_RELEASE quanto à origem da geometria; autorização da apresentação pública continua pendente no gate existente.
- Kenney Modular Buildings foi conferido novamente na página primária (CC0). KayKit Medieval Hexagon teve LICENSE.txt conferido no GitHub (CC0). Não foram importados: não oferecem Konoha ou Naruto próprios da referência.
- `guto-alves/naruto-game` foi inspecionado no GitHub: aplicativo Android; não foi comprovado pacote 3D próprio/autorizado de personagem ou aldeia do Storm. MIT de código de outro repositório não foi tratado como autorização para redistribuir assets comerciais.
- O rig fornecido continua UNKNOWN_LICENSE, inclusive no mundo; não foi substituído por download não autorizado. Nenhum novo modelo proprietário foi adquirido.

## Pesquisa técnica Storm / Jump Force — 2026-10-03

As ferramentas/formatos listados em `STORM_MOVES_DATA.md` foram referências de estrutura, sem código/binaries/PRM/ANM comerciais copiados. UE4SS possui MIT; Unverum GPL-3.0; vários outros repositórios consultados não expõem licença raiz. Licença da ferramenta não licencia assets do jogo.

`assets/combat/naruto_moveset.tres` e `demon_wind_projectile.tres`: dados originais do projeto, SAFE_FOR_RELEASE quanto ao arquivo de configuração; nomes/apresentação/modelo continuam sujeitos ao gate separado. Dano/tempo/distâncias são OUR_APPROXIMATION. Nenhum novo asset externo foi baixado.

## Seleção, Sasuke e áudio — 2026-10-03

- [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds): CC0 1.0, conferido na página primária e em License.txt do ZIP oficial. Integrados sem alterar o arquivo: impactPunch_medium_000, impactPunch_heavy_000, impactMetal_light_000, footstep_concrete_000, footstep_grass_000. Fonte ZIP: https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip .
- [Kenney Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds): CC0 1.0, página/licença do ZIP verificadas. forceField_000, thrusterFire_000, explosionCrunch_000 são SFX temporários de energia/dash/fumaça; não são áudio Naruto. Fonte ZIP: https://kenney.nl/media/pages/assets/sci-fi-sounds/6b296f9ecf-1677589334/kenney_sci-fi-sounds.zip . Licenças locais em assets/audio/kenney/LICENSE_*.txt; hashes no registro. Oito OGG somam 297328 bytes (~290 KiB).
- CharacterDefinition/Resources, Fireball e VFX elétrico/fogo são autorais. SAFE_FOR_RELEASE quanto ao conteúdo original dos arquivos, sem alterar o gate de apresentação/modelo.
- [Naruto por RodrigoXP](https://blendswap.com/blend/17083): candidato fan art CC-BY (Blender 2.7), não importado; comentários públicos indicam ausência de bones/rig, e o arquivo não foi obtido/validado tecnicamente. CC-BY anunciado por uploader não resolve automaticamente direitos da personagem.
- Resultados [Asif20 Naruto 2942](https://blendswap.com/blend/2942), [2945](https://blendswap.com/blend/2945), [Sasuke 2946](https://blendswap.com/blend/2946) são armas (kunai/shuriken/fūma), não GLBs dos personagens. Não foram usados como falsos substitutos.
- Nenhum novo GLB/retrato comercial foi baixado. O rig fornecido segue preservado e UNKNOWN_LICENSE; perfis usam model_path configurável e o mesmo adaptador Mixamo. Conversão/rigging de modelos futuros deve ocorrer no pipeline de desenvolvimento, nunca no Android.

## Quatro meshes próprias estilizadas — 2026-10-03

`assets/characters/stylized/{naruto,sasuke,sakura,kakashi}.glb` são geometria original gerada offline por `tools/create_stylized_fighters.py`: corpo, rosto, olhos, cabelo e roupa em uma superfície opaca com vertex colors. Nenhuma geometria/textura/animação de Storm foi baixada. Apenas os 65 transforms/joints de corpo do rig fornecido foram preservados para o retarget existente. O rig original não foi modificado. Licença da apresentação dos personagens e origem do skeleton não estão liberadas para publicação: arquivos classificados **DEVELOPMENT_ONLY**, com SHA no registry. Não confundir com modelos oficiais ou qualidade final.

Pesquisa adicional: Sasuke fanart rigado https://blendswap.com/blend/17887; Kakashi fanart https://blendswap.com/blend/29331; Naruto/Sasuke low poly https://sketchfab.com/3d-models/naruto-sasuke-low-poly-rig-texture-b650b60a7bbd4f11b05a435e65116168. Candidatos não importados: download/rig/proveniência não foram verificados em conjunto. Não tratamos licença de fanart ou rótulo “free” como autorização para distribuir assets extraídos de jogos.

Toon usa o material nativo do Godot, sem código externo copiado: https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html. Arena/piso/sky e material são autorais; detalhes completos em STYLIZED_PRESENTATION.md.


Booby Trap (2026-10-03): geometria de duas kunai, fio, bola e espinhos criada em `scripts/booby_trap.gd` com meshes nativos Godot. Nenhum asset externo/rip. JutsuDefinition `.tres` são configurações autorais; comportamentos referenciados em STORM_MOVES_DATA e números OUR_APPROXIMATION.

## Ferramentas Storm 1 pesquisadas — 2026-10-03

- [roqols/NUNSMOD](https://github.com/roqols/NUNSMOD): raiz Apache-2.0; pesquisado para CPK/XFBIN, `nuccChunkBinary` e `CommandChartData.xfbin`. Não vendorizado. O projeto informa que sua cópia de `xfbin_lib`/PyBinaryReader é MIT.
- [Lyingcake77/NUNS_Meshswap_tool](https://github.com/Lyingcake77/NUNS_Meshswap_tool): ferramenta antiga de mesh swap que procura seções `NDP3`; somente referência técnica, não integrada ao runtime.
- [AkikoKumagara/Naruto-STORM-1-PS-Icons](https://github.com/AkikoKumagara/Naruto-STORM-1-PS-Icons): usado apenas para confirmar a organização pública `data_win32/interface`; nenhuma textura foi incorporada.

Foram adicionados somente scripts autorais de **inventário/normalização de metadados**. Eles não contêm assets, textos extraídos do jogo nem código copiado das ferramentas acima. Arquivos brutos fornecidos pelo usuário ficam fora do Git em `external/storm1_raw/`.
