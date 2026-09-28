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

## Cards (Fase 1B) — conceitos

Três estilos, todos em 9:16 (1080×1920) e 1:1 (1080×1080), para pescaria e captura:

1. **Régua:** foto sangrando a tela toda; na base, a tábua de medição com escala em
   cm ou polegadas e o entalhe vermelho no comprimento do peixe. Número gigante em
   itálico expandido. Sem comprimento, a régua vira a escala de peso.
2. **Carta:** fundo de água funda com isóbatas geradas a partir do id da pescaria
   (decorativas, **nunca** das coordenadas reais). Os números da pescaria aparecem
   como sondagens da carta. Espécies como legenda.
3. **Etiqueta:** etiqueta de coleção ictiológica. Nome científico em itálico, local
   (conforme privacidade), data com mês romano (12.IX.2026), medidas datilografadas.
   Funciona sem foto.

Regras dos cards: marca discreta no rodapé; selo "Novo recorde" em dourado com a %
de melhoria; nunca coordenadas; texto não escala com a fonte do sistema.

## Registro de iterações

- 1A: tokens, tipografia e régua do tempo na pescaria ativa.
