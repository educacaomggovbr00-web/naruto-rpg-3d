# Shinobi Clash 0.4.0 — validação e teste

Base preservada: main e779639, continuada no branch codex/henrique-combat100-android.
Leia HENRIQUE_INTEGRATION.md e SHINOBI_CLASH_EVOLUTION.md para escopo e pendências.

## APK de teste

- Arquivo: shinobi-clash-0.4.0-debug.apk; pacote org.shinobi.narutorpg3d.
- versionCode 4, versionName 0.4.0-shinobi-evolution, label Shinobi Clash.
- Debug ARM64, Android 7.0/API 24 ou superior. Não é build público final.
- SHA-256: c7c215c5d494e2a26bb122396c7d7d3f1de0dd486b6aa7af2bf9c607b9ae3b61.
- Assinaturas v2/v3, integridade ZIP e zipalign 4 bytes / páginas 16 KB passaram.
- Conteúdo extraído e carregado fora do checkout: modelos, elenco, mundo,
  campanha, controles, sete arenas, quatro formas, roupas e status passaram.
- 17 testes Python passaram; registro de assets e git diff --check passaram.
- Godot 4.7.2; capturas em OpenGL Compatibility/Mesa llvmpipe, sem benchmark móvel.
- Não houve instalação nem teste em aparelho Android físico nesta sessão.

## Conferir a versão e as diferenças

1. Instale o APK 0.4.0. O menu precisa mostrar 0.4.0; um menu 0.3.0 é outro build.
   Preserve o save existente; não desinstale apenas para trocar uma versão debug.
2. Selecione Henrique contra Naruto, arena Floresta, depois Vale/Esconderijo/Ruínas.
3. OPÇÕES → Henrique/Roupa alterna original, lenço e colete; confira no preview.
4. Use NINJA → seleção de jutsu para percorrer os sete poderes em versus/treino.
   Na história, os novos poderes dependem dos marcos existentes.
5. Nagashi abre área em volta; Amaterasu deixa chamas temporárias e dano periódico;
   Genjutsu causa hitstun e distorce a visão quando atinge o jogador; onda Katon
   é ampla e não persegue. Verifique defesa/esquiva/substituição e obstáculos.
6. Desperte com vida ≤50%, chakra cheio, no chão e sem ação. Invocação atravessa
   formas; enquanto ativo, AWK/6/direcional direito alterna a forma. Em LOW/MEDIUM
   as asas não aparecem; em HIGH aparecem apenas no perfeito.
7. Confira trilhas diferentes na exploração, luta e desafios de chefes; SOM
   e volume devem controlar também a música.
8. Após derrota/revanche, não podem permanecer chamas, distorção nem avatar.
9. No Android registre modelo/API, versão exibida, instalação, multitouch,
   pause/resume, controle Bluetooth e FPS/temperatura em partidas de 10 minutos.

## Limites de apresentação

Cenários procedurais e acessórios são protótipos visuais. O rosto não tem rig
facial, os 100 clips continuam adaptações CC0, as duas primeiras formas usam
nós articulados e não skins novas, e as músicas são loops instrumentais curtos.
Dublagem, modelagem final, campanha cinematográfica e toda a lista de evolução
não estão concluídas. O plano registra critérios objetivos para essas entregas.
