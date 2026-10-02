# Fontes de animação pesquisadas

## Quaternius — Universal Animation Library

- Fonte: https://github.com/J-Ponzo/gltf-universal-animation-library
- Autor original: Quaternius
- Licença: CC0 1.0
- Conteúdo: versão Standard gratuita da Universal Animation Library, com dezenas de animações humanoides.
- Situação neste projeto: **não embutida diretamente no personagem Mixamo** porque o pacote usa outro esqueleto/bone rest. Aplicar os clips sem retarget correto deformaria o personagem.
- Uso futuro: referência para retarget/bake quando o pipeline de retarget estiver pronto.

## avatar-stage

- Fonte: https://github.com/rana-jatin/avatar-stage
- Autor: Jatin Rana
- Licença: MIT
- Relevância: detecta rigs Mixamo e demonstra uma biblioteca de animações procedurais geradas em runtime.
- Situação neste projeto: serviu como referência técnica para a estratégia de gerar movimentos diretamente no rig do personagem, evitando depender de arquivos de animação redistribuídos.

## Adobe Mixamo

Mixamo continua sendo uma boa fonte para baixar animações para uso dentro de jogos. Porém, a orientação pública da Adobe permite o uso em projetos e restringe a redistribuição dos arquivos brutos de animação. Por isso, este repositório não incorpora downloads brutos do Mixamo.

## Implementação usada

O projeto gera sua própria biblioteca `proc/` em GDScript no carregamento do personagem.

Clips atuais:

- `proc/idle`
- `proc/run`
- `proc/air`
- `proc/attack_1`
- `proc/attack_2`
- `proc/attack_3`
- `proc/attack_4`
- `proc/air_attack_1`
- `proc/air_attack_2`
- `proc/air_attack_3`
- `proc/air_attack_4`
- `proc/guard`
- `proc/dodge`
- `proc/chakra_dash`
- `proc/chakra_charge`
- `proc/jutsu`
- `proc/hit`
- `proc/defeat`

Esses clips usam o Bone Rest real do GLB importado e os paths de osso descobertos nas animações do próprio arquivo, então foram feitos especificamente para conviver com o esqueleto `mixamorig:*`.

Quando um clip real compatível for adicionado ao GLB com um nome reconhecível, o adapter prefere o clip real e usa o procedural apenas como fallback.
