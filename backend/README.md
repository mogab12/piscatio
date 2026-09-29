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
| `GET /health` | verificação do servidor |

Tudo em `/api` exige `Authorization: Bearer <token>`, menos o login.

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
2. Confirme. O Render gera a `DJANGO_SECRET_KEY`, cria o banco e publica em
   `https://piscatio-api.onrender.com` (ou nome parecido).
3. Opcional, em **Environment**: SMTP para os e-mails e R2 para as fotos.

No plano gratuito o servidor dorme sem uso (o primeiro acesso demora) e o
banco gratuito expira depois de 30 dias; o disco não é permanente, então para
backup de fotos de verdade configure o R2.
