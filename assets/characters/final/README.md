# Modelos finais do roster

Esta pasta contém os 21 modelos estilizados próprios gerados por `tools/create_roster_fighters.py`, sem alterar os cinco modelos anteriormente prontos. Geometria original, roupas/acessórios skinados, 65 ossos; fingerprints e limites em `roster_manifest.json`. O gerador recusa sobrescrever modelos existentes. A estrutura continua permitindo substituir modelos individualmente sem alterar combate, IA ou jutsus.

## Convenção de caminho

Para cada personagem, use:

`assets/characters/final/<character_id>/<character_id>_mobile.glb`

Exemplos:

- `assets/characters/final/gaara/gaara_mobile.glb`
- `assets/characters/final/rock_lee/rock_lee_mobile.glb`
- `assets/characters/final/itachi/itachi_mobile.glb`

O `RosterModelSlotFactory` já aponta para esses caminhos. Enquanto o arquivo não existir, o jogo usa `assets/characters/rigged.glb` automaticamente.

## Contrato mínimo do GLB

O modelo final precisa:

- abrir como `PackedScene`/Node3D;
- conter `Skeleton3D`;
- possuir os ossos de combate compatíveis com Mixamo: Hips, Spine, Spine1, Spine2, Head, braços, antebraços, mãos, coxas, pernas e pés dos dois lados;
- permitir retarget da biblioteca de 127 clips;
- ter pelo menos um mesh visível;
- ser adequado a mobile em triângulos, materiais e texturas;
- usar apenas assets com procedência/licença registrada antes de publicação.

Um `AnimationPlayer` embutido é opcional: o adapter cria um em runtime quando necessário.

## Fallback seguro

O `RiggedCharacterAdapter` tenta o modelo final primeiro. Se estiver ausente, não abrir, não tiver Skeleton3D, faltar ossos críticos ou falhar no retarget, ele descarta o candidato e usa o rig compartilhado.

Os acessórios procedurais e o tint do placeholder só são aplicados quando o fallback está ativo. Quando um GLB final válido entra, a identidade procedural deixa de ser aplicada automaticamente.

## Importante

Não coloque modelos comerciais extraídos ou assets sem licença verificável nesta pasta. O gate de release deve continuar bloqueando qualquer asset sem procedência autorizada.
