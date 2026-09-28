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

- [x] Fila de jobs (reprocessa ao abrir o app, a cada 15 min e quando a conexão volta)
- [x] Clima via NASA POWER (série horária da pescaria) + atribuição nos Ajustes
- [x] Nome do local via geocodificação da plataforma (enfileirado sem rede)
- [x] Resumo pós-pescaria: duração, capturas, espécies, régua do tempo, recordes,
      maior captura, isca, região, lua e clima, com "Criar card"
- [x] Recordes pessoais (peso e comprimento, % de melhoria, "primeira da espécie"),
      sempre calculados
- [x] Cards: Régua, Carta e Etiqueta, 9:16 (1080×1920) e 1:1 (1080×1080), pescaria e captura
- [x] Cards: recorde na linguagem de cada estilo, marca discreta, local conforme
      privacidade (e chave "Mostrar local")
- [x] Compartilhar via share sheet (PNG renderizado pelo app: não carrega EXIF)
- [x] **Checkpoint 1B**: testado no celular (feedback aplicado na 1C: marca, cards, atualização)

### 1C — Estatísticas, retroativa e acabamento

- [x] Estatísticas (aba Números): totais, horas, capturas por hora, espécies, iscas,
      recordes e melhor pescaria
- [x] Iscas e equipamentos: listas com adicionar, editar, arquivar e restaurar
- [x] Pescaria passada com data, horário e local sugeridos pelas fotos (EXIF lido
      antes de ser removido); cada foto vira uma captura
- [x] Busca de local por nome (geocodificação da plataforma)
- [x] Exportar dados (JSON pelo menu de compartilhar) e apagar todos os dados
- [x] Recuperar a foto quando o Android encerra o app com a câmera aberta
- [x] Revisão de acessibilidade das telas novas (fonte 1,6×, rótulos para leitor de
      tela, alvos ≥ 56 dp)
- [x] Marca: símbolo da boia, assinatura nos cards, zonas seguras do story;
      personalização dos cards (cor, foto, detalhes, legenda)
- [x] README: emulador, celular físico, atualizar sem desinstalar
- [x] Critérios de pronto da Fase 1: offline-first coberto pelos testes (rede sempre
      falha nos testes de widget e nada trava), troca de idioma e unidade em tempo
      real (testes de ajustes)
- [ ] **Checkpoint 1C**: testar no celular

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
