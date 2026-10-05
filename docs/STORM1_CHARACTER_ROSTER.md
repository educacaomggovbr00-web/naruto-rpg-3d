# Elenco — Storm 1

Pesquisa em 2026-10-03. A [página oficial mobile da Bandai Namco](https://play.google.com/store/apps/details?id=com.bandainamcoent.ultimateninjastorm) confirma 25 lutadores e 10 suportes. Identidades cruzadas com a [lista Storm 1 da wiki](https://naruto-ultimate-ninja-storm.fandom.com/wiki/Naruto:_Ultimate_Ninja_Storm) e os ícones de elenco na [página de Naruto Part 1](https://naruto-ultimate-ninja-storm.fandom.com/wiki/Naruto_Uzumaki_(Part_1)). A lista textual da primeira wiki omite Kisame; o índice visual inclui-o.

## Jogáveis

Naruto Uzumaki; Sasuke Uchiha; Sakura Haruno; Shikamaru Nara; Choji Akimichi; Ino Yamanaka; Rock Lee; Neji Hyuga; Tenten; Shino Aburame; Kiba Inuzuka; Hinata Hyuga; Gaara; Kankuro; Temari; Kakashi Hatake; Might Guy; Jiraiya; Tsunade; Hiruzen Sarutobi; Orochimaru; Kabuto Yakushi; Kimimaro; Itachi Uchiha; Kisame Hoshigaki.

## Suporte

Asuma Sarutobi; Kurenai Yuhi; Anko Mitarashi; Shizune; Hashirama Senju; Tobirama Senju; Kidomaru; Sakon/Ukon (uma entrada); Jirobo; Tayuya. Não tratar estes dez como lutadores completos da edição original. [Anúncio de DLC de suporte](https://www.gematsu.com/2008/10/naruto-ultimate-ninja-storm-dlc-to-be-free-detailed).

## Estado no projeto

Os **25 jogáveis acima já estão presentes na seleção** como jogador e CPU. Naruto, Sasuke, Sakura e Kakashi mantêm os perfis próprios já existentes. Os outros 21 usam temporariamente `assets/characters/rigged.glb`, mas não compartilham mais o moveset do Naruto: cada slot recebe um perfil independente de combo terrestre/aéreo, velocidade, vida, knockback e launcher gerado por `RosterMovesetFactory`. Esses valores são `OUR_APPROXIMATION`; jutsus, Ultimate, Awakening, modelos e coreografias finais ainda precisam ser implementados.

Os 10 nomes de suporte permanecem separados em `CharacterCatalog.SUPPORT_ONLY` e não viraram lutadores completos.

## Dados por personagem e sequência de implementação

| Personagem | Evidência registrada | Lacunas antes de implementação final |
|---|---|---|
| Naruto | Rasengan, Demon Wind Bomb, clones, Barrage; Ultimate Naruto’s Ninja Handbook; Awakening de uma cauda, Vermillion Rasengan, Ultimate despertado Sealed Power | Frames/coreografia exata, clips autorais, modelo próprio, áudio autorizado, medidas de velocidade/alcance |
| Sasuke (criança) | Próximo após framework de Naruto consolidado | Pesquisar seção específica Storm 1: todos combos, Chidori/alternativas, Ultimate e formas; não usar moveset Shippuden |
| Sakura (criança) | Próxima após Sasuke | Confirmar combos, força/alcance, jutsu, Ultimate, modo despertado e suporte na edição 1 |
| Kakashi | Próximo após Sakura | Confirmar combos, jutsus selecionáveis, Ultimate, Sharingan/modo, efeitos e suporte na edição 1 |
| Outros 21 | Slots jogáveis já ativos; cada um possui agora ataques-base independentes marcados como OUR_APPROXIMATION | Refinar cada ficha com pesquisa, modelo, jutsus, Ultimate/Awakening, VFX e coreografia próprios; não tratar o perfil-base como reprodução final de Storm 1 |

Ficha obrigatória por personagem: modelo/skeleton/biblioteca/tree; combo neutro/direcional/launcher/aéreo; jutsus; Ultimate; Awakening; velocidade/alcance/estilo; particularidades; suporte; animações/VFX/áudio necessários; CPU profile; fonte e confiança. O framework configura todos os 25 IDs sem duplicar o controlador. A presença no roster não significa conclusão individual: 21 ainda são slots de desenvolvimento até receberem implementação própria.
