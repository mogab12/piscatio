# Contas de negócio (pesqueiros e afins)

Como o Piscatio vai ganhar dinheiro sem trair a confiança de quem pesca: lugares e
serviços de pesca (pesqueiros, pousadas, guias, lojas, marinas, barcos) criam um
perfil público no app, pagam para aparecer nas buscas e para entender o que os
pescadores que frequentam o lugar preferem. A base está pronta desde a Fase 2;
a interface completa para os negócios vem depois.

## Peças

| Peça | Onde | O quê |
|---|---|---|
| Lugar (`Venue`) | `backend/venues` | Perfil público: nome, tipo, descrição, localização (é um endereço comercial, não um pesqueiro secreto), contatos, espécies, comodidades, horários, selo de verificado. Estados: rascunho → publicado → suspenso. |
| Equipe (`VenueMember`) | `backend/venues` | Pessoas que administram o perfil: dono, gerente (editam) e equipe (só leem). |
| Favoritos e contadores | `backend/venues` | Favoritar um lugar; contadores diários de visualizações do perfil e de aparições nas buscas. |
| Planos e assinaturas | `backend/billing` | Um plano lista recursos (`listing`, `insights`, e outros no futuro). A assinatura dá esses recursos a um lugar enquanto está vigente. |
| Cobrança | `backend/billing/providers.py` | Interface de provedor. Hoje, **manual** (a equipe ativa no admin). Stripe ou Mercado Pago entram como outro provedor, sem mudar o resto. |
| Chaves de recurso | `backend/flags` | Recursos saem desligados e são abertos remotamente: para todos, para uma porcentagem das contas, só para a equipe ou para contas escolhidas. O app recebe tudo em `/api/config` a cada sincronização. |
| Pescaria → lugar | `logbook.Trip.venue` e `trips.venue_id` no app | Quem pesca escolhe, se quiser, em que lugar foi a pescaria. Sincroniza como o resto. |

## Regras

- **Aparecer na busca** exige perfil publicado **e** assinatura vigente com o recurso
  `listing`. A equipe do Piscatio verifica e publica.
- **Dados para os negócios** (recurso `insights`): só totais das pescarias ligadas
  ao lugar, e somente de quem ligou a chave **"Ajudar pesqueiros com números
  anônimos"** (desligada por padrão, na tela Conta). Nada aparece com menos de 10
  pescadores diferentes; grupos com menos de 5 pessoas (uma espécie rara, uma isca
  incomum) são omitidos; o total de pescadores é arredondado para baixo, de 5 em
  5. Nunca nomes, nunca pontos, nunca coordenadas de ninguém. Os limites ficam nas
  variáveis `VENUE_INSIGHTS_MIN_ANGLERS` e `VENUE_INSIGHTS_MIN_GROUP`.
- **Busca de lugares perto de uma pescaria** usa o ponto aproximado da pescaria,
  nunca o ponto exato.
- Um lugar que deixou de existir não impede a sincronização da pescaria: o vínculo
  some e a pescaria segue.
- Negócios nunca recebem dados de uma pessoa que não os favoritou nem ligou uma
  pescaria a eles.

## Rotas

| Rota | Para quem |
|---|---|
| `GET /api/config` | toda conta: chaves de recurso e build mínimo do app |
| `GET /api/venues?q=&lat=&lon=&radius_km=&kind=&species=` | toda conta: busca (sem acento, por distância) |
| `POST /api/venues` | um negócio se cadastra (vira rascunho; quem cria é o dono) |
| `GET/PATCH /api/venues/<id>` | perfil; editar é para dono e gerente |
| `POST/DELETE /api/venues/<id>/favorite` | favoritar |
| `GET /api/venues/<id>/insights` | equipe do lugar com o recurso `insights` |
| `GET /api/me/venues` | lugares que a pessoa administra, com papel e recursos |
| `PATCH /api/me` | a chave de consentimento `share_insights` |

## No app

- `FeatureFlags` (`domain/models/venue.dart`) e `featureProvider(chave)` decidem o
  que aparece. Com `venues` desligado, nada muda para ninguém.
- Com `venues` ligado: campo **Pesqueiro** em Editar pescaria (busca por perto e por
  nome), nome do lugar no detalhe da pescaria e a chave de consentimento na Conta.
- Lugares vistos ficam no cache `venue_cache` (como os mapas: não é dado da pessoa,
  não exporta, não sincroniza, apaga com "Apagar todos os dados").

## Como abrir para teste

1. No admin do servidor (`/admin`), crie um **Plano** com recursos
   `["listing", "insights"]`.
2. Crie um **Lugar**, publique-o e adicione uma **Assinatura** ativa com esse plano.
3. Em **Feature flags**, ligue `venues` (para todos, uma porcentagem ou só a sua
   conta). O app recebe a mudança na próxima sincronização.

## Próximos passos previstos

- Área do negócio no app (editar perfil, fotos, ver os números).
- Cobrança automática (Stripe ou Mercado Pago) como novo provedor.
- Promoções e eventos (torneios), reservas, destaque pago nas buscas: cada um
  como um novo recurso de plano, aberto por chave.
- Assinatura premium para pescadores (a mesma estrutura de planos).
