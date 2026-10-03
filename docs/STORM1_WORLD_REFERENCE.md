# Mundo Shinobi — referência Storm 1

Pesquisa em 2026-10-03. Direção: Konoha explorável fisicamente com a maior fidelidade prática possível, não uma vila genérica ou menu de missões. Construção reservada à fase do mundo, após estabilizar Naruto/CPU no Android.

## Confirmado publicamente

A [descrição oficial mobile](https://play.google.com/store/apps/details?id=com.bandainamcoent.ultimateninjastorm) confirma exploração livre de Hidden Leaf Village, missões e minigames no Ultimate Mission Mode. A versão mobile acrescenta autosave, retry, modos casual/manual, assistências e controles de exploração adaptados. Isto sustenta botões touch diretos, sem alterar o alvo principal Storm 1.

A [Narutopedia](https://naruto.fandom.com/wiki/Naruto%3A_Ultimate_Ninja_Storm) descreve a campanha da Parte I até a recuperação de Sasuke: missões Flashback ordenadas e Free Missions D–S, condições bônus e recompensas.

O [guia Ashurii de 2008](https://gamefaqs.gamespot.com/ps3/943434-naruto-ultimate-ninja-storm/faqs/54852) documenta exploração, missões de Konohamaru, desafios de árvores/corrida e lojas. A academia/Iruka usa scrolls para habilidades; a loja de insetos converte coletas em ryo. [Guia des326](https://gamefaqs.gamespot.com/ps3/943434-naruto-ultimate-ninja-storm/faqs/54663) descreve mapa, scrolls secretos após missões e lojas.

## Levantamento ainda necessário

Não há levantamento métrico do mapa nesta sessão. Não inventar ruas, bairros ou afirmar reprodução do layout. Antes da fase de construção, comparar capturas públicas de exploração e mapa: rotas entre academia, Ichiraku, lojas e torre; ruas/becos/pontes, telhados acessíveis, altura dos saltos, paredes/limites, landmarks, NPCs, coletáveis, objetos quebráveis, condições de desbloqueio, entrada/saída de batalha. Registrar timestamps e medidas relativas, com confiança por região. Vídeos localizados não equivalem a quadros assistidos/medidos.

## Arquitetura prevista, não implementada

Exploração com corrida/salto/verticalidade/interação → evento orientado a Resource → transição → combate existente → resultado/recompensa/progresso → retorno à posição segura no mundo. Missões de história, conversa, coleta, entrega, treino e desafio usam dados configuráveis. Saves versionados em user://, com migração e escrita atômica.

Android: setores/chunks, visibility ranges/LOD/instancing, colisões simplificadas, iluminação baked, NPCs e VFX em pools, perfis LOW/MEDIUM/HIGH. Streaming não deve causar hitch perceptível nas rotas de telhado.

## Assets pesquisados

[Kenney Modular Buildings](https://kenney.nl/assets/modular-buildings), CC0, e [KayKit Medieval Hexagon Pack](https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0), CC0 com licença no repositório. Podem fornecer bases técnicas/prototipagem; nenhum reproduz a arquitetura exata de Konoha. Não foram importados nem apresentados como mundo final. Fachadas, telhados e landmarks específicos exigem autoria ou assets compatíveis com licença clara. Nenhum rip/dump de Storm foi adquirido.
