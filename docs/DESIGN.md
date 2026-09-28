# Design — Piscatio

Notas de direção visual (processo da skill *frontend-design*: plano → revisão contra
clichês → construção → crítica). Atualizar a cada iteração com o que foi tentado.

## Assunto, público e função

- **Assunto:** diário de pescaria esportiva e de lazer (rio, represa, mar).
- **Público:** pescadores do Brasil, da América Latina e da América do Norte, de 25 a 55
  anos, orgulhosos das capturas. Usam o app no barranco ou no barco: mão molhada,
  sol forte, pressa.
- **Função do app:** registrar em segundos, sem pensar.
- **Função do card:** fazer quem rola o feed parar, sentir o peixe e querer ir pescar.

## Vocabulário do universo da pesca (fonte das escolhas)

- **Pinturas de isca artificial** com nomes que todo pescador reconhece: *red head*
  (cabeça vermelha e corpo branco), *firetiger*, *prata*, *chartreuse*.
- **Boia** vermelha e branca.
- **Régua de medição:** a tábua com escala em que o peixe é medido antes da soltura.
- **Carta náutica** com isóbatas (linhas de profundidade).
- **Etiqueta de coleção ictiológica:** nome científico em itálico, localidade, data com
  mês em algarismos romanos, coletor.
- **Letreiros de casco de barco e motor de popa:** letras largas, itálicas e pesadas.

## Plano (1ª passada)

**Cores**

| Nome | Hex | Papel |
|---|---|---|
| Red head | `#E4262C` | ação principal; a cor da isca cabeça-vermelha |
| Deep water | `#0B2A33` | tinta no tema claro, fundo no escuro |
| Paper | `#FFFFFF` | fundo claro (branco de verdade: máximo contraste sob sol) |
| Mist | `#EDF2F1` | superfície secundária, fria (nada de creme) |
| Dorado | `#F4B400` | recordes e conquistas; o dourado do peixe |
| Reed | `#4A6670` | texto secundário (contraste 6,1:1 no branco) |

Tema escuro: fundo `#0B2A33` (água funda, não preto), superfícies `#12363F`/`#184450`,
ação `#F23A30`, vermelho como texto `#FF6A5E` (5,4:1).

**Tipografia:** uma família, Archivo, em três larguras:

- *Archivo Expanded* ExtraBold/Black **itálico**: números grandes (cronômetro,
  medidas, totais). É a linguagem dos adesivos de casco e motor de popa. Algarismos
  tabulares no cronômetro.
- *Archivo* Regular/SemiBold/Bold: interface.
- *Archivo Condensed* Bold: dados densos nos cards (listas de espécies, legenda).
- Itálico regular para nome científico (convenção da biologia, não enfeite).

**Layout do app:** alinhado à esquerda. Números grandes no topo, ação principal numa
"laje" vermelha larga na parte de baixo, na zona do polegar. Superfícies chapadas,
sem sombra. Hierarquia por tamanho e peso, não por caixas.

**Princípio:** a ousadia fica num lugar só, os números em itálico expandido e o motivo
da régua. O resto é quieto.

## Revisão contra clichês (o que mudei e por quê)

1. *Branco + vermelho + azul-marinho* é paleta esportiva comum. **Mudança:** o vermelho
   deixou de ser "cor de marca" genérica e passou a ser a isca *red head*, e os estilos
   de card ganham nomes de pinturas de isca. Isso amarra a paleta ao assunto.
2. *Cartões arredondados iguais com sombra* para cada pescaria. **Mudança:** listas com
   miniatura de foto e número grande, separadas por espaço. Raios por hierarquia:
   laje de ação 24, folhas 28, miniaturas 10, campos 14.
3. *Rótulo em caixa alta sobre cada seção* e *metadados unidos por "·"*. **Mudança:**
   títulos em frase normal; metadados em linhas próprias com pesos diferentes.
4. *Número grande + rótulo pequeno + gradiente* como destaque padrão. **Mudança:** o
   número grande fica, é o assunto (peso, tempo, medida), mas sem gradiente. O
   destaque visual vem da **régua**: uma escala com marcas que codifica informação
   real. Na pescaria ativa, cada captura vira um entalhe vermelho na régua do tempo.
   Nos cards, a régua mede o peixe.
5. *Preto azulado no lugar do preto* no escuro. **Mudança:** o fundo é
   explicitamente água funda (`#0B2A33`), uma cor, não um quase-preto.

## Cards (Fase 1B) — plano

