# Apresentação anime — 2026-10-03

O pedido de continuar na `main` com gráficos próximos de Genshin Impact inicia
uma camada de iluminação anime autoral. A direção de gameplay Storm 1 continua;
esta mudança trata da apresentação, sem trocar rigs, clips ou regras de combate.

## Implementação

- Shader opaco de uma passagem com sombra em faixas, preenchimento azulado e
  luz suave na borda iluminada. Usa as luzes e sombras reais do Godot.
- Naruto mantém cada textura/cor do modelo fornecido. Overrides por superfície
  são compartilhados entre jogador, CPU, seleção e clones; o GLB não é alterado.
  Usa material toon nativo com rim, preservando os recursos das texturas importadas.
  O shader próprio é usado nas superfícies de cores.
  Materiais importados com transparência, normal map ou UV transformado mantêm
  o original para não perder recursos. Sasuke/Sakura/Kakashi usam vertex colors.
- Arena/aldeia usam o mesmo shader de cenário, céu azul ou de entardecer,
  telhados turquesa, folhagem verde e névoa leve. Piso da arena usa variação ampla
  e suaviza as linhas com derivadas para reduzir cintilação.
- LOW remove sombras/névoa; MED/HIGH preservam os orçamentos anteriores.
  Nenhuma passagem de outline, bloom, SSAO ou dependência de Forward+ foi adicionada.

Não foram importados modelos, texturas ou shaders de Genshin. Este é um primeiro
incremento de iluminação; não equivale à qualidade final daquele jogo. Modelos,
rosto, materiais específicos de cabelo/pele e paisagismo detalhado ainda precisam
de trabalho. FPS e consumo de GPU no Android não foram medidos.

## Validação

Godot 4.7.2: import, contratos existentes de animação/combate/personagens/mundo,
contrato de apresentação e pacote Android isolado. Treze testes Python e registry
de assets também foram executados. O contrato de seleção foi atualizado porque
Naruto pré-Shippuden e Sasuke possuem rest rigs diferentes: não devem compartilhar
a biblioteca preparada entre si; clones do mesmo Naruto continuam compartilhando.
O registry agora inclui os shaders/materiais novos e as imagens recriadas pelo
import do Naruto, além do hash do perfil que estava desatualizado na `main`.

Render OpenGL Compatibility com Mesa llvmpipe: capturas da seleção, treino,
pátio e aldeia. Isso verifica compilação do shader e imagem no desktop por software;
não comprova desempenho nem aparência em uma GPU Android.

```sh
godot --headless --path . --script res://tests/anime_presentation_contract.gd
godot --path . --rendering-method gl_compatibility --script res://tests/anime_presentation_contract.gd -- --capture
```

No aparelho, comparar LOW/MED/HIGH com Naruto/Sasuke, clones e jutsus; observar
rosto/texturas, sombras em movimento, contorno e piso em ângulos rasos. Explorar
a aldeia e retornar ao combate para conferir iluminação, legibilidade e FPS.
