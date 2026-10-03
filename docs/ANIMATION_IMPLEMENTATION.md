# Auditoria e implementação de animações

## Estado inicial

Base: `6753598aa6ee52deb3338b2a0f1597c40fc5cffd`, branch main, 88 commits. Foram lidos todos os arquivos rastreados, o GLB binário (nodes, skins, inverse binds, animations), o histórico completo e os diffs do adapter. Não havia AGENTS.md, testes ou CI.

As fases anteriores criaram movimento/câmera mobile, combate completo, hitboxes, combo aéreo, bounces e feedback. A integração rigada começou em `6277254`; `ac9eb66` acrescentou o GLB real. `260be85` a `6d83ee6` tentaram preencher clips por movimentos procedurais. Nenhum acrescentou animações externas reais.

## Causas verificadas no Godot 4.7.2

- GLB: apenas `happy`, 2,9667 s; duas skins, unificadas no Skeleton3D importado de 102 ossos.
- Godot sanitiza `mixamorig:Hand` para `mixamorig_Hand`. O código antigo buscava nomes com `:`; hitboxes não encontravam mãos/pés e o gerador não reconhecia os canais.
- A pose de nó do GLB não é a pose de bind. Retarget usa os inverse bind matrices da skin de 65 ossos Mixamo, não a pose de `happy`.
- StateMachine não tinha transições: `travel()` não oferecia o crossfade esperado.
- Cooldown permitia reiniciar o ataque antes do fim; dodge, substituição, stagger e KO deixavam janelas de hitbox ativas.
- Lunge podia atravessar o alvo; blends em andamento atrasavam ataques rápidos.
- Jutsu aplicava dano no input, antes do gesto de disparo.
- Ocultar o visual de primitivas também removia a aura de chakra.

## Pipeline

Extratos de animação das fontes CC0 fixados no repositório, com licenças e hashes. `source/extraction.json` registra os hashes dos downloads originais; `tools/extract_animation_sources.py` preserva os canais sem alterar valores de movimento. Python lê canais glTF e interpola rotações com SLERP a 30 Hz. As duas famílias de ossos (DEF/Rigify e UE-style) são mapeadas para Mixamo, incluindo dedos e toes. O T-pose da fonte define a referência. A correção global de cada osso é:

`target_pose_global = alignment * source_pose_global * inverse(source_T_pose_global) * inverse(alignment) * target_bind_global`

Rotação local é recuperada pelo inverso do pai. O alvo usa centímetros; comprimento/translação de cada osso vêm do bind do alvo. A yaw de 180° alinha a fonte +Z com o alvo -Z; o yaw do modelo em jogo o alinha com o forward +Z do controlador. Translação horizontal da pelvis é limitada para não duplicar o movimento do CharacterBody3D. A raiz do salto é controlada pela física; KO preserva a queda da pelvis.

As variantes aéreas usam o movimento superior dos golpes e as pernas do NinjaJump. Launcher adapta a trajetória do hook para cima. Slam recorta o golpe descendente final do combo pesado e não instancia espada. Fontes, recortes, durações, loops, startup e mãos constam no manifest.

Não há retarget por frame, dependência de Blender em Android ou construção de poses simplificadas por GDScript. O arquivo procedural antigo foi removido; o visual de primitivas fica como recurso de emergência para falha de asset.

## Integração

- Biblioteca `combat/` com seleção por estado exato, sem fuzzy matching e sem happy como idle.
- AnimationTree em avanço manual de física; AnimationNodeTimeScale para ajustar jog/sprint à velocidade.
- Transições dirigidas de todos os estados, crossfade de 25 ms para ataques, 35 ms para hit/dodge, 80 ms para demais estados.
- `next()` permite interromper uma transição anterior; action ID reinicia one-shots repetidos.
- Jump/fall separados por velocidade vertical, pouso curto, morte sem loop até respawn.
- Hitbox lê a mão correspondente ao clip e atualiza após a pose, antes da consulta de overlap; sem consulta imediata a overlap antigo ao ativar.
- Duração do ataque e frame de impacto partem do manifest; cooldown cobre a duração toda.
- Cancelamento fecha a janela de ataque; jutsu só aplica dano em 0,24 s e pode ser interrompido.
- Lunge para a 1,15 m do alvo. Suspensão aérea cobre a duração da animação.
- Aura de chakra reparentada ao adapter para sobreviver à ocultação das primitivas.

## Validação

Executado com `4.7.2.stable.official.ed1daf0bf`: importação, execução da cena e teste de contrato. Todos os 22 clips têm 130 canais (posição + rotação em 65 ossos), quaternions normalizados e movimento em múltiplos ossos. Testes de combate usam física real e AnimationTree, incluindo acertos de hitbox, launcher/slam, cancelamentos, repetição, jutsu e KO/respawn. As silhuetas em três instantes por clip foram renderizadas por CPU a partir das poses avaliadas no engine e revisadas.

A CI repete importação e contrato na mesma versão. Fontes e ferramentas de bake ficam fora do pacote Android através de `.gdignore`.

## Limitações reais

Este conjunto resolve a ausência de animações reais; não equivale à qualidade de um jogo comercial com animação dedicada. Guarda deriva de uma postura de escudo (sem asset de escudo); chakra/jutsu são gestos genéricos de magia; launcher e golpes aéreos são adaptações declaradas. Os clips de jog/sprint são frontais: strafe em lock-on ainda pede clips direcionais dedicados. `knockback` está disponível na biblioteca, mas o controlador atual usa `hit` para stagger comum. O inimigo ainda é o dummy original. Android/renderer OpenGL e FPS em hardware real não foram medidos nesta execução headless.

## Atualização Storm 1 — 2026-10-02

Base auditada: main `41ac201`; histórico de 90 commits, scripts/cena/fontes/manifestações revisados antes da edição. Biblioteca agora tem 27 estados (20 clips-fonte): variantes de jog lateral e reverso, cross para Rasengan, Idle_Shield_Break. Variantes são adaptações de material real, não coreografia final de Naruto. Manifesto de golpes explicita startup/active/recovery e cancel windows; bake reproduz esses campos.

Jutsu de dano por distância foi removido: Demon Wind tem swept sphere e colisão com mundo/hurtboxes; Rasengan usa Area3D no osso; clones têm Skeleton3D independente, AnimationPlayer manual e hitbox nos ossos com fonte redirecionada ao jogador. Pool de três clones/projéteis e 32 efeitos reutilizados. Barrage só segue após o primeiro contato limpo e sempre restaura câmera/controle em erro, cancelamento ou KO. CPU básica recebe guard meter e substituição probabilística atrasada, sem acesso ao input do jogador; a etapa CPU Fighter rigada continua posterior.

Validação adicional: contrato Storm com colisão real, acerto/whiff/bloqueio/cenário, cancelamentos, câmera, bounded pools e recursos. PCK Android foi exportado e executado separadamente do projeto: manifesto/27 clips/clones presentes; fontes e testes ausentes. Não foi exportado APK nem medido FPS real. Inspeção CPU das 27 poses não substitui revisão visual do renderer no aparelho.
