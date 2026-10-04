# Sakura — modelo fornecido pelo usuário

O perfil `sakura.tres` procura primeiro:

`res://assets/characters/sakura_user/sakura_mobile_rigged.glb`

Se o arquivo não existir, o jogo mantém automaticamente
`res://assets/characters/stylized/sakura.glb` como fallback para não quebrar seleção,
CPU, previews ou testes.

## Inspeção do GLB recebido

- GLB 2.0, THREE.GLTFExporter r169
- 1 mesh / 1 skin / 1 material
- 20.856 vértices
- 107.157 índices, aproximadamente 35.719 triângulos
- 27 bones corporais Mixamo
- bounds do mesh: aproximadamente 0,89 × 1,55 × 0,53 m
- texturas PBR: diffuse, metallic/roughness e normal
- animações nativas: Bind, Idle, Walk, Run e Wave
- SHA-256 do upload original: `ef814d05c5ab4d33c15448918b9581c5c9ad5507e6401516324a7120fe131668`

A versão mobile preparada reduz somente as três texturas embutidas de 2048 para
1024 px. Mesh, skin, UVs, joints, pesos e animações são preservados.

- tamanho original: 13.621.748 bytes
- tamanho mobile: 4.365.668 bytes
- SHA-256 mobile: `fc02718a9e9409603cae00087cb1f8525f628c7f0f3c6f45f19c1e3f013cc997`

## Compatibilidade de combate

O adapter aceita rigs Mixamo compactos desde que mantenham os bones críticos de
tronco, braços/mãos e pernas/pés. Tracks opcionais de dedos/helpers que não
existirem são descartados. Como o Bone Rest deste GLB difere do rig de referência,
os clips são retargetados em runtime usando `assets/animations/mixamo_reference_rest.json`:
rotação é transferida relativa ao rest e posições são normalizadas pelo comprimento
do bone. Assim o rig compacto não recebe as transformações absolutas em centímetros
do personagem antigo.

O material texturizado mantém diffuse/normal/roughness e recebe o passe de
iluminação anime do projeto. Autoescala normaliza o personagem para 1,75 m e o
grounding alinha os pés à cápsula física.

## Publicação

Origem/licença do arquivo recebido não foi comprovada. Até haver documentação de
licença, tratar o modelo como DEVELOPMENT_ONLY e não incluí-lo em release público.
