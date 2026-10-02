# Shinobi RPG 3D

Protótipo mobile de RPG de ação 3D inspirado no ritmo, mobilidade e câmera de arena fighters de anime.

> Projeto independente/fan prototype. Não inclui assets, áudio ou código proprietários de Naruto/Storm.

## Engine e alvo
- Godot 4.x
- mobile-first
- orientação horizontal (landscape)
- alvo de 60 FPS
- renderer `gl_compatibility` para ampliar compatibilidade em aparelhos móveis

## Estado atual — combate vertical slice
- movimentação 3D responsiva
- câmera orbital em terceira pessoa
- corrida e pulo
- lock-on com movimento de strafe
- câmera automática de combate
- dummy com vida, hit reaction, knockback, K.O. e respawn
- chakra com regeneração
- chakra dash direcionado ao alvo
- combo básico de 4 golpes com finalizador
- HUD de chakra, lock, combo e FPS
- controles mobile multi-touch
- humanoide shinobi low-poly provisório
- animação procedural de idle, corrida e quatro poses de ataque
- aura de chakra leve durante o dash
- camera shake curto nos impactos

## Controles mobile
- **Joystick esquerdo:** mover
- **Joystick perto da borda:** correr automaticamente
- **Arrastar no lado direito:** girar câmera quando estiver sem lock-on
- **ATK:** ataque / combo
- **DASH:** chakra dash
- **PULO:** pular
- **LOCK:** ativar/desativar lock-on

Os controles aceitam múltiplos dedos ao mesmo tempo, então é possível mover e atacar/dar dash simultaneamente.

## Controles de teste no PC
- WASD: mover
- Mouse: câmera
- Tab: lock-on
- Clique esquerdo: ataque
- Q: chakra dash
- Shift: correr
- Espaço: pular

## Teste rápido
1. Abra a pasta na Godot 4.x.
2. Rode `main.tscn`.
3. No celular, toque em **LOCK** para travar no dummy vermelho.
4. Use **DASH** para avançar consumindo chakra e ver a aura.
5. Use **ATK** quatro vezes para completar o combo e sentir o impacto de câmera.
6. Observe o contador de FPS no canto superior direito.

## Direção técnica mobile
A UI usa posições relativas ao viewport e multi-touch por índice de dedo. A câmera aceita swipe no lado direito e o movimento continua baseado na direção da câmera. O projeto limita o FPS a 60, mantém o renderer de compatibilidade e usa um humanoide feito de primitivas low-poly para validar gameplay sem carregar assets pesados.

## Próximas camadas
- substituir o boneco provisório por personagem 3D original/licenciado com Skeleton3D
- state machine de animação/combate
- hitboxes sincronizadas com animações
- VFX leves de impacto
- substituição
- carregamento de chakra
- jutsus
- IA de combate
- presets de qualidade para celulares fracos/intermediários/fortes
