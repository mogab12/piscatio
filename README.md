# Piscatio

Diário social de pescaria: registre cada pescaria, guarde as capturas e compartilhe
cards bonitos no Instagram e no WhatsApp. Funciona sem internet.

- App Flutter (Android e iOS): [`app/`](app/)
- Convenções do projeto: [`CLAUDE.md`](CLAUDE.md)
- Roadmap e status: [`docs/ROADMAP.md`](docs/ROADMAP.md)
- Direção visual: [`docs/DESIGN.md`](docs/DESIGN.md)

## Status

Fase 1 pronta (1A, 1B e 1C): pescaria ativa e captura rápida com foto sem EXIF,
histórico, resumo pós-pescaria, recordes pessoais, clima da NASA POWER, cards em
três estilos (Régua, Carta e Etiqueta) com personalização, estatísticas, iscas e
equipamentos, pescaria passada a partir das fotos, busca de local por nome,
exportação e exclusão de dados. Tudo funciona sem internet; a Fase 2 traz conta e
sincronização.

## Jeito mais rápido de testar (Android, sem instalar nada)

Cada push gera um APK na CI.

1. Abra **Actions** no GitHub, escolha a última execução verde do workflow `app`.
2. Em **Artifacts**, baixe `piscatio-android-arm64` e descompacte o `.zip`.
3. Envie o `app-arm64-v8a-release.apk` para o celular (cabo, Drive, WhatsApp…) e
   abra. O Android vai pedir para permitir a instalação de "fontes desconhecidas"
   para o app que abriu o arquivo.

O APK é de teste, não para a loja.

### Atualizar sem desinstalar

O Android só instala uma versão por cima da outra se as duas tiverem a mesma
assinatura. A CI assina com uma chave fixa guardada no segredo
`PISCATIO_KEYSTORE_B64` do repositório (**Settings → Secrets and variables →
Actions → New repository secret**). O valor é o arquivo da chave em base64; a
senha fica no workflow, porque sem o arquivo ela não serve para nada. Sem o
segredo, cada build sai com uma chave descartável e é preciso desinstalar antes de
instalar a nova versão. Guarde a chave com cuidado: quem a tiver consegue assinar
um APK que o celular aceita como atualização deste app de teste. A chave da loja
será outra.

## Rodar a partir do código

### Pré-requisitos

- Flutter **3.47.5** (stable) — <https://docs.flutter.dev/get-started/install>
- Android: Android Studio (SDK e emulador) e Java 17
- iOS: um Mac com Xcode e CocoaPods

`flutter doctor` mostra o que falta. O código gerado (Drift, freezed, traduções) já
está no repositório, então basta:

```bash
cd app
flutter pub get
flutter run
```

### Emulador Android

1. Android Studio → **Device Manager** → **Create device** (ex.: Pixel 8, Android 15).
2. `flutter emulators` para listar e `flutter emulators --launch <id>` para abrir.
3. `flutter run` dentro de `app/`.

Para testar localização no emulador: menu **⋯ → Location**, escolha um ponto e
clique em **Set location**. Para a câmera, o emulador usa uma cena virtual.

### Celular Android físico

1. Em **Configurações → Sobre o telefone**, toque 7 vezes em **Número da versão**.
2. Em **Opções do desenvolvedor**, ative **Depuração USB**.
3. Conecte o cabo, aceite a chave RSA no celular e confira com `flutter devices`.
4. `flutter run --release` (mais fluido que o modo debug).

### Simulador iOS (Mac)

```bash
open -a Simulator
cd app && flutter run
```

### iPhone físico (Mac)

1. `cd app/ios && pod install`, depois abra `Runner.xcworkspace` no Xcode.
2. Em **Runner → Signing & Capabilities**, escolha seu **Team** (uma conta Apple
   gratuita serve para testar por 7 dias). Se o identificador `app.piscatio` já
   estiver em uso na sua conta, troque por outro único.
