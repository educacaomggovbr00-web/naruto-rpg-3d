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
- combo terrestre de 4 golpes
- hitbox/hurtbox 3D separadas por camada de colisão
- janelas de impacto sincronizadas com o estado do golpe
- 4º golpe terrestre lança o inimigo
- chakra dash persegue alvo lançado no ar
- combo aéreo
- pequena suspensão aérea durante ataques para facilitar continuidade
- 4º golpe aéreo derruba o oponente
- chakra dash
- carregamento manual de chakra
- defesa segurando botão
- esquiva com invulnerabilidade curta
- substituição com 4 cargas e cooldown
- primeiro jutsu com custo de chakra, dano e knockback
- vida do jogador, stagger, derrota e respawn
- inimigo com IA de perseguição, ataque, defesa e reação/esquiva
- ataques da IA também usam janela de hitbox
- K.O. e respawn do inimigo
- HUD de vida, chakra, substituições, cooldowns, estado de animação e FPS
- controles multi-touch

## Máquina de estados de animação
O controlador expõe estados explícitos:

- `idle`
- `run`
- `air`
- `attack`
- `air_attack`
- `guard`
- `dodge`
- `chakra_dash`
- `chakra_charge`
- `jutsu`
- `hit`
- `defeat`

O personagem provisório ainda usa animação procedural leve. Essa máquina de estados foi criada para depois mapear diretamente para `AnimationTree` + `Skeleton3D` quando entrar um modelo rigado, sem reescrever a lógica de combate.

## Controles mobile
- **Joystick esquerdo:** mover; perto da borda corre
- **Arrastar lado direito:** girar câmera sem lock
- **ATK:** combo terrestre/aéreo
- **JUTSU:** usar jutsu
- **DASH:** chakra dash e perseguição aérea
- **PULO:** pular
- **ESQ:** esquiva
- **SUB:** substituição
- **CHK (segurar):** carregar chakra
- **DEF (segurar):** defender
- **LOCK:** ativar/desativar lock-on

## Como testar o combo aéreo
1. Trave no inimigo com **LOCK**.
2. Use **ATK** até o 4º golpe.
3. O 4º golpe terrestre lança o inimigo.
4. Aperte **DASH** enquanto ele está no ar para persegui-lo.
5. Use **ATK** no ar para continuar o combo.
6. O 4º golpe aéreo aplica o slam para baixo.

## Controles de teste no PC
- WASD: mover
- Mouse: câmera
- Tab: lock-on
- Clique esquerdo: ataque
- Q: chakra dash/perseguição
- E: jutsu
- F: substituição
- Alt: esquiva
- C segurado: carregar chakra
- R segurado: defender
- Shift: correr
- Espaço: pular

## Arquitetura de hitbox/hurtbox
O jogador e o inimigo usam `Area3D` separadas para ataque e dano. A hitbox só processa acertos durante uma janela curta aberta pelo golpe. Cada alvo só pode ser acertado uma vez por janela. Isso prepara o projeto para no futuro anexar hitboxes a mãos, pés, armas e ossos específicos.

## Mobile
O protótipo continua usando primitivas low-poly e efeitos baratos para validar o combate em aparelhos móveis antes de adicionar modelos e VFX pesados.

## Próximas melhorias
- personagem rigado original/licenciado com Skeleton3D
- AnimationTree usando os estados já existentes
- hitboxes presas a ossos de mãos/pés
- hit pause curto e efeitos de impacto
- parede/ground bounce
- jutsus com projétil/área e VFX próprios
- efeitos de substituição mais claros
- seleção de personagem
- arena maior com paredes/obstáculos
- presets de qualidade para celulares fracos/intermediários/fortes
