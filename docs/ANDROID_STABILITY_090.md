# Android: estabilidade — 0.9.0

O usuário relatou encerramento inesperado. Ainda não há logcat, modelo do aparelho ou ponto exato de reprodução. Portanto, esta entrega corrige riscos identificados no código e a saída automática pelo botão Voltar; não atribui o encerramento observado a uma causa nativa já comprovada.

## Mudanças concretas

- O cache de bibliotecas retargetadas agora é LRU com no máximo quatro entradas. Antes, cada novo skeleton/rest visitado ficava retido durante toda a sessão. A expulsão remove apenas a referência do cache; AnimationPlayers ativos continuam com seus 127 clips, incluindo clones.
- A seleção reutiliza os atores que não mudaram. Alterar arena, dificuldade ou atualizar a interface não recria dois rigs; mudar apenas a CPU preserva o ator do jogador.
- Android inicia em LOW quando não existe preferência gráfica. Preferências existentes são mantidas em uma inicialização normal. O preview permanece em resolução nativa, mas não exige o framebuffer MSAA 4x no Android. Desktop mantém MSAA 4x. Não foram retirados personagens, jutsus, mapas ou sistemas de combate.
- `quit_on_go_back` fica desativado. Voltar no combate/exploração retorna à seleção; no menu abre confirmação de saída. O checkpoint de exploração usa o mecanismo de save existente antes de sair; pausa e escala de tempo são restauradas.
- Um marcador de sessão em primeiro plano guarda a última cena. Ao reiniciar após uma interrupção sem encerramento normal, apenas a qualidade gráfica é selecionada para LOW, com aviso no menu; o progresso e demais configurações permanecem. Pausar o aplicativo remove o marcador, porque o Android pode encerrar normalmente processos em segundo plano. Retomar o aplicativo recria o marcador. Isso detecta interrupção, não identifica a causa do crash.
- `user://runtime_stability.log` registra a versão, a última cena da sessão interrompida, renderer e memória estática nas mudanças de cena. O arquivo é limitado a aproximadamente 64 KB por sessão. Não contém dados pessoais. O registro não captura crashes que ocorram antes da inicialização dos autoloads nem mede memória de GPU.

## Validação

Godot **4.7.2**, Compatibility. Os 36 contratos anteriores passaram. O contrato novo passou em **89 verificações**, incluindo 26 trocas de CPU, limite do cache, conservação do ator e da biblioteca ativa após expulsão, recuperação sem apagar outras preferências, confirmação de saída e retorno batalha/menu. Também passou em OpenGL/Mesa com o conteúdo extraído do APK, fora do checkout. Os 21 testes Python e o registro de assets passaram. Os workflows executam o contrato novo em headless e OpenGL.

O primeiro ensaio do contrato novo aguardava `frame_post_draw` também em headless e ficava pendente. A condição foi corrigida para verificar o DisplayServer; o contrato foi executado novamente e passou. Nenhuma regra de gameplay foi alterada para contornar o teste.

## APK para teste

- `shinobi-clash-0.9.0-debug.apk`, ARM64, Android 7+ (`minSdkVersion 24`), versionCode **10**.
- Assinatura v2/v3 e alinhamento de 16 KB verificados. Mesma chave debug dos APKs locais anteriores; atualização mantém os dados da instalação.
- SHA-256: `8323b050a7273f7aafb45f6d187fca1b2631f98efb483f2fa85bfb0d2fe63d6f`.
- Contrato do pacote Android e teste de estabilidade/OpenGL executados a partir dos arquivos efetivamente extraídos deste APK.

Ainda é necessário testar no aparelho que apresentou a falha. Se continuar fechando, registrar modelo, momento exato e logcat (`adb logcat -b crash`) para distinguir erro de script, driver gráfico, falha nativa e encerramento por memória. A ausência desses dados impede confirmar que esta versão resolve aquele encerramento específico.
