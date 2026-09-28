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

  @override
  String get errorGeneric => 'Algo deu errado. Tente de novo.';

  @override
  String get startTripAction => 'Iniciar pescaria';

  @override
  String get resumeTripAction => 'Voltar à pescaria';

  @override
  String get homeRecentTrips => 'Últimas pescarias';

  @override
  String get homeEmptyTitle => 'Sua primeira pescaria começa aqui.';

  @override
  String get homeEmptyBody =>
      'Toque em Iniciar pescaria quando chegar na água. Cada captura leva três toques, mesmo com a mão molhada.';

  @override
  String get activeTripLabel => 'Pescaria em andamento';

  @override
  String activeTripElapsed(String duration) {
    return 'Pescando há $duration';
  }

  @override
  String activeTripStartedAt(String time) {
    return 'Começou às $time';
  }

  @override
  String get activeTripNoLocation => 'Sem localização';

  @override
  String get activeTripLocationSaved => 'Local salvo';

  @override
  String get activeTripEmpty =>
      'Nenhuma captura ainda. Toque em + Captura assim que o peixe sair da água.';

  @override
  String get activeTripMinimize => 'Minimizar';

  @override
  String get addCatchAction => '+ Captura';

  @override
  String get finishTripAction => 'Finalizar';

  @override
  String get finishTripTitle => 'Finalizar a pescaria?';

  @override
  String get finishTripBody =>
      'O cronômetro para agora. Horários e capturas continuam editáveis depois.';

  @override
  String get finishTripConfirm => 'Finalizar pescaria';

  @override
  String catchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas',
      one: '1 captura',
      zero: 'Nenhuma captura',
    );
    return '$_temp0';
  }

  @override
  String catchCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'capturas',
      one: 'captura',
    );
    return '$_temp0';
  }

  @override
  String get catchReleased => 'Solto';

  @override
  String get speciesUnknown => 'Espécie não identificada';

  @override
  String rulerHour(int hours) {
    return '$hours h';
  }

  @override
  String rulerSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Régua do tempo com $count capturas marcadas',
      one: 'Régua do tempo com 1 captura marcada',
      zero: 'Régua do tempo, nenhuma captura ainda',
    );
    return '$_temp0';
  }

  @override
  String get quickCatchTitle => 'Nova captura';

  @override
  String get quickCatchPhotoTitle => 'Primeiro a foto';

  @override
  String get quickCatchPhotoHint =>
      'Os dados de localização saem da foto antes de ela ser salva.';

  @override
  String get quickCatchTakePhoto => 'Tirar foto';

  @override
  String get quickCatchGallery => 'Galeria';

  @override
  String get quickCatchNoPhoto => 'Sem foto';

  @override
  String get quickCatchSpeciesTitle => 'Qual é o peixe?';

  @override
  String get quickCatchChangeSpecies => 'Trocar';

  @override
  String get quickCatchMoreDetails => 'Mais detalhes';

  @override
  String get quickCatchMoreDetailsHint =>
      'Peso, comprimento, isca, equipamento, profundidade';

  @override
  String get quickCatchSave => 'Salvar captura';

  @override
  String get catchSaved => 'Captura salva';

  @override
  String get photoImportFailed =>
      'Não deu para usar esta foto. A captura foi salva sem ela.';

  @override
  String get speciesSearchHint => 'Buscar: traíra, tararira, bass…';

  @override
  String get speciesSearchClear => 'Limpar busca';

  @override
  String get speciesMostUsed => 'Suas mais pescadas';

  @override
  String get speciesAll => 'Todas as espécies';

  @override
  String get speciesUnknownAction => 'Não sei a espécie';

  @override
  String speciesAlsoKnownAs(String name) {
    return 'Também: $name';
  }

  @override
  String get speciesNoResults => 'Nenhuma espécie com esse nome.';

  @override
  String speciesAddCustom(String name) {
    return 'Adicionar “$name” como espécie';
  }

  @override
  String get catchWeight => 'Peso';

  @override
  String get catchWeightOunces => 'Onças';

  @override
  String get catchLength => 'Comprimento';

  @override
  String get catchDepth => 'Profundidade';

  @override
  String get catchReleasedQuestion => 'Soltou?';

  @override
  String get catchReleasedYes => 'Soltei';

  @override
  String get catchReleasedNo => 'Levei';

  @override
  String get catchBait => 'Isca';

  @override
  String get catchGear => 'Equipamento';

  @override
  String get catchChooseBait => 'Escolher isca';

  @override
  String get catchChooseGear => 'Escolher equipamento';

  @override
  String get catchNone => 'Nenhum';

  @override
  String get catchNotes => 'Anotações';

  @override
  String get tackleNewBait => 'Nova isca';

  @override
  String get tackleNewGear => 'Novo equipamento';

  @override
  String get tackleName => 'Nome';

  @override
  String get errorInvalidNumber => 'Digite um número, como 2,5';
}
