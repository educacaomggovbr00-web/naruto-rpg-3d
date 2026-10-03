# Storm 1 — pipeline de pesquisa e importação técnica

Atualizado em 2026-10-03.

Objetivo: usar ferramentas públicas da comunidade para entender e transformar dados de **Naruto: Ultimate Ninja Storm 1** em informação útil para o projeto Godot, sem colocar arquivos brutos do jogo neste repositório.

## Fontes técnicas verificadas

### NUNSMOD

Fonte: https://github.com/roqols/NUNSMOD

O repositório declara Apache-2.0 na raiz. Ele contém:

- `CC2_CPK_Decrypter.bms`;
- `nunsmod_tool.py`;
- parser/repacker XFBIN;
- ferramenta específica para `CommandChartData.xfbin`.

O `nunsmod_tool.py` é voltado a payloads `nuccChunkBinary` do tipo `mode_select`/mensagens e trabalha com campos big-endian e texto UTF-8. Isso é útil para compreender binários internos, mas **não deve ser tratado como moveset/frame data**.

O `command_chart_tool.py` é mais relevante para personagens. O próprio código documenta que:

- `CommandChartData.xfbin` contém múltiplos `nuccChunkBinary`;
- cada personagem possui um chunk próprio;
- exemplos confirmados no código: `cmd1nrt` = Naruto e `cmd1ssk` = Sasuke;
- os payloads misturam números `uint32` big-endian e strings UTF-8;
- o primeiro `uint32` representa o tamanho restante do payload;
- a ferramenta consegue listar, segmentar e exportar os campos para JSON.

Os números ao redor dos textos **não são automaticamente dano/startup/radius**. O significado precisa ser identificado antes de virar valor de gameplay.

A cópia de `xfbin_lib` usada por essa ferramenta é descrita pelo próprio projeto como MIT.

### NUNS Meshswap Tool

Fonte: https://github.com/Lyingcake77/NUNS_Meshswap_tool

É uma ferramenta antiga em Python 2/Tkinter voltada a troca de mesh, descrita pelo autor como ferramenta para Naruto Ultimate Ninja Storm. O código da versão 1.9 procura blocos `NDP3` e nomes de partes dentro do binário.

Uso neste projeto: **referência de formato/nomenclatura**, não pipeline direto de Godot.

### Storm 1 PlayStation Icons

Fonte: https://github.com/AkikoKumagara/Naruto-STORM-1-PS-Icons

O mod confirma uma estrutura prática da versão PC com conteúdo sob:

`data_win32/interface/`

Subpastas visíveis no repositório:

- `adv`
- `battle`
- `battle_mode`
- `cmn`
- `title_option`

Isso é útil para mapear a organização do HUD/interface. As texturas modificadas desse mod **não são importadas automaticamente** para este projeto.

## O que foi adicionado ao nosso repositório

### 1. Inventário de arquivos fornecidos pelo usuário

`tools/storm1_file_probe.py`

Uso:

```sh
python tools/storm1_file_probe.py /caminho/para/storm1_extraido
```

Saída padrão:

`build/research/storm1_file_inventory.json`

O scanner registra apenas:

- caminho relativo;
- tamanho;
- SHA-256;
- extensão;
- assinaturas conhecidas;
- função de pesquisa sugerida.

Ele reconhece pistas como:

- `.xfbin`
- `.binary`
- `.cpk`
- `.nud`
- `.nut`
- `.anm`
- `NDP3`
- `NTP3`
- `CPK `

Ele **não extrai nem copia o conteúdo**.

### 2. Bridge para CommandChartData

`tools/storm1_command_chart_bridge.py`

Fluxo recomendado:

1. Com uma cópia local de NUNSMOD, usar o `command_chart_tool.py` em um `CommandChartData.xfbin` fornecido pelo usuário.
2. Gerar JSON pelo comando `extract`.
3. Passar o JSON para nosso bridge:

```sh
python tools/storm1_command_chart_bridge.py command_chart.json build/research/storm1_command_chart.normalized.json
```

O resultado:

- separa personagens conhecidos;
- preserva chunks desconhecidos;
- mantém índices originais;
- conserva textos;
- adiciona contexto dos números próximos;
- não inventa significado para os números.

Mapeamento inicial confirmado pela fonte:

```text
cmd1nrt -> naruto
cmd1ssk -> sasuke
```

Para adicionar códigos descobertos posteriormente:

```json
{
  "cmd1kks": "kakashi",
  "cmd1gar": "gaara"
}
```

E usar:

```sh
python tools/storm1_command_chart_bridge.py command_chart.json output.json --character-map character_map.json
```

Só adicionar um código ao mapa quando ele tiver sido verificado na fonte/arquivo analisado.

## Como isso entra no Godot

O bridge ainda **não converte automaticamente números desconhecidos** em `AttackDefinition`.

A ordem correta é:

```text
arquivo fornecido pelo usuário
        ↓
ferramenta de pesquisa local
        ↓
JSON extraído
        ↓
storm1_command_chart_bridge.py
        ↓
dados normalizados
        ↓
identificação do significado dos campos
        ↓
AttackDefinition / JutsuDefinition / ProjectileDefinition
        ↓
teste físico no Godot
```

Quando um campo for identificado de forma verificável, registrar em `docs/STORM_MOVES_DATA.md` com uma das classificações:

- `CONFIRMED`
- `COMMUNITY_RESEARCH`
- `VIDEO_ESTIMATE`
- `OUR_APPROXIMATION`

## Prioridade de análise quando houver arquivos

1. `CommandChartData.xfbin` — nomes/estrutura de comandos por personagem.
2. XFBINs relacionados a batalha/personagem/jutsu.
3. animação e câmera;
4. modelos/texturas somente quando necessários à compreensão técnica;
5. interface para reconstrução do HUD.

A primeira meta prática é **Naruto**: extrair nomes/ordem/contexto de comandos, identificar campos úteis e alimentar os Resources já existentes sem quebrar o combate atual.

## Regras de repositório

Arquivos brutos fornecidos pelo usuário devem ficar fora do Git, em:

`external/storm1_raw/`

Essa pasta é ignorada.

Resultados reproduzíveis podem ir para `build/research/`, que também já é ignorada pelo projeto.

Somente dados normalizados necessários para implementação e sem payload comercial devem ser promovidos para `assets/` ou `docs/`.