Canvas fixo: 1080×1920 (story 9:16) e 1080×1080 (quadrado 1:1), medidas em px do
canvas. O texto não escala com a fonte do sistema. Cada estilo tem **uma** ousadia;
o resto fica quieto. Recorde é mostrado com a linguagem do próprio estilo, não com
um selo genérico.

### Régua (a tábua de medição)

- Foto sangrando a tela; sem foto, água funda.
- Na base, uma **tábua de medição** branca com o batente escuro no zero (onde o
  focinho encosta), marcas de 1 cm (ou ½ pol), números a cada 10 cm e um entalhe
  vermelho no comprimento do peixe.
- **Recorde:** o recorde anterior aparece como uma marca dourada na mesma escala,
  com "recorde anterior" ao lado; a distância entre as marcas *é* a melhoria.
- Sem comprimento, a tábua mede o peso; sem medida nenhuma, a hora do dia.
- A marca Piscatio vai **impressa na tábua**, como a marca do fabricante.
- Pescaria: a tábua vira a régua do tempo da pescaria (um entalhe por captura),
  como na tela da pescaria ativa.

### Carta (carta náutica, modo noturno)

- Fundo água funda com **isóbatas** geradas a partir do id (curvas de nível de um
  campo de ruído, por marching squares). Nunca a partir das coordenadas.
- Borda graduada de carta (barras alternadas, como a escala de minutos).
- Os números são **sondagens**: na carta, profundidade se escreve em itálico. O
  número da pescaria (capturas) ou da captura (comprimento) é a sondagem gigante.
- **Rosa dos ventos** com dados reais: seta do vento (NASA POWER) e, no centro,
  o disco da lua na fase do dia.
- Quadro de título (cartucho): local conforme privacidade, data e uma tabela
  curta. Foto, se houver, num **encarte** de moldura dupla, como os planos
  ampliados das cartas.
- Recorde: linha dourada no cartucho com a % de melhoria.

### Etiqueta (etiqueta de coleção ictiológica)

- Uma **etiqueta de papel manilha** pendurada por um barbante, levemente
  inclinada, sobre a foto escurecida (ou água funda).
- Texto datilografado (Courier Prime, só neste estilo: é a metáfora, não um
  rótulo técnico): nº de tombo (a posição da captura no diário), nome científico
  em itálico, nome comum, local, data com mês romano (12.IX.2026), medidas, isca.
- Recorde: **carimbo vermelho** "Recorde pessoal +14%"; primeira da espécie:
  carimbo azul-escuro "Primeira captura".
- Pescaria: a etiqueta vira uma folha de registro de campo com as capturas.

### Revisão contra clichês

- Papel manilha lembra o "fundo creme": aceito porque é um objeto na cena (sobre
  foto/água), não o fundo da página, e sem serifa de display. Tom mais saturado
  (`#E4D29E`) para ler como papel, não como interface.
- Monoespaçada é um sinal de interface gerada quando usada em rótulos pequenos;
  aqui ela é o assunto (etiqueta datilografada) e grande. Só no estilo Etiqueta.
- Gradientes: só *scrims* funcionais sob texto em cima da foto.
- Nada de selos redondos genéricos, CAIXA ALTA decorativa ou "·" entre dados.

## Registro de iterações

- 1A: tokens, tipografia e régua do tempo na pescaria ativa. Revisado por capturas
  de tela (claro, escuro, fonte 1,6×). Ajustes feitos depois da revisão: botão de
  ação principal sempre no mesmo ponto em todo o fluxo de captura; no escuro, o bloco
  "pescaria em andamento" usa `#184450` para não sumir no fundo; com fonte grande,
  as medidas da captura descem para baixo do nome; cronômetros com `FittedBox`.
- 1B (cards): renderizados em 1080×1920 e 1080×1080 e revisados por capturas de
  tela com e sem foto. Ajustes feitos depois da revisão: na Carta, as legendas da
  lua e do vento saíram de dentro da rosa (brigavam com a seta) e as isóbatas
  ficaram mais suaves (menos oitavas, escala maior) com menos sondagens; o quadrado
  da Carta passou a ter o cartucho na largura toda (os valores eram cortados); na
  Régua da pescaria, entalhes menores e números por cima das linhas; a Etiqueta
  ficou menor para mostrar mais da foto e o carimbo não cobre mais os campos.
- 1B (resumo): fundo água funda, uma só ação ("Criar card"); a régua do tempo da
  pescaria ativa reaparece inteira, com um entalhe por captura; recordes com filete
  dourado.