3. Conecte o iPhone, ative o **Modo Desenvolvedor** (Ajustes → Privacidade e
   Segurança) e rode `flutter run --release` em `app/`.
4. Na primeira vez, confie no desenvolvedor em **Ajustes → Geral → VPN e
   Gerenciamento de Dispositivos**.

## Verificação (igual à CI)

```bash
cd app
tool/verify.sh
```

Roda geradores, formatação, análise estrita, checagem de traduções (pt, en, es),
checagem de texto literal na interface e todos os testes.

Capturas de tela para revisão de design:

```bash
SCREENSHOTS=1 flutter test test/screenshots   # PNGs em app/build/screenshots/
```

## Privacidade

- Localização padrão: "Só eu". Coordenadas nunca vão para cards.
- Fotos são regravadas sem EXIF/GPS no momento da importação.
- O modo "Região aproximada" desloca o ponto de forma consistente (grade + HMAC),
  para que várias pescarias no mesmo lugar não revelem o pesqueiro.

## Dados de clima

A Open-Meteo gratuita não permite uso comercial. O app usa a **NASA POWER**
(CC BY 4.0, uso comercial permitido, sem chave). Os dados saem com 2 a 3 dias de
atraso: ao finalizar, a pescaria entra numa fila que tenta de novo ao abrir o app,
a cada 15 minutos e quando a internet volta. O crédito fica nos Ajustes. Clima ao
vivo fica para a Fase 2, através do backend.

## O que testar no checkpoint 1C

1. **Números:** a aba mostra totais, horas pescando, capturas por horário (toque
   numa barra para ler o valor), espécies e iscas que mais pegam, recordes e a
   melhor pescaria.
2. **Pescaria passada:** no Diário, "Registrar pescaria passada". Adicione fotos da
   galeria tiradas numa pescaria: a data, o horário e o local são sugeridos por
   elas, e cada foto vira uma captura. Salve e complete as espécies.
3. **Buscar local por nome** (na pescaria passada ou em Editar pescaria): digite o
   nome de um rio ou represa, escolha o resultado.
4. **Ajustes → Iscas e equipamentos:** adicione, edite e arquive.
5. **Ajustes → Exportar dados:** o arquivo JSON abre no menu de compartilhar.
   **Apagar todos os dados:** confirma antes, apaga tudo e volta ao início.
6. **Cards:** abas Estilo, Cor, Foto, Detalhes e Legenda; a marca aparece no alto
   de todos os estilos.
7. **Modo avião:** tudo continua funcionando (clima e nome da região ficam na fila
   e chegam quando a internet voltar).

## O que testar no checkpoint 1B

1. Inicie uma pescaria com o GPS ligado, registre duas ou três capturas (com foto e
   comprimento em pelo menos uma) e finalize. O resumo abre na hora.
2. No resumo, toque em **Criar card**. Troque entre Régua, Carta e Etiqueta, entre
   Story e Quadrado, e compartilhe no WhatsApp ou salve a imagem.
3. Mude a privacidade da pescaria (Editar) e veja o local do card mudar: privada
   não mostra nada, aproximada mostra só a região, exata mostra o nome do local.
4. Registre outra captura da mesma espécie, maior que a anterior: o card mostra o
   recorde (marca dourada na Régua, linha dourada na Carta, carimbo na Etiqueta).
5. Volte à pescaria 3 dias depois: o painel de clima aparece com os dados.

## Limitações conhecidas

- O clima só existe 2 a 3 dias depois da pescaria (limite da fonte gratuita).
- Nome da região e busca de local usam o geocodificador do sistema (Android/iOS) e
  precisam de internet; sem ela, o nome da região fica na fila.
- A exportação leva os dados em JSON; as fotos ficam no celular (backup de fotos
  chega com a conta, na Fase 2).
- Se o Android encerrar o app com a câmera aberta, a foto volta na próxima
  abertura e a captura continua, se houver pescaria em andamento.
- Validado por testes automatizados e pela CI, que compila o APK.
