# Piscatio — convenções do projeto

Diário social de pescaria. Cada **pescaria** (Trip) contém **capturas** (Catches) e
vira um **card** compartilhável (9:16 e 1:1). Roadmap e status: `docs/ROADMAP.md`.

## Monorepo

```
/app        Flutter (Android + iOS)
/backend    Django + DRF + PostGIS — Fase 2 (conta, sync, fotos, clima ao vivo)
/docs       ROADMAP e decisões
```

## Idioma

- Documentos para humanos (`README.md`, `docs/`, este arquivo): pt-BR.
- Código, identificadores, comentários e mensagens de commit: inglês.
- Textos da interface: somente nos ARB (`app/lib/l10n/app_{en,pt,es}.arb`).

## Comandos (rodar dentro de `app/`)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift / freezed / json
flutter gen-l10n                                            # traduções
dart format .
flutter analyze
flutter test
dart run tool/check_l10n.dart          # chaves e placeholders iguais nos 3 idiomas
dart run tool/check_hardcoded_strings.dart   # nenhum texto literal na UI
tool/verify.sh                         # tudo acima, como na CI — rodar antes de commitar
```

Backend (dentro de `backend/`, detalhes em `backend/README.md`):

```bash
DJANGO_DEBUG=1 pytest                 # PostGIS local (usuário/senha/banco "piscatio")
ruff check . && ruff format --check .
python manage.py makemigrations --check --dry-run
```

O código gerado (`*.g.dart`, `*.freezed.dart`, `lib/l10n/generated/`) **é commitado**
para que `flutter run` funcione logo após clonar. A CI regenera e falha se houver diff:
depois de mudar tabelas, modelos ou ARB, rode os geradores e commite o resultado.

## Arquitetura (`app/lib`)

```
core/        tema, rotas, widgets base, relógio, ids, providers de infraestrutura
domain/      Dart puro: models/ (freezed) e services/ (unidades, lua, recordes,
             estatísticas, privacidade, busca de espécies). Sem Flutter, sem Drift.
data/        db/ (Drift: tabelas, DAOs, seed), repositories/, remote/, media/, jobs/
features/    uma pasta por funcionalidade: presentation/ (telas, widgets) e
             application/ (controllers e providers Riverpod)
