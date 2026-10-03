# Fontes de assets

## Integrados
- Quaternius UAL 1/2 Standard, CC0: clips reais já retargetados. Ver ANIMATION_SOURCES.md e manifestos com hashes. Compartilhados com clones; nenhum download runtime.
- Modelo rigged.glb fornecido anteriormente pelo usuário: licença permanece sob responsabilidade/origem do arquivo; nenhuma aquisição nova de modelo proprietário.
- Fūma shuriken, esfera de chakra, anéis/trails e fumaça: meshes originais geradas pelo código deste repositório, sem asset comercial, shaders unshaded compatíveis com Android.

## Pesquisados, não importados
- [Kenney Particle Pack](https://kenney.nl/assets/particle-pack): 80 sprites de VFX, CC0. Boa opção para acabamento futuro; fase atual prioriza pooling de meshes opacas, sem aumentar overdraw/transparências.
- [Quaternius UAL](https://quaternius.com/packs/universalanimationlibrary.html): animações CC0; as fontes já vendorizadas são suficientes para o protótipo de clones.

Não foi localizado nesta pesquisa um pacote reutilizável com a coreografia exata de Rasengan/Barrage e licença apropriada. Usa-se a animação real disponível como placeholder documentado, nunca download/rip de Storm. Áudio e músicas não fazem parte desta fase.


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
