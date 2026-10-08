# Henrique Uchiha: integração

## Estado entregue

- Protagonista inicial e da campanha: Henrique Uchiha. Seleção tem 26 personagens; os 25 anteriores continuam nos mesmos índices e com os mesmos modelos/kits.
- Fonte do Henrique: `3970037e-fd4c-4114-b9f6-75905e547ff4.zip`, PBR GLB sem skeleton, skin ou animações. A integração usa realmente essa malha, não o ninja genérico.
- Saída: `assets/characters/henrique/henrique_mobile_rigged.glb`, 3.228.368 bytes, 21.707 vértices, 15.398 triângulos, 65 ossos e quatro influências normalizadas por vértice. Texturas de até 1024 px.
- Cabeça chibi rígida e landmarks específicos do upload, ajuste offline para T-pose. `RiggedCharacterAdapter` retargeta as 27 animações existentes para as proporções do novo skeleton; player, CPU, menu e exploração compartilham clips preparados, com playback independente.
- Combos terrestres, aéreos e branches próprios; Katon, Chidori, despertar Susanoo, corte de área e Ultimate de entrada confirmada. Todos usam os hitboxes, guarda, substituição, interrupção, pools e câmera existentes.
- Despertar: HP ≤50%, chakra cheio, no chão e sem outra ação; consome chakra, transforma em 0,85 s, dura 14 s, movimento ×1,08 e dano ×1,30. Interrupção durante transformação, KO, reset ou expiração removem o avatar; cooldown 18 s. A câmera recua 1,2 m apenas enquanto Henrique transforma/está transformado.
- Corte exige despertar ativo; a área só abre no momento de impacto da animação e um alvo não recebe dano repetido do mesmo hitbox. Ultimate custa 80 chakra e não pode começar durante despertar; mantém os contratos de entrada, guarda, miss, lock e cancelamento do controlador existente.
- Save versão 1 preservado. Na campanha, os marcos `demon`, `clones`, `barrage` correspondem a Katon, Chidori e corte Susanoo; versus/treino mantêm o kit completo. Diálogo do protagonista usa Henrique; missões, adversários, recompensas, inventário, skills e mapa não foram substituídos.

## Susanoo pronto

Modelo escolhido: [Perfect susanoo](https://sketchfab.com/3d-models/perfect-susanoo-c1ef38744eb64891b26a6f41aac1b199), por [wahidinesport](https://sketchfab.com/wahidinesport), anunciado sob [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

O arquivo de preservação contém glTF, binário, texturas e `license.txt`. O título, autor e licença foram conferidos também nos metadados públicos da API do Sketchfab. O arquivo original tem 34.098 triângulos e **não contém skin ou animações**. A saída GLB tem 11.961 triângulos e 564.144 bytes. O jogo aplica material de chakra violeta e anima uma lâmina própria; a armadura estática acompanha o protagonista e pulsa. As asas largas aparecem somente em HIGH para preservar a leitura do combate em celular.

A atribuição original está em `assets/susanoo/LICENSE.txt`, `THIRD_PARTY_NOTICES.md`, e no botão CRÉDITOS da seleção. O arquivo de licença está incluído no export Android. `source_manifest.json` registra a origem e os fingerprints.

O registro conserva DEVELOPMENT_ONLY e o gate público existente: a licença declarada pelo uploader não comprova os direitos de apresentação da franquia, e a licença de geração do modelo fornecido pelo jogador não foi enviada. Nenhuma liberação pública adicional foi presumida.

## Reprodução

A fonte original do Henrique fica fora do Git. Recriar com numpy, scipy, Pillow e gltfpack **1.3**:

```sh
python3 tools/rig_henrique.py --source /caminho/base_basic_pbr.glb --gltfpack /caminho/gltfpack
```

O script confere o SHA-256 do upload antes de gerar a malha. O skeleton de referência e a biblioteca são os já presentes no projeto. Fingerprints da fonte e saída ficam em `rig_profile.json` e `asset_registry.json`.

Converter o download glTF do Susanoo com gltfpack 1.3:

```sh
gltfpack -i /caminho/scene.gltf -o assets/susanoo/susanoo_mobile.glb -si 0.30 -se 0.004 -sp -sv -noq -kn -ke
```

## Validação

Godot **4.7.2.stable.official.ed1daf0bf**, Linux:

- Importação sem SCRIPT ERROR ou ERROR.
- **26 contratos GDScript passaram**, incluindo o novo `henrique_contract.gd`, regressões de Naruto, elenco, CPU, combos, câmera, campanha e exploração.
- O contrato Henrique testa a skin real em três fases de cada uma das 27 animações, pesos, bounds, movimento efetivo, dois skeletons independentes, modelo Susanoo externo, qualidade, transformação, dano, expiração, interrupção, jutsus, Ultimate e campanha.
- **13 testes Python passaram**, incluindo o gate de assets e ferramentas de pesquisa existentes.
- Registro de assets e `git diff --check` passaram.
- Export **Android PCK** carregado isoladamente fora do checkout: elenco, mundo, regiões e Henrique/Susanoo/atribuição passaram. Isso verifica o conteúdo do pacote, **não equivale a testar um APK em um aparelho Android**.
- Captura OpenGL Compatibility com llvmpipe: modelo enviado e armadura pronta aparecem juntos. FPS da captura em software não é um benchmark de celular.
- Novo contrato adicionado ao workflow existente, fixado no Godot 4.7.2.

![Henrique transformado em Susanoo no Godot](captures/henrique_susanoo.png)

Limitações: rig é um ajuste inicial específico da malha, ainda refinável em ombros/mangas/mãos. Susanoo não tem animação esquelética própria; aura e lâmina são animadas pelo jogo. APK, instalação, toque e desempenho em aparelho Android físico não foram verificados neste ambiente.