l10n/        ARB + código gerado
```

Regras:
- **Offline-first**: o Drift é a fonte da verdade. A UI observa streams do banco
  (`StreamProvider`) e nunca espera rede. Rede = jobs enfileirados que gravam no banco.
- `domain/` não importa `package:flutter`, `drift` nem `data/`. Toda regra de negócio
  testável mora lá.
- Repositórios convertem linhas do Drift ↔ modelos de domínio. Telas nunca usam Drift.
- Leitura pontual = `get()`; **nunca** `watch().first`. O Drift compartilha streams
  idênticos e um stream já observado pela UI pode travar a leitura.
- Riverpod 3 **sem codegen** (`Provider`, `StreamProvider`, `Notifier`, `AsyncNotifier`).
  Dependências externas (relógio, UUID, GPS, câmera, HTTP, banco) são providers
  sobrescrevíveis em teste.
- Navegação só via `go_router` (`core/router/`), rotas nomeadas em `AppRoutes`.

## Dados

- IDs: **UUID v7** gerados no cliente (`core/ids`).
- Datas: sempre **UTC** no banco; `trips.timezone` guarda o IANA da pescaria para exibição.
- Toda tabela do usuário tem `created_at`, `updated_at`, `deleted_at` (exclusão lógica)
  e `sync_status`. Consultas normais filtram `deleted_at IS NULL`.
  "Apagar todos os dados" é a única exclusão física.
- Toda escrita atualiza `updated_at` (via `Clock`, nunca `DateTime.now()` direto).
- Unidades: armazenar **sempre em SI** — gramas, milímetros, °C, hPa, km/h — como
  inteiros quando possível. Converter apenas na exibição/entrada (`domain/services/units`).
- Fotos: arquivos em `<documentos do app>/photos/`, banco guarda **caminho relativo**
  (no iOS o caminho absoluto muda a cada atualização).
- Espécies: `species.id` é um slug estável (ex.: `hoplias-malabaricus`); o nome
  científico pode mudar e o antigo vira sinônimo. Catálogo em `assets/seed/species.json`
  com `seed_version`; traduções incertas marcadas `needs_review: true`.
- Recordes, estatísticas, "espécies mais usadas" e ponto aproximado são **calculados**,
  nunca armazenados.
- Mudança de schema = nova versão + migração em `data/db/` + teste de migração.

## Sincronização

- O app nunca depende do servidor: sem conta tudo funciona. Sincronizar é um job
  (`JobKind.sync`) que se reagenda a cada 15 min; fotos sobem e descem em jobs
  próprios.
- Toda escrita numa tabela do usuário grava `sync_status = pending` (inclusive
  exclusão e restauração). `rejected` = o servidor recusou; só volta a subir na
  próxima edição.
- Conflito: vence o `updated_at` maior. Uma edição local pendente mais nova que a
  do servidor não é sobrescrita pelo `pull`.
- Token só no armazenamento seguro (`TokenStore`), nunca no banco. Sair da conta
  mantém o diário e volta as linhas a `pending` (`forgetServer`).
- O segredo da localização aproximada é o da conta: o primeiro aparelho define,
  os outros adotam.
- Tabela nova sincronizada: `SyncService` (app), `logbook/sync.py` (servidor) e o
  `FakeServer` dos testes, no mesmo commit.

## Internacionalização

- Idiomas: `en` (modelo), `pt` (conteúdo pt-BR), `es`. Padrão = idioma do aparelho,
  fallback `en`. Usuário pode fixar o idioma nos ajustes.
- **Zero texto literal na UI.** Inclui `Text`, `tooltip`, `semanticsLabel`, `hintText`,
  `labelText`, SnackBars e diálogos. Tudo via `context.l10n`.
- Datas e números sempre por `intl` com o locale ativo (`core/formatting`).
- Unidades (métrico/imperial) são configuração separada do idioma.
- Toda chave nova entra nos três ARB no mesmo commit, com `@descrição`.

## Privacidade (inegociável)

- Níveis: `private` (padrão), `friends`, `approximate`, `exact`. No MVP `friends`
  se comporta como `private`.
- Cards **nunca** recebem coordenadas: o modelo de dados do card não tem lat/lng.
  Local no card: private → nenhum; friends/approximate → região; exact → nome do local.
- Fotos têm EXIF/GPS removido **na importação** (reencode). Data e local do EXIF são
  lidos antes e salvos no banco.
- Modo aproximado: `domain/services/privacy_offset` — encaixe em grade (~1 km) +
  deslocamento determinístico (HMAC com salt da instalação). Nunca aleatório por chamada.
- Mapas (`domain/services/map_sketch`): só em aproximado/exato. O card recebe um
  `MapSketch` (formas relativas, sem lat/lng). O círculo contém o ponto e nunca é
  centrado nele. Serviços externos só recebem o ponto aproximado.

## Clima

- Open-Meteo gratuita **não** permite uso comercial → não usar.
- Fase 1: **NASA POWER** (CC BY 4.0, uso comercial permitido, sem chave; atraso de
  2–3 dias). Dados preenchidos pela fila de jobs quando disponíveis. Exibir atribuição.
- Clima agora (MET Norway) só via backend (exigência dos termos deles para apps),
  só com conta e só para exibir (não é gravado). O app manda o ponto aproximado
  fino; o servidor arredonda a 2 casas antes da MET. Crédito "MET Norway" na tela.
- Fase da lua: cálculo local (`domain/services/moon`).

## Mapas

- OpenStreetMap via Overpass (ODbL: crédito em todo mapa e nos Ajustes). Só água e
  estradas principais, simplificadas e guardadas em `place_maps` (cache, não é dado
  do usuário: não exporta, não sincroniza, apaga com "Apagar todos os dados").
- Com conta, o pedido passa pelo backend (cache por região); sem conta ou com o
  servidor fora, vai direto ao Overpass. `tool/overpass_probe.dart` (workflow
  `map-probe`) testa a consulta real, porque o ambiente de desenvolvimento não
  alcança o Overpass.

## Design

Direção "Red Head" — cores e linguagem do universo da pesca (isca cabeça-vermelha,
boia, régua de medição, rio). Tokens em `core/theme/`:

| Token | Hex | Uso |
|---|---|---|
| `redHead` | `#E4262C` | ação principal (Iniciar pescaria, + Captura) |
| `deepWater` | `#0B2A33` | texto no claro, fundo no escuro |
| `paper` | `#FFFFFF` | fundo claro |
| `mist` | `#EDF2F1` | superfície secundária clara |
| `dorado` | `#F4B400` | recordes |

- Tipografia: **Archivo** (UI), **Archivo Expanded** itálico pesado para números
  grandes (cronômetro, medidas, cards), **Archivo Condensed** para dados densos.
  Fontes empacotadas em `assets/fonts` (gerar com `tool/build_fonts.py`), nunca
  baixadas em runtime.
- Uso sob sol e mão molhada: alvos de toque ≥ 56 dp (ações principais ≥ 72 dp),
  contraste AA mínimo, ações principais na parte de baixo da tela.
- Evitar clichês de UI gerada: rótulos em CAIXA ALTA, sombras cinza iguais em todos os
  cartões, gradientes decorativos, metadados unidos por "·", "→" em botões.
- Textos: frases curtas, voz ativa, a ação mantém o mesmo nome no fluxo inteiro.
- Acessibilidade: respeitar escala de fonte do sistema no app (não nos cards, que têm
  canvas fixo) e rotular ícones com `Semantics`/`tooltip` traduzidos.

## Testes

- `test/` espelha `lib/`. Domínio: testes unitários puros. Dados: Drift em memória
  (`NativeDatabase.memory()`). Telas: testes de widget com providers sobrescritos.
- Cada incremento termina com testes verdes e um commit descritivo
  (Conventional Commits: `feat:`, `fix:`, `test:`, `chore:`, `docs:`, `refactor:`).
- Nunca pular, desabilitar ou apagar teste para deixar a CI verde.
