# Personagem rigado

O arquivo original `rigged.glb` permanece intacto, com sua animação `happy`. O adapter adiciona a biblioteca externa `../animations/combat_mixamo.tres` ao AnimationPlayer, sob o namespace `combat/`. Todos os estados jogáveis usam os clips reais dessa biblioteca.

O Godot 4.7.2 importa os nomes Mixamo substituindo `:` por `_`. O adapter resolve ambos os formatos, descobre o caminho real do Skeleton3D e remapeia os canais da biblioteca; não depende da animação `happy` para descobrir os ossos.

A biblioteca foi bakeada para este GLB específico, usando as matrizes de bind da skin corporal. Sua pose de nó importada é diferente da pose de bind; multiplicar rotações simples pela pose importada não faz retarget adequado.

Após substituir o GLB, rode `python tools/bake_combat_animations.py` e os testes descritos no README. O manifest registra SHA-256 do personagem e das fontes usadas.

A escala automática para aproximadamente 1,75 m e o yaw de 180° foram preservados. Mãos seguem o movimento real: jab esquerdo, cross direito, hook/launcher direito e slam direito. O dummy inimigo continua com sua representação original.

Sem GLB ou com uma biblioteca incompatível, o adapter mostra o erro e mantém o visual de primitivas como recurso de emergência. Esse visual não é a solução de animação do personagem rigado.

A origem/licença do modelo fornecido anteriormente não foi alterada nem reclassificada por esta mudança. A declaração CC0 cobre as novas animações do Quaternius.
