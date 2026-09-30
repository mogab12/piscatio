# Piscatio — backend (Fase 2)

Django + DRF + PostgreSQL/PostGIS. Guarda a conta e uma cópia do diário para
sincronizar entre aparelhos e fazer backup das fotos. O app continua
offline-first: o banco do celular é a fonte da verdade e a sincronização roda
pela fila de jobs quando há internet.

## O que tem

| Rota | O quê |
|---|---|
| `POST /api/auth/email/start` | envia um código de 6 dígitos por e-mail |
| `POST /api/auth/email/verify` | troca e-mail + código por um token (um por aparelho) |
| `POST /api/auth/google` | login com Google (se `GOOGLE_CLIENT_IDS` estiver configurado) |
| `POST /api/auth/logout` | revoga o token deste aparelho |
| `GET /api/me` · `POST /api/me/privacy-secret` | conta; segredo da localização aproximada, igual em todos os aparelhos |
| `POST /api/sync/push` · `GET /api/sync/pull?since=` | sincronização (ver abaixo) |
| `PUT/GET /api/photos/<id>/file` | envio e download da imagem de uma foto |
| `GET /api/account` · `DELETE /api/account` | exportar tudo · apagar a conta e todos os dados (LGPD/GDPR) |
| `GET /api/conditions/weather?lat=&lon=` | clima agora (MET Norway), ponto arredondado a ~1 km |
| `GET /api/conditions/map?lat=&lon=` | dados de mapa do OpenStreetMap, com cache por região |
| `GET/PUT/DELETE /api/social/profile` · `PUT /api/social/profile/avatar` | perfil público: criar, mudar, sair da comunidade; foto do perfil |
| `GET /api/social/people?q=` · `GET /api/social/people/<handle>` | buscar pessoas · perfil com contagens e relação |
| `POST/DELETE /api/social/people/<handle>/follow` | seguir (ou pedir, se o perfil for fechado) · deixar de seguir |
| `GET /api/social/requests` · `POST/DELETE /api/social/requests/<handle>` | pedidos para seguir · aceitar/recusar |
| `POST/DELETE /api/social/people/<handle>/block` · `GET /api/social/blocks` | bloquear · desbloquear · bloqueados |
| `GET /api/social/feed?scope=following\|discover&before=` | feed (quem você segue) ou descobrir (perfis abertos) |
| `PUT/GET/DELETE /api/social/posts/<id>` · `PUT …/image` · `POST/DELETE …/like` | publicar um card · imagem · curtir |
| `POST /api/social/reports` | denunciar publicação ou perfil (vai para o admin) |
| `GET /health` | verificação do servidor |

Tudo em `/api` exige `Authorization: Bearer <token>`, menos o login e os links
assinados de imagem (`/api/social/media/<assinatura>`).

### Comunidade

- Só participa quem cria um perfil (`@nome`); sem perfil, a conta é só backup
  do diário. Perfil nasce **fechado**: seguir exige aprovação.
- Amigos = pessoas que se seguem. Publicação "amigos" só chega a amigos;
  "pública" chega a todos se o perfil for aberto, e só a seguidores aceitos se
  for fechado. Bloqueio esconde tudo nos dois sentidos. Regras em
  `social/rules.py`, usadas por todas as rotas.
- A publicação é a imagem do card (que nunca tem coordenadas) com poucos dados
  (tipo, espécie, pesqueiro). O id vem do app, então reenviar não duplica.
- Imagens saem por link assinado que vale de 1 a 2 dias e não muda no mesmo
  dia (o app guarda em cache). Com S3/R2, o próprio storage assina.
- Moderação no admin: denúncias, "esconder publicação" (só o autor continua
  vendo).
- Exportar a conta inclui perfil, publicações, quem segue e é seguido;
  apagar a conta apaga as imagens.

### Sincronização

- Cada linha leva o id do app (UUID v7), `updated_at` e `deleted_at`.
- Conflito: vence a edição mais recente (`updated_at` da própria linha).
  Exclusão é uma edição como outra (lápide), então chega a todos os aparelhos.
- Cada escrita aceita recebe o próximo `server_seq`. O `pull` devolve o que
  mudou depois do cursor, em páginas; os `push` de uma pessoa rodam um de cada
  vez, então nenhum `pull` pula linha.
- Ninguém lê nem altera linha de outra pessoa (testado).

## Rodar localmente

Precisa de PostgreSQL com PostGIS e das bibliotecas GDAL/GEOS.

```bash
cd backend
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
# banco local: usuário/senha/banco "piscatio" (ou defina DATABASE_URL)
DJANGO_DEBUG=1 python manage.py migrate
DJANGO_DEBUG=1 python manage.py runserver
DJANGO_DEBUG=1 pytest          # testes
ruff check . && ruff format --check .
```

Sem SMTP configurado, o código de login aparece no log do servidor.

## Variáveis de ambiente

| Variável | Para quê |
|---|---|
| `DJANGO_SECRET_KEY` | obrigatória em produção |
| `DATABASE_URL` | PostgreSQL com PostGIS |
| `DJANGO_ALLOWED_HOSTS` | padrão: `localhost,127.0.0.1,.onrender.com` |
| `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `DEFAULT_FROM_EMAIL` | envio dos códigos (ex.: SMTP do Resend) |
| `GOOGLE_CLIENT_IDS` | ids de cliente OAuth aceitos no login com Google |
| `AWS_STORAGE_BUCKET_NAME`, `AWS_S3_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | fotos em armazenamento S3 (ex.: Cloudflare R2). Sem isso, ficam no disco do servidor |

## Publicar no Render

O `render.yaml` na raiz do repositório cria o serviço (Docker) e o banco:

1. Em <https://dashboard.render.com/blueprints>, **New Blueprint Instance**,
   escolha este repositório e o branch.
2. Confirme. O Render gera a `DJANGO_SECRET_KEY`, cria o banco (com PostGIS,
   ativado pela primeira migração) e publica em
   `https://piscatio-api.onrender.com` (ou nome parecido).
3. Abra `https://<endereço>/health`: deve responder `{"ok": true}`.
4. Se o endereço não for `https://piscatio-api.onrender.com`, crie no GitHub a
   variável `PISCATIO_API` (**Settings → Secrets and variables → Actions →
   Variables**) com o endereço. Os próximos APKs já saem apontando para ele; no
   APK atual, dá para trocar em **Conta → Servidor**.
5. Opcional, em **Environment**: SMTP para os e-mails e R2 para as fotos.

### E-mail do código de login

Sem `EMAIL_HOST`, o código não é enviado: aparece no log do servidor (**Logs** no
Render, procure "Seu código do Piscatio"). Serve para testar sozinho. Para enviar
de verdade, um SMTP como o do Resend (gratuito para poucos e-mails):
`EMAIL_HOST=smtp.resend.com`, `EMAIL_PORT=587` (ou `2587`, se a porta 587 estiver
bloqueada), `EMAIL_HOST_USER=resend`, `EMAIL_HOST_PASSWORD=<chave da API>` e um
`DEFAULT_FROM_EMAIL` de um domínio verificado. Se o envio falhar, o servidor
responde 503 e registra o erro no log.

### Plano gratuito

O servidor dorme depois de uns 15 minutos sem uso (o primeiro acesso pode levar
até um minuto) e o banco gratuito expira depois de 30 dias. O disco não é
permanente, então para backup de fotos de verdade configure o R2
(`AWS_STORAGE_BUCKET_NAME`, `AWS_S3_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`).
