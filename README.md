# Shinobi RPG 3D

Protótipo mobile de RPG de ação 3D inspirado no ritmo, mobilidade e câmera de arena fighters de anime.

> Projeto independente/fan prototype. Não inclui assets, áudio ou código proprietários de Naruto/Storm.

## Engine e alvo
- Godot 4.7.x
- mobile-first
- orientação horizontal (landscape)
- alvo de 60 FPS
- renderer `gl_compatibility`

## Combate atual
- movimentação 3D e corrida
- pulo
- lock-on e strafe
- câmera automática de combate
- combo de 4 golpes
- chakra dash
- carregamento manual de chakra
- defesa segurando botão
- esquiva com invulnerabilidade curta
- substituição com 4 cargas e cooldown
- primeiro jutsu com custo de chakra, dano e knockback
- vida do jogador, stagger, derrota e respawn
- inimigo com IA de perseguição, ataque, defesa e reação/esquiva
- K.O. e respawn do inimigo
- HUD de vida, chakra, substituições, cooldowns e FPS
- controles multi-touch

## Controles mobile
- **Joystick esquerdo:** mover; perto da borda corre
- **Arrastar lado direito:** girar câmera sem lock
- **ATK:** combo
- **JUTSU:** usar jutsu
- **DASH:** chakra dash
- **PULO:** pular
- **ESQ:** esquiva
- **SUB:** substituição
- **CHK (segurar):** carregar chakra
- **DEF (segurar):** defender
- **LOCK:** ativar/desativar lock-on

## Controles de teste no PC
- WASD: mover
- Mouse: câmera
- Tab: lock-on
- Clique esquerdo: ataque
- Q: chakra dash
- E: jutsu
- F: substituição
- Alt: esquiva
- C segurado: carregar chakra
- R segurado: defender
- Shift: correr
- Espaço: pular

## Comportamento da IA
O inimigo detecta o jogador, persegue até alcance de ataque, alterna ataques com períodos de defesa, recebe stagger e knockback e executa uma esquiva reativa depois de alguns impactos.

## Mobile
O protótipo continua usando primitivas low-poly e efeitos baratos. O objetivo desta fase é validar sensação de combate sem comprometer celulares modestos.

## Próximas melhorias
- trocar o humanoide provisório por personagem original/licenciado com Skeleton3D
- animações reais por AnimationTree
- hitboxes sincronizadas por frame de animação
- jutsus com projétil/área e VFX próprios
- efeitos de substituição mais claros
- seleção de personagem
- arena maior e paredes/obstáculos
- presets de qualidade para celulares fracos/intermediários/fortes
