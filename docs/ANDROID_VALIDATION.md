# Validação no Android — fase Storm 1

Engine alvo: Godot 4.7.2, gl_compatibility, landscape, 60 FPS como meta (não medido nesta máquina). Atualizar main e reimportar; preset Android inclui JSON. Pacote PCK Android exportado e executado headless separadamente, com manifesto/rig e sem fontes/testes. O APK não foi produzido nesta sessão: SDK/templates/assinatura/aparelho não foram disponibilizados.

## Testes automáticos

Importação sem parser errors; contrato de 27 clips (130 canais, quaternions e poses) e contrato da fase Storm (movimento, confirms, dash, guarda, projétil, Rasengan, clones e Barrage). CI executa ambos na versão fixada. Hit-stop é desabilitado somente na suíte da fase para assertions de tempo determinísticas; permanece habilitado no jogo e no contrato anterior.

## Roteiro no aparelho

| Ação | O que observar |
|---|---|
| LOCK, joystick lateral/baixo, correr e pular | Orbitar sem virar as costas; intensidade do stick controla velocidade; comparar deslizamento dos pés (clips direcionais ainda adaptados) |
| Afastar lutadores, circular perto das quatro paredes | Dois corpos visíveis; distância/FOV graduais; câmera não entra nas paredes nem oscila sem impacto |
| ATK 1–4, alto/baixo/lateral antes do primeiro | Neutro preserva launcher; baixo derruba, lateral afasta; sem dano quando o braço passa longe |
| ATK durante recovery; DASH após acerto e após erro | Entrada pode ficar em buffer; whiff não cancela; contato com guarda dá recoil; dash fecha ao tocar e ATK continua |
| Launcher → DASH → aéreo → slam | Tracking acompanha altura; duas perseguições máximas no mesmo voo; CPU recupera de cadeias longas |
| DEF contra vários golpes e soltar | Meter desce, bloqueio tem feedback azul, esgotamento causa stun; meter recupera após pausa |
| SUB durante combo, perto da parede | Fumaça e breve desaparecimento; surge atrás do alvo sem sair da arena; cargas voltam de uma em uma |
| Selecionar DWB e JUTSU a média distância | Clone lançador, fūma giratório, personagem representado pelo projétil, colisão e golpes com clones após confirm; erro/parede não causa dano |
| Selecionar RAS e JUTSU | Esfera e anéis acompanham mão direita; corrida aproxima sem atravessar cenário; fora da trajetória não acerta; ataque interrompido dissipa |
| CLONE no chão e no ar | Duas cópias rigadas, golpes escalonados, fumaça ao sair; observar se punhos encostam no alvo e se poses/interseções precisam de ajuste |
| BARR perto do alvo, longe e contra defesa | Só acerto limpo inicia sequência; clone lança, intermediário e slam; erro/bloqueio não abre câmera; SUB/KO restaura controles |
| Repetir especiais por dois minutos | Sem crescimento de clones/efeitos, sem objetos esquecidos, sem erro de log; observar aquecimento e FPS |

Registrar modelo do aparelho, FPS mínimo durante 3 clones/Rasengan/trails, atraso de toque e vídeo curto de qualquer golpe que pareça sem contato. Poses foram inspecionadas via render CPU, não captura OpenGL do Android.

## Limitações deliberadas desta fase

Rig/modelo existente preservado. Golpes da mão substituem provisoriamente chutes específicos; Rasengan usa cross adaptado; guarda/shield e spell gestures ainda precisam de acabamento. CPU original continua sendo cápsula nesta fase, com defesa/sub melhoradas; CPU Fighter rigada está na etapa posterior solicitada. Não há inventário ninja tools, Ultimate, Awakening, áudio ou suporte de outros personagens nesta revisão.
