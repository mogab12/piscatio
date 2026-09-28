# Roadmap

Marque `[x]` quando a tarefa estiver pronta, testada e commitada.

## Fase 1 — MVP offline (atual)

### 1A — Fundação e registro

- [x] Projeto Flutter em `/app`, lints estritos, CI (análise, testes, traduções, APK)
- [x] Internacionalização: ARB pt/en/es, teste de chaves, verificação de texto literal
- [x] Domínio: conversão de unidades e formatação por locale
- [x] Domínio: fase da lua
- [x] Domínio: deslocamento de privacidade (grade + HMAC)
- [x] Domínio: busca de espécies sem acento, com sinônimos
- [x] Banco Drift: pescarias, capturas, fotos, espécies, iscas, equipamentos, ajustes
- [x] Catálogo inicial: ~40 espécies da América do Sul + ~20 da América do Norte
- [x] Tema claro/escuro, fontes, rotas e navegação por abas
- [x] Onboarding: idioma, unidades, permissão de localização
- [x] Ajustes: idioma, unidades, privacidade padrão
- [x] Início: iniciar/retomar pescaria, últimas pescarias
- [x] Pescaria ativa: cronômetro, local, lista de capturas, finalizar
- [x] Captura rápida: foto (câmera/galeria/sem foto) → espécie → salvar, com desfazer
- [x] Detalhes da captura: peso, comprimento, isca, equipamento, profundidade, solto
- [x] Fotos: importação com remoção de EXIF, caminho relativo
- [x] Histórico: lista, detalhe, edição e exclusão
- [ ] **Checkpoint 1A**: testar no celular

### 1B — Clima, resumo e cards

- [ ] Fila de jobs (reprocessa ao abrir o app e quando a conexão volta)
- [ ] Clima via NASA POWER (série horária da pescaria) + atribuição
- [ ] Nome do local via geocodificação da plataforma (enfileirado sem rede)
- [ ] Resumo pós-pescaria: duração, capturas, espécies, maior captura, isca, local, lua
      (cálculo pronto em `domain/services/trip_summary.dart`, falta a tela)
- [ ] Recordes pessoais (peso e comprimento, % de melhoria, "primeira captura")
- [ ] Cards: 3 estilos, 9:16 (1080×1920) e 1:1 (1080×1080), pescaria e captura
- [ ] Cards: selo de recorde, marca discreta, local conforme privacidade
- [ ] Compartilhar via share sheet (PNG sem EXIF)
- [ ] **Checkpoint 1B**: testar no celular

### 1C — Estatísticas, retroativa e acabamento

- [ ] Estatísticas: totais, horas, espécies, recordes, isca mais produtiva
- [ ] Iscas e equipamentos: listas simples
- [ ] Pescaria retroativa com sugestão de data/local pelo EXIF
- [ ] Busca de local por nome (geocodificação da plataforma)
- [ ] Exportar dados (JSON) e apagar todos os dados
- [ ] Revisão de acessibilidade (leitor de tela nos 3 idiomas, fonte dinâmica)
- [ ] README: emulador e celular físico
- [ ] **Critérios de pronto da Fase 1** verificados (modo avião, troca de idioma/unidade)

## Fase 2 — Backend e sincronização

- [ ] Django + DRF + PostgreSQL + PostGIS em `/backend`
- [ ] Login (Google, Apple, e-mail)
- [ ] Sincronização offline-first (UUID + updated_at + tombstones)
- [ ] Backup de fotos
- [ ] Clima ao vivo (MET Norway via proxy do backend)
- [ ] Exclusão de conta (LGPD/GDPR)
- [ ] "O que funcionou?": melhores horários, lua, clima e iscas por espécie

## Fase 3 — Social

- [ ] Feed, seguidores, perfil público
- [ ] Nível de privacidade "amigos" efetivo
- [ ] Resumo do ano
- [ ] Compartilhamento direto para Stories do Instagram

## Fase 4 — Inteligência

- [ ] Identificação de espécie por foto
- [ ] Estimativa de comprimento
- [ ] Previsão de condições de pesca
