# Inicialização e menus — 0.10.0

Continuação das correções Android da 0.9.0. O encerramento relatado no aparelho ainda não tem reprodução nem logcat; estas mudanças corrigem o fluxo de carregamento e ampliam as opções de estabilidade, sem atribuir o crash a uma causa já confirmada.

## Implementação

- `boot.tscn` é a primeira cena: não possui meshes, animações ou pools. A seleção só começa a carregar depois que a interface leve foi criada. O contrato verifica que a biblioteca de combate ainda não está carregada nesse ponto.
- GameFlow exibe uma tela 2D, bloqueia solicitações repetidas, desativa a cena anterior e a libera antes de solicitar os recursos da próxima. Em OpenGL, aguarda também a limpeza do quadro de renderização. O framebuffer 3D fica sem MSAA durante a troca; a cena de destino aplica sua preferência gráfica normalmente.
- A tela mostra etapas reais da transição, dicas de combate e ações para tentar novamente ou voltar ao menu se o carregamento falhar. Pausa e escala de tempo são restauradas. A inicialização do boot não pode ser confundida com a conclusão do destino solicitado.
- Carregamento de recursos e instanciação permanecem na thread principal. Há frames entre as etapas para exibir a interface e limpar a cena; isso não garante ausência de bloqueios dentro de uma etapa pesada. O pipeline não carrega scripts de gameplay em threads concorrentes.
- OPÇÕES apresenta Leve, Equilibrada e Alta, com descrição. A preferência compartilhada usa escrita temporária/rename e rejeita valores inválidos. Combate, aldeia e todas as regiões consultam a mesma rotina: o default Android LOW também vale fora de Konoha. Preferências válidas existentes permanecem.
- A janela de opções agora tem rolagem e altura limitada para manter os controles e o botão OK acessíveis em 720p.
- O menu conserva os dois personagens e a arena da sessão anterior. O preview já nasce com essa dupla, evitando carregar temporariamente Henrique/Naruto quando outros personagens estavam selecionados.
- O marcador Android registra o destino antes do carregamento, para distinguir uma interrupção nesse estágio. O manager das regiões tem UID estável registrado; o pacote não depende do fallback para um identificador antigo.

Modelos, 26 personagens, 127 clips, jutsus, danos, custos, hitboxes, dificuldade, missões, inventário e save v1 preservados. Os limites de cache da 0.9.0 continuam ativos. Não há novos modelos ou gravações de animação nesta etapa.

## Validação e evidências

- Godot **4.7.2**: 38 contratos de regressão passaram; 21 testes Python passaram.
- Contrato de carregamento: **50 verificações** em headless e OpenGL, incluindo boot, sete transições, liberação da cena anterior antes da solicitação, comandos repetidos, preferências malformadas, persistência, altura de opções, dupla/arena lembradas e rigs com 127 clips.
- Testes existentes aguardam a conclusão de GameFlow antes de suas verificações de gameplay. As verificações de combate anteriores foram mantidas.
- Contrato do pacote e contrato de carregamento/OpenGL passaram usando apenas arquivos extraídos do APK, fora do checkout. Registro de assets e diff-check passaram.
- Capturas reais no Godot/Compatibility/Mesa: [carregamento](captures/loading_0100.png) e [opções](captures/options_0100.png). Não são benchmark de Android.

## APK

`shinobi-clash-0.10.0-debug.apk`, ARM64, Android 7+, versionCode **11**, versão `0.10.0-loading`. Assinatura v2/v3 e alinhamento de 16 KB verificados. Mesma chave debug dos APKs locais anteriores, permitindo atualizar a instalação sem mudar o formato dos saves.

SHA-256: `593bee3947484d1c738767aea17b5dcf5ec57339bd1c61b2bdc18e49ebe50c45`.

Teste no aparelho que apresentou o fechamento continua pendente. Modelo do celular, ponto exato da falha e logcat ainda são necessários para confirmar correções de driver, falha nativa ou encerramento por memória. O fluxo novo não evita uma falha do processo ocorrida antes do boot/autoloads.
