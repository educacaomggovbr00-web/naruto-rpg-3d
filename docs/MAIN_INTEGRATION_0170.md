# Integração do main — 0.17.0

Esta versão une a evolução 0.16 (`087a410`) ao novo main (`9e473ab`), ambos derivados de `e779639`. `docs/HENRIQUE_INTEGRATION.md` foi lido antes da resolução. Nenhum modelo, personagem ou arquivo de animações foi substituído nesta integração.

## Resultado jogável

- Hitboxes consultam volumes físicos entre poses, com até oito amostras e deduplicação; verificam o último frame ativo e bloqueiam ataques através de paredes. Props destrutíveis continuam recebendo contato.
- Agarrão explícito no banco NINJA e LB + X; CPU pode pressionar guarda sustentada com a mesma técnica. Ambos cancelam o volume ao serem interrompidos. Agarrão direcional anterior e suas sequências continuam disponíveis.
- Defesa perfeita compartilhada usa janela de 120 ms, cooldown de 800 ms e deixa o atacante em recuperação. Métricas preservam a classificação de guarda antes do dano.
- Dano interrompe contato do chakra dash e limpa comandos pendentes; buffer/coyote time e cancelamentos confirmados anteriores permanecem.
- Treino repõe chakra, recupera o alvo após a sequência e reinicia KO sem recompensas. Guia, análise e três comportamentos do alvo continuam funcionando com física ativa.
- Sobrevivência preserva vida e recupera 20% da vida máxima entre duelos, registra recorde e aumenta pressão até 30%. Derrota encerra a série; reiniciar volta ao primeiro adversário.
- Touch oferece escala/opacidade salvas, limites landscape, botão de agarrão e indicadores de recarga. Ajustes ficam em OPÇÕES e na pausa, com rolagem; não há duas telas de pausa ou dois disparos por botão físico.
- CombatSettings mantém os quatro níveis de dificuldade e os comandos de equipes. Preferências antigas de controles são migradas quando o JSON atual não existe. Câmera usa uma única fonte de sensibilidade e descarta arrastes durante lock-on.
- Preview mantém resolução integral; Android Equilibrado/Alto usa MSAA 2×, Leve desativa MSAA. Modelos e rigs corrigidos permanecem.
- Preservados: 26 personagens, biblioteca de 127 clips (100 adaptações), 60 técnicas, Susanoo com 25 ossos/quatro formas, equipes de três, sete arenas, campanha do Henrique, NPCs, progressão, estados elementais e pools de efeitos/áudio.

## Validação e APK

Godot 4.7.2, Compatibility. Contrato novo: 54 verificações em headless e OpenGL; contrato integrado: 32 em OpenGL. Regressões cobrem os 47 contratos executáveis do projeto; ferramentas Python: 21 testes. Payload extraído do APK é testado sem acesso à pasta do projeto. Gate público de assets permanece independente do contrato de desenvolvimento.

APK de teste: `shinobi-clash-0.17.0-debug.apk`, `versionCode=18`, pacote `org.shinobi.narutorpg3d`.

SHA-256: `eff0d991eed37249be8df4af023fd9bef80892c1b797ead4280db6bf0057fd4a`.

Certificado debug preservado: `23b085387ea32bdd7d02de4f2fbaf0fa9830865051f0eceb6a36a21ed914d195`. Assinatura e alinhamento de 16 KB verificados. O APK local pode atualizar o 0.16 local assinado com esse certificado. Builds da CI usam certificado próprio.

Não houve teste em aparelho Android físico. OpenGL por Mesa valida shaders e apresentação, sem comprovar FPS/temperatura no celular. Este passe não entrega qualidade final de Storm 4, multiplayer, dublagem, novos rigs faciais ou publicação em itch.io. O detalhamento dos vinte pontos continua em [INTEGRATED_POLISH_0160.md](INTEGRATED_POLISH_0160.md); exigências de proveniência para release continuam aplicadas.
