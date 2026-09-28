// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Piscatio';

  @override
  String get navFish => 'Pescar';

  @override
  String get navLogbook => 'Diário';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get unitGram => 'g';

  @override
  String get unitKilogram => 'kg';

  @override
  String get unitOunce => 'oz';

  @override
  String get unitPound => 'lb';

  @override
  String get unitCentimeter => 'cm';

  @override
  String get unitInch => 'pol';

  @override
  String get unitMeter => 'm';

  @override
  String get unitFoot => 'pés';

  @override
  String get unitCelsius => '°C';

  @override
  String get unitFahrenheit => '°F';

  @override
  String get unitHectopascal => 'hPa';

  @override
  String get unitInchOfMercury => 'inHg';

  @override
  String get unitKilometerPerHour => 'km/h';

  @override
  String get unitMilePerHour => 'mph';

  @override
  String get unitMillimeter => 'mm';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get moonNew => 'Lua nova';

  @override
  String get moonWaxingCrescent => 'Lua crescente';

  @override
  String get moonFirstQuarter => 'Quarto crescente';

  @override
  String get moonWaxingGibbous => 'Crescente gibosa';

  @override
  String get moonFull => 'Lua cheia';

  @override
  String get moonWaningGibbous => 'Minguante gibosa';

  @override
  String get moonLastQuarter => 'Quarto minguante';

  @override
  String get moonWaningCrescent => 'Lua minguante';

  @override
  String get privacyPrivate => 'Só eu';

  @override
  String get privacyFriends => 'Amigos';

  @override
  String get privacyApproximate => 'Região aproximada';

  @override
  String get privacyExact => 'Local exato';

  @override
  String get privacyPrivateDescription =>
      'Os cards nunca mostram onde você pescou.';

  @override
  String get privacyFriendsDescription =>
      'Por enquanto funciona como “Só eu”. Amigos chegam numa próxima versão.';

  @override
  String get privacyApproximateDescription =>
      'Os cards mostram só a região, como a cidade. O ponto é deslocado alguns quilômetros.';

  @override
  String get privacyExactDescription =>
      'Os cards mostram o nome do local. Coordenadas nunca aparecem.';

  @override
  String get unitsMetric => 'Métrico';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get unitsMetricExample => 'kg, cm, m, °C';

  @override
  String get unitsImperialExample => 'lb, pol, pés, °F';

  @override
  String get baitTypeNatural => 'Isca natural';

  @override
  String get baitTypeArtificial => 'Isca artificial';

  @override
  String get baitTypeFly => 'Mosca';

  @override
  String get gearTypeCombo => 'Vara e molinete/carretilha';

  @override
  String get gearTypeRod => 'Vara';

  @override
  String get gearTypeReel => 'Molinete/carretilha';

  @override
  String get gearTypeLine => 'Linha';

  @override
  String get tackleTypeOther => 'Outro';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionBack => 'Voltar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionUndo => 'Desfazer';

  @override
  String onboardingStepOf(int step, int total) {
    return 'Passo $step de $total';
  }

  @override
  String get onboardingTagline => 'Cada pescaria vira uma história.';

  @override
  String get onboardingLanguageTitle => 'Idioma';

  @override
  String get onboardingUnitsTitle => 'Como você mede seus peixes?';

  @override
  String get onboardingUnitsHint => 'Dá para trocar depois nos Ajustes.';

  @override
  String get onboardingLocationTitle => 'Onde você está pescando?';

  @override
  String get onboardingLocationWhy =>
      'A localização guarda onde cada pescaria aconteceu e permite buscar o clima daquele dia.';

  @override
  String get onboardingLocationPrivacy =>
      'O local fica no seu celular. Os cards nunca mostram coordenadas, e você decide quanto revelar.';

  @override
  String get onboardingLocationOffline =>
      'Funciona sem sinal. O clima é buscado quando a internet voltar.';

  @override
  String get onboardingLocationAllow => 'Permitir localização';

  @override
  String get onboardingLocationSkip => 'Agora não';

  @override
  String get settingsSectionPreferences => 'Preferências';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String settingsLanguageDevice(String language) {
    return 'Idioma do aparelho: $language';
  }

  @override
  String get settingsUnits => 'Unidades';

  @override
  String settingsUnitsValue(String system, String examples) {
    return '$system ($examples)';
  }

  @override
  String get settingsDefaultPrivacy => 'Privacidade padrão do local';

  @override
  String get settingsLicenses => 'Licenças de código aberto';
}
