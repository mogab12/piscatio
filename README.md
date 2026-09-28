# Piscatio

Diário social de pescaria: registre cada pescaria, guarde as capturas e compartilhe
cards bonitos no Instagram e no WhatsApp. Funciona sem internet.

- App Flutter (Android e iOS): [`app/`](app/)
- Convenções do projeto: [`CLAUDE.md`](CLAUDE.md)
- Roadmap e status: [`docs/ROADMAP.md`](docs/ROADMAP.md)
- Direção visual: [`docs/DESIGN.md`](docs/DESIGN.md)

## Status

Fase 1A pronta: onboarding, ajustes, pescaria ativa, captura rápida com foto sem
EXIF, histórico com edição e exclusão. Clima, resumo e cards chegam na 1B.

## Jeito mais rápido de testar (Android, sem instalar nada)

Cada push gera um APK na CI.

1. Abra **Actions** no GitHub, escolha a última execução verde do workflow `app`.
2. Em **Artifacts**, baixe `piscatio-android-arm64` e descompacte o `.zip`.
3. Envie o `app-arm64-v8a-release.apk` para o celular (cabo, Drive, WhatsApp…) e
   abra. O Android vai pedir para permitir a instalação de "fontes desconhecidas"
   para o app que abriu o arquivo.

O APK é assinado com a chave de depuração: serve para teste, não para a loja.

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

## Dados de clima (Fase 1B)

A Open-Meteo gratuita não permite uso comercial. O app vai usar a **NASA POWER**
(CC BY 4.0, uso comercial permitido, sem chave), com atraso de 2 a 3 dias e crédito
visível no app. Clima ao vivo fica para a Fase 2, através do backend.

## Limitações conhecidas da 1A

- Sem clima, resumo pós-pescaria, cards, estatísticas e pescaria retroativa (1B/1C).
- O nome do local é digitado pelo usuário (busca automática chega na 1B).
- No Android, se o sistema encerrar o app enquanto a câmera está aberta, a foto
  daquela captura se perde (recuperação chega na 1C).
- Validado por testes automatizados (unitários e de widget) e pela CI, que compila
  o APK. Ainda não rodou em aparelho real: esse é o objetivo do checkpoint 1A.
