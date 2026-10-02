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
- contador de combo com HITS e dano acumulado
- hit-stop curto apenas quando o golpe conecta
- VFX leves para impacto normal, defesa, launcher, slam e bounce
- zoom de impacto e camera shake por intensidade do golpe
- ground bounce depois de slam
- wall bounce em golpes fortes contra as paredes da arena
- efeito visual leve de chakra dash
- efeito de fumaça na substituição
- arena fechada com quatro paredes físicas
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

O projeto agora possui um adapter real para `Skeleton3D + AnimationTree`. Quando existe `res://assets/characters/rigged.glb`, o modelo é instanciado automaticamente, o humanoide procedural é ocultado e os estados do combate passam a controlar uma máquina de estados de animação. Se alguma animação ainda não existir no GLB, o adapter usa uma animação disponível como fallback sem quebrar o combate.

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

## Combat Polish
O feedback de combate agora é disparado pelo acerto real da hitbox. Golpes no vazio não aumentam o contador nem acionam hit-stop.

- golpes normais: impacto curto
- defesa: impacto mais leve
- launcher: impacto e zoom maiores
- slam: impacto forte e ground bounce
- golpes fortes próximos da borda: wall bounce
- bounces prolongam brevemente a janela visual do combo

Os VFX usam meshes simples criadas em runtime, sem texturas ou sistemas pesados de partículas.

## Mobile
O protótipo continua usando primitivas low-poly e efeitos baratos para validar o combate em aparelhos móveis antes de adicionar modelos e VFX pesados.

## Personagem rigado
O adapter procura `res://assets/characters/rigged.glb`.

O GLB analisado nesta etapa possui rig Mixamo, ossos de mãos/pés compatíveis com o sistema de hitbox e uma animação `happy` de aproximadamente 3 segundos. A hitbox do jogador passa a seguir os ossos `mixamorig:RightHand`, `mixamorig:LeftHand`, `mixamorig:RightFoot` e `mixamorig:LeftFoot` quando o rig está carregado.

O HUD mostra `RIG: OK` quando o asset foi importado corretamente. Sem o arquivo, o boneco procedural continua funcionando como fallback.

## Próximas melhorias
- pacote completo de animações para o rig: idle, run, jump, ataques, guard, dodge, hit e KO
- crossfade refinado entre animações reais
- jutsus com projétil/área e VFX próprios
- seleção de personagem
- arena temática maior com obstáculos
- áudio de golpes, dash, chakra e jutsu
- presets de qualidade para celulares fracos/intermediários/fortes
