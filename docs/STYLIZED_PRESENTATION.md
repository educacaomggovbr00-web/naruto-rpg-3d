# Quatro personagens e apresentação mobile

2026-10-03. Godot 4.7.2 / Android landscape / gl_compatibility.

## Implementado

Quatro GLBs próprios, selecionáveis para jogador e CPU, com 65 joints Mixamo e
27 clips reais existentes. Naruto: roupa laranja/azul, cabelo amarelo, marcas nas
bochechas. Sasuke: cabelo escuro, camisa azul/shorts claros. Sakura: cabelo rosa,
roupa vermelha. Kakashi: cabelo prateado, máscara, olho coberto e colete verde.
São versões estilizadas iniciais, feitas de geometria autoral, com limitações de
rosto, mãos, costura e deformação. **Não são modelos do Storm nem visual final de
jogo comercial.** O rigged.glb original e o bake de animações foram preservados.

| Modelo | Vértices | Triângulos | GLB bytes | Superfícies |
|---|---:|---:|---:|---:|
| Naruto | 7400 | 9446 | 554176 | 1 |
| Sasuke | 6643 | 8604 | 500676 | 1 |
| Sakura | 6953 | 9580 | 526372 | 1 |
| Kakashi | 6878 | 8940 | 517732 | 1 |

Sem texturas/transparência/outline em segunda passagem. Material toon nativo
com rim leve, compartilhado também pelos clones. Um cache por hierarquia,
nomes e rest transforms permite compartilhar AnimationLibrary entre meshes
diferentes, mantendo AnimationTree independente. Novos modelos futuros com
rest diferente não reutilizam esse cache inadvertidamente.

Seleção tem um SubViewport de resolução reduzida, dois modelos animados, sem
arsenal/colisão/pools de combate. Trocar seleção remove os atores antigos;
sair do menu destrói o viewport e modelos.

Sakura/Kakashi usam Resources de moveset próprios, mas ainda compartilham
clips CC0: Sakura tem aproximação de melee pesado sem jutsu; Kakashi usa a
mecânica de Chidori como base de relâmpago. Valores de stats/dano são
OUR_APPROXIMATION; não dados oficiais de Storm. Ambos não acessam Ultimate,
Awakening ou clones de Naruto. Essas bases não substituem o trabalho futuro de
coreografia/moveset de referência. Perfis sem jutsu não indexam array vazio,
não habilitam JUT e não criam projéteis desnecessários.

Arena recebeu paredes com madeira/plaster, portão, dois halls com telhados,
árvores e sky/luz. Geometria estática agrupada por setores, menos de 20 mil
triângulos; cenários externos não usam sombras caras. Piso usa um shader
opaco autoral, sem textura externa. Treino e pátio preservam a mesma arena
física. Telhados decorativos usam camada 32 só para câmera; fighters/projéteis
continuam usando camada 1 do cenário. SpringArm detecta 1|32 também em cinematic.
LOW retira sombras/fog e setores mais externos. Combate/hitboxes não mudam.
A aldeia conserva colisões/conteúdo/save, agora com material toon; jogador usa
a mesh Naruto nova. NPCs ainda usam o rig de desenvolvimento existente.

## Validação e limites

437 checks comportamentais (315 existentes + 122 novos), contrato dos 27 clips
e nove testes Python de registry/gate. Novo contrato percorre os quatro como
jogador/CPU, reconstrói vertices skinned reais em idle/ataque/aéreo/Rasengan para
verificar deformação finita, verifica strike bone do manifesto, cache,
restrições de arsenal, UI landscape, troca/cleanup e orçamento da arena.
PCK Android é verificado isolado do checkout. Publicação continua bloqueada
pelos assets de desenvolvimento e autorização de apresentação pendente.

Revisão da geometria foi feita por render offline dos próprios meshes; import,
animação, física e Resources foram testados no Godot headless. **Headless não
valida imagem final, compilação GPU do shader ou FPS no Moto G22.** Não foi
gerado APK/AAB nesta etapa. Python/numpy só são necessários para refazer os
GLBs no desenvolvimento, nunca no telefone. Polimento comercial, coreografias
exclusivas, LOD e perfil de GPU continuam necessários.

## Checklist no aparelho

1. Selecionar os quatro: rostos/roupas distintos, preview, corpo sem partes
   abertas/invertidas; idle, corrida, salto, combo, launcher, KO e revanche.
2. Naruto/clones: mesmo visual, mãos/áreas de golpe alinhadas e fumaça limpa.
3. Sakura: JUT indisponível, melee/guarda/dash/tools funcionam. Kakashi:
   relâmpago na mão; nenhum Ultimate/clones de Naruto.
4. Arena: piso sem cintilação, paredes/portão legíveis, rotação da câmera junto
   a paredes/telhados sem atravessar, cinematic devolve câmera normalmente.
5. LOW/MED/HIGH: medir FPS/DC por 60 segundos e após cinco minutos; dois
   Narutos com clones/Rasengan. Comparar também aldeia e multitouch.
