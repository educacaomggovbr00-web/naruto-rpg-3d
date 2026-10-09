# Passe de melhorias — 2026-10-08

Registro da implementação que chegou ao main em `9e473ab`. Na integração 0.17, a evolução posterior dos rigs, equipes, arenas e modos também foi preservada. Estado atual: [MAIN_INTEGRATION_0170.md](MAIN_INTEGRATION_0170.md).

Implementação sobre o combate, elenco de 26 slots, campanha do Henrique e assets existentes. Ajustes de gameplay autorais (`OUR_APPROXIMATION`), sem alegar frame data de Storm. Mantidos Godot 4.7.2, landscape e Compatibility.

## O que muda ao jogar

Seleção oferece Versus, Treinamento e Sobrevivência, além de três dificuldades. AJUSTES permite salvar sensibilidade de câmera, escala/opacidade do touch, tremor e comportamento do dummy. PAUSA/Start/Esc/back Android congela a simulação e libera dedos, carga, defesa e filas. Perda de foco pausa a batalha; a retomada é explícita.

Treino não consome os itens ou dá recompensas da campanha. O alvo recupera vida depois que o contador de combo termina; KO reinicia a tentativa. Chakra do jogador é infinito. Dummy pode ficar parado, defender ou lutar.

Sobrevivência usa o elenco existente sem criar outros controladores. Vitória abre PRÓXIMO OPONENTE: preserva a fração de vida restante e adiciona 20% da vida máxima. Chakra, substituições e ferramentas iniciam um novo duelo. O ritmo de decisão da CPU cresce até 30%, mantendo dano/timing/colisões comuns. Derrota encerra a sequência; RECOMEÇAR restaura o primeiro oponente escolhido. `survival_best` é um campo compatível no save v1; preferências ficam em `user://controls.cfg`.

Agarrão usa volume de contato, startup de 0,18 s, janela ativa de 0,10 s, recuperação e cooldown de 1,1 s. Defesa perfeita existe na camada compartilhada de hitbox: janela de 0,12 s ao levantar guarda, cooldown de 0,8 s, recuperação de 5 chakra/8 guarda e atacante em reação por 0,32 s. Não reflete projéteis nem dispara finalização. Clips já existentes representam a ação; poses dedicadas continuam pendentes.

## Cobertura dos 20 tópicos solicitados

| Área | Entrega neste passe | Trabalho restante |
| --- | --- | --- |
| 1. Combate | Varredura de hitbox, último frame ativo, paredes, interrupção de dash, agarrão, defesa perfeita | Coreografias dedicadas; balanceamento competitivo de cancel/juggle |
| 2. Movimentação | Buffer de salto, sticks analógicos e liberação de holds na pausa | Wall run e mais transições direcionais |
| 3. Animações | Técnicas usam clips/AnimationTree existentes; corrigido tempo de ataque do Henrique CPU | Clips próprios de agarrão, facial e personagens |
| 4. IA | Três dificuldades; perfis duplicados por instância; pressão de agarrão cresce ao observar defesa sustentada | Adaptação mais ampla baseada em partidas reais |
| 5. Personagens 3D | Preservados modelos/skin/65 ossos e fallbacks; regressões verificadas | Não foram criados modelos finais novos ou expressões faciais |
| 6. Jutsus | Colisão compartilhada mais robusta para ataques de mão e de área; feedback de recarga | Amaterasu dedicado e finalizações/coreografias específicas |
| 7. Susanoo | Entrada gradual, arco de espada MED/HIGH, funcionamento do Henrique CPU | Rig próprio, asas articuladas e ataques gigantes completos |
| 8. Gráficos | Preview com resolução/MSAA 2× por qualidade, corte limitado por qualidade, apresentação validada em OpenGL | Passe completo de materiais/reflexos/pós-processamento |
| 9. Câmera | Sensibilidade salva, tremor opcional, stick direito, descarte de arrastes acumulados no lock | Mais enquadramentos cinematográficos autorais |
| 10. Efeitos visuais | Arco de corte construído uma vez, feedback de toque/defesa perfeita | Destruição e efeitos elementais específicos mais elaborados |
| 11. Cenários | Exploração existente usa controle físico e preferências de câmera/touch | Novo conteúdo de Konoha, props destrutíveis e interação de terreno |
| 12. Interface | Modos/dificuldade/ajustes/pausa, barras de guarda, recarga touch, combo sem sobrepor vida | Ícones próprios e edição individual da posição de cada botão |
| 13. Android | Touch redimensionado com limites de viewport; preferências; gamepad e pausa de foco/back | Testes de deadzone/latência em aparelhos e diferentes gamepads |
| 14. Áudio | Pool de oito vozes SFX 3D, passos/impactos na posição da ação | Trilha e vozes originais/licenciadas; mixagem em aparelho |
| 15. História | Campanha e diálogos existentes preservados e testados | Não foram adicionados novos capítulos, escolhas ou cutscenes |
| 16. Modos | Treinamento e Sobrevivência integrados ao Versus | Torneio, desafios específicos e multiplayer |
| 17. Progressão | Recorde de sobrevivência persistido; treino isolado das recompensas | Novas conquistas/trajes/desbloqueios |
| 18. Qualidade técnica | Contratos de regressão, input físico, colisões, interrupções, pausa, save e export | Medição de FPS/memória/temperatura no Android real |
| 19. Apresentação | Seleção de modo, banner de duelo, feedback de defesa e menus | Poses de vitória e introduções exclusivas |
| 20. Publicação | Novo contrato na CI e teste do payload de desenvolvimento Android | APK assinado, itch.io/trailer/capturas finais dependem da preparação de release |

O modelo do Susanoo permanece estático, animado pela casca/espada do jogo. Nenhum modelo ou áudio comercial foi baixado. Os gates de proveniência existentes continuam aplicados; este passe não declara a versão pronta para distribuição pública.

## Reprodução

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/gameplay_improvements_contract.gd
python -m unittest discover -s tests -p 'test_*.py'
python tools/validate_release_assets.py
```

O novo contrato verifica entradas reais de gamepad, hitbox física entre poses, parede, janela abaixo de um frame, repetição de acertos, perfect guard, agarrão, dano durante dash, buffer de salto, layouts landscape, release de toque, pause/resume, CPU Henrique com Susanoo e sequência vitória/derrota/retry de sobrevivência. Arquivos de teste de save/config usam caminhos próprios.

Para renderizar com captura de seleção/ajustes (precisa de display OpenGL):

```sh
godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://tests/gameplay_improvements_contract.gd \
  -- --capture --capture-dir=/tmp/shinobi-captures
```

Headless não comprova estética. OpenGL via Mesa/llvmpipe permite compilar shaders e revisar layouts, mas também não é um benchmark do celular.
