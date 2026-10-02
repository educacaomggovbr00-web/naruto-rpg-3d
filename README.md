# Shinobi RPG 3D

Protótipo de RPG de ação 3D inspirado no ritmo, mobilidade e câmera de arena fighters de anime.

> Projeto independente/fan prototype. Não inclui assets, áudio ou código proprietários de Naruto/Storm.

## Engine
Godot 4.x

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
- HUD de chakra, lock e combo

## Controles
- **WASD:** mover
- **Mouse:** câmera livre
- **Tab:** ativar/desativar lock-on
- **Clique esquerdo:** ataque / combo
- **Q:** chakra dash
- **Shift:** correr
- **Espaço:** pular
- **Esc:** liberar o mouse

## Teste rápido
1. Abra a pasta na Godot 4.x.
2. Rode `main.tscn`.
3. Aperte **Tab** para travar no dummy vermelho.
4. Use **Q** para avançar com chakra.
5. Chegue perto e encadeie quatro cliques para testar o combo e o finalizador.

## Próximas camadas
A base foi separada para receber personagem animado, state machine de combate, hitboxes por animação, substituição, carregamento de chakra, jutsus, VFX e inimigos com IA sem reescrever a movimentação/câmera.
