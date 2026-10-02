# Personagem rigado

O jogo procura o modelo principal neste caminho:

`res://assets/characters/rigged.glb`

O arquivo analisado nesta etapa possui um rig Mixamo com ossos `mixamorig:*` e a animação `happy`.

## Integração automática

Quando `rigged.glb` existe nesse caminho:

- o humanoide procedural antigo é ocultado;
- o GLB é instanciado como visual do Player;
- o `Skeleton3D` e o `AnimationPlayer` são encontrados automaticamente;
- um `AnimationTree` com os estados do combate é criado em runtime;
- nomes de animações futuras são associados aos estados por palavras-chave;
- a hitbox do Player passa a seguir mãos e pés reais do rig.

Se o arquivo não existir ou falhar ao importar, o jogo mantém o boneco procedural como fallback e continua executando.

## Animações esperadas futuramente

O adapter reconhece nomes contendo termos como:

- idle / happy / stand
- run / jog / sprint
- jump / fall / air
- attack / punch / kick / combo
- guard / block
- dodge / roll
- dash / rush
- charge / powerup
- jutsu / cast
- hit / hurt
- defeat / death / ko

Não é obrigatório usar exatamente esses nomes; eles são apenas palavras-chave para associação automática.


## Escala automática

Esse GLB mede aproximadamente **178,92 unidades de altura** no arquivo, então em Godot ele pode aparecer gigante se entrar com escala 1.0.

O `RiggedCharacterAdapter` agora mede o AABB dos meshes em runtime e ajusta automaticamente o modelo para **1,75 m**. Para esse arquivo, a escala esperada fica perto de **0,00978**.

O parâmetro `model_scale` funciona apenas como multiplicador fino depois da correção automática. Normalmente deve ficar em `1.0`.
