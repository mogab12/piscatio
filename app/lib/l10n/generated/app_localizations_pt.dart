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

  @override
  String get historyEmpty =>
      'As pescarias finalizadas aparecem aqui, mês a mês.';

  @override
  String get tripNotFound => 'Esta pescaria não existe mais.';

  @override
  String get catchNotFound => 'Esta captura não existe mais.';

  @override
  String get tripNoCatches => 'Nenhuma captura nesta pescaria.';

  @override
  String get tripAddCatch => 'Adicionar captura';

  @override
  String tripTimeRange(String start, String end) {
    return 'Das $start às $end';
  }

  @override
  String get tripStatDuration => 'pescando';

  @override
  String speciesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'espécies',
      one: 'espécie',
    );
    return '$_temp0';
  }

  @override
  String tripBiggestCatch(String species, String measure) {
    return 'Maior: $species, $measure';
  }

  @override
  String get deleteTripTitle => 'Excluir pescaria';

  @override
  String get deleteTripBody =>
      'As capturas e fotos desta pescaria também serão excluídas. Não dá para desfazer.';

  @override
  String get deleteCatchTitle => 'Excluir captura';

  @override
  String get deleteCatchBody => 'A captura e a foto dela serão excluídas.';

  @override
  String get editTripTitle => 'Editar pescaria';

  @override
  String get editTripDate => 'Data';

  @override
  String get editTripStart => 'Início';

  @override
  String get editTripEnd => 'Fim';

  @override
  String get editTripEndBeforeStart => 'O fim precisa ser depois do início.';

  @override
  String get editTripPlace => 'Nome do local';

  @override
  String get editTripPlaceHelp => 'Aparece nos cards só com “Local exato”.';

  @override
  String get editTripRegion => 'Região';

  @override
  String get editTripRegionHelp =>
      'Cidade ou estado, como Cuiabá, MT. Aparece com “Região aproximada”.';

  @override
  String get editTripPrivacy => 'Privacidade do local';

  @override
  String get catchPhoto => 'Foto';

  @override
  String get catchAddPhoto => 'Adicionar foto';

  @override
  String get catchReplacePhoto => 'Trocar';

  @override
  String get catchRemovePhoto => 'Remover';

  @override
  String get catchTime => 'Horário da captura';

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String get weatherPending =>
      'O clima desta pescaria fica pronto 2 a 3 dias depois.';

  @override
  String get weatherUnavailable =>
      'Sem clima para esta pescaria (sem local ou sem dados).';

  @override
  String get weatherTemperature => 'Temperatura';

  @override
  String get weatherPressure => 'Pressão';

  @override
  String get weatherPressureFalling => 'Pressão caindo';

  @override
  String get weatherPressureRising => 'Pressão subindo';

  @override
  String get weatherPressureSteady => 'Pressão estável';

  @override
  String get weatherWind => 'Vento';

  @override
  String get weatherRain => 'Chuva';

  @override
  String get weatherSource => 'Clima: NASA POWER';

  @override
  String get compassN => 'N';

  @override
  String get compassNE => 'NE';

  @override
  String get compassE => 'L';

  @override
  String get compassSE => 'SE';

  @override
  String get compassS => 'S';

  @override
  String get compassSW => 'SO';

  @override
  String get compassW => 'O';

  @override
  String get compassNW => 'NO';

  @override
  String get settingsWeatherData => 'Dados de clima';

  @override
  String get settingsWeatherDataCredit =>
      'Projeto NASA POWER, NASA Langley Research Center. CC BY 4.0.';

  @override
  String get brandName => 'Piscatio';

  @override
  String cardBiggestValue(String species, String measure) {
    return '$species, $measure';
  }

  @override
  String cardCatchNumber(String number) {
    return 'Nº $number';
  }

  @override
  String get cardFieldSpecies => 'Espécie';

  @override
  String get cardFieldCommonName => 'Nome popular';

  @override
  String get cardFieldPlace => 'Local';

  @override
  String get cardFieldDate => 'Data';

  @override
  String get cardFieldTime => 'Hora';

  @override
  String get cardFieldLength => 'Comprimento';

  @override
  String get cardFieldWeight => 'Peso';

  @override
  String get cardFieldBait => 'Isca';

  @override
  String get cardFieldWind => 'Vento';

  @override
  String get cardFieldAir => 'Ar';

  @override
  String get cardFieldPressure => 'Pressão';

  @override
  String get cardFieldMoon => 'Lua';

  @override
  String get cardFieldDuration => 'Duração';

  @override
  String get cardFieldBiggest => 'Maior';

  @override
  String get cardFieldReleased => 'Solto';

  @override
  String get cardFieldKept => 'Levado';

  @override
  String get cardFieldFate => 'Destino';

  @override
  String get cardFieldLog => 'Registro de campo';

  @override
  String cardPreviousRecord(String measure) {
    return 'recorde anterior $measure';
  }

  @override
  String cardRecordImprovement(String improvement) {
    return 'Recorde pessoal, $improvement';
  }

  @override
  String get cardRecord => 'Recorde pessoal';

  @override
  String get cardFirstOfSpecies => 'Primeira da espécie';

  @override
  String cardRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordes pessoais',
      one: '1 recorde pessoal',
    );
    return '$_temp0';
  }

  @override
  String get cardHoursUnit => 'h';

  @override
  String cardMoreCatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e mais $count',
      one: 'e mais 1',
    );
    return '$_temp0';
  }

  @override
  String get cardCreate => 'Criar card';

  @override
  String get cardStyleBoard => 'Régua';

  @override
  String get cardStyleChart => 'Carta';

  @override
  String get cardStyleTag => 'Etiqueta';

  @override
  String get cardFormatStory => 'Story';

  @override
  String get cardFormatSquare => 'Quadrado';

  @override
  String get cardShowPlace => 'Mostrar local';

  @override
  String get cardPlacePrivate =>
      'Esta pescaria é privada: o card não mostra onde foi.';

  @override
  String get cardPlaceRegion => 'Mostra só a região, nunca o ponto.';

  @override
  String get cardPlaceUnknown => 'Nenhum nome de local salvo nesta pescaria.';

  @override
  String get cardShare => 'Compartilhar';

  @override
  String get cardShareFailed => 'Não deu para gerar a imagem. Tente de novo.';

  @override
  String cardPreviewLabel(String style, String format) {
    return 'Prévia do card: $style, $format';
  }

  @override
  String get actionClose => 'Fechar';

  @override
  String get summaryTitle => 'Pescaria finalizada';

  @override
  String get summaryRecords => 'Recordes';

  @override
  String summaryTopBait(String bait) {
    return 'Isca que mais pegou: $bait';
  }

  @override
  String summaryRecordLine(String species, String measure) {
    return '$species, $measure';
  }

  @override
  String get bootStepDatabase => 'Abrindo o diário…';

  @override
  String get bootStepCatalog => 'Carregando as espécies…';

  @override
  String get bootSlow => 'Está demorando mais que o normal.';

  @override
  String get bootFailedTitle => 'O app não conseguiu abrir';

  @override
  String get bootFailedBody =>
      'Tire um print desta tela e mande para a gente. Seus dados continuam no celular.';

  @override
  String get bootRetry => 'Tentar de novo';

  @override
  String get bootCopyDetails => 'Copiar detalhes';

  @override
  String get brandTagline => 'Diário de pesca';

  @override
  String get cardSectionStyle => 'Estilo';

  @override
  String get cardSectionPhoto => 'Foto';

  @override
  String get cardSectionDetails => 'Detalhes';

  @override
  String get cardSectionCaption => 'Legenda';

  @override
  String get cardNoPhoto => 'Sem foto';

  @override
  String get cardNoPhotos => 'Sem fotos para usar no card.';

  @override
  String cardPhotoOption(String number) {
    return 'Foto $number';
  }

  @override
  String get cardShowWeather => 'Clima e lua';

  @override
  String get cardShowBait => 'Isca';

  @override
  String get cardCaptionHint => 'Escreva uma legenda (opcional)';

  @override
  String get cardFieldNotes => 'Observações';

  @override
  String get navStats => 'Números';

  @override
  String get statsTitle => 'Seus números';

  @override
  String get statsEmpty => 'Seus números aparecem depois da primeira pescaria.';

  @override
  String statsTripsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pescarias',
      one: 'pescaria',
    );
    return '$_temp0';
  }

  @override
  String statsReleased(String percent) {
    return '$percent soltos';
  }

  @override
  String statsPerHour(String rate) {
    return '$rate por hora pescando';
  }

  @override
  String get statsByHourTitle => 'Capturas por horário';

  @override
  String statsPeakHour(String start, String end) {
    return 'Mais capturas entre $start e $end';
  }

  @override
  String statsHourBar(String time, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas',
      one: '1 captura',
    );
    return '$time: $_temp0';
  }

  @override
  String get statsSpeciesTitle => 'Espécies mais pescadas';

  @override
  String get statsBaitsTitle => 'Iscas que mais pegam';

  @override
  String get statsRecordsTitle => 'Recordes pessoais';

  @override
  String get statsBestTrip => 'Melhor pescaria';

  @override
  String statsBestTripValue(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas',
      one: '1 captura',
    );
    return '$date: $_temp0';
  }

  @override
  String statsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas',
      one: '1 captura',
    );
    return '$_temp0';
  }

  @override
  String get tackleBaits => 'Iscas';

  @override
  String get tackleGear => 'Equipamentos';

  @override
  String get tackleEditBait => 'Editar isca';

  @override
  String get tackleEditGear => 'Editar equipamento';

  @override
  String get tackleArchive => 'Arquivar';

  @override
  String get tackleRestore => 'Restaurar';

  @override
  String get tackleArchived => 'Arquivados';

  @override
  String get tackleArchivedNote =>
      'Continuam nas capturas antigas, mas saem das listas de escolha.';

  @override
  String get tackleEmptyBaits =>
      'Nenhuma isca ainda. Adicione as que você mais usa.';

  @override
  String get tackleEmptyGear =>
      'Nenhum equipamento ainda. Adicione varas, carretilhas e linhas.';

  @override
  String get settingsSectionTackle => 'Iscas e equipamentos';

  @override
  String settingsBaitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count iscas',
      one: '1 isca',
      zero: 'Nenhuma ainda',
    );
    return '$_temp0';
  }

  @override
  String settingsGearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
      zero: 'Nenhum ainda',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionData => 'Seus dados';

  @override
  String get settingsExport => 'Exportar dados';

  @override
  String get settingsExportHint =>
      'Arquivo JSON com pescarias, capturas e iscas. As fotos ficam no celular.';

  @override
  String get settingsExportFailed => 'Não deu para exportar. Tente de novo.';

  @override
  String get settingsWipe => 'Apagar todos os dados';

  @override
  String get settingsWipeHint =>
      'Pescarias, capturas, fotos e iscas. Não dá para desfazer.';

  @override
  String get wipeTitle => 'Apagar todos os dados?';

  @override
  String get wipeBody =>
      'Tudo o que você registrou sai deste celular: pescarias, capturas, fotos, iscas e ajustes. Exporte antes se quiser guardar uma cópia.';

  @override
  String get wipeConfirm => 'Apagar tudo';

  @override
  String get pastTripAction => 'Registrar pescaria passada';

  @override
  String get pastTripTitle => 'Pescaria passada';

  @override
  String get pastTripPhotos => 'Fotos da pescaria';

  @override
  String get pastTripPhotosHint =>
      'Cada foto vira uma captura. A data e o local das fotos sugerem os da pescaria.';

  @override
  String get pastTripAddPhoto => 'Adicionar foto';

  @override
  String get pastTripSuggested => 'Data e local sugeridos pelas fotos.';

  @override
  String get pastTripSave => 'Salvar pescaria';

  @override
  String get pastTripPhotoFailed => 'Não deu para ler esta foto. Tente outra.';

  @override
  String get placeSearchAction => 'Buscar local por nome';

  @override
  String get placeSearchHint => 'Represa, rio, cidade…';

  @override
  String get placeSearchEmpty => 'Nenhum lugar encontrado com esse nome.';

  @override
  String get placeSearchFailed => 'Sem conexão para buscar. Tente de novo.';

  @override
  String get placeSearchPointSaved => 'Ponto do local marcado';

  @override
  String get cardSectionTheme => 'Tema';

  @override
  String get cardThemeRedHead => 'Cabeça-vermelha';

  @override
  String get cardThemePaper => 'Papel';

  @override
  String get cardThemeTucunare => 'Tucunaré';

  @override
  String get cardThemeDawn => 'Amanhecer';

  @override
  String get cardThemeMoon => 'Lua';

  @override
  String get cardThemeRiver => 'Rio';

  @override
  String get cardFilterNone => 'Original';

  @override
  String get cardFilterDuotone => 'Duotom';

  @override
  String get cardFilterInk => 'Nanquim';

  @override
  String get cardFilterEngraving => 'Gravura';

  @override
  String get cardFilterScreenprint => 'Serigrafia';

  @override
  String get cardFilterHalftone => 'Retícula';

  @override
  String get cardFilterWorking => 'Aplicando o filtro';

  @override
  String get cardFilterFailed => 'Não deu para aplicar o filtro nesta foto.';

  @override
  String get unitKilometer => 'km';

  @override
  String get unitMile => 'mi';

  @override
  String get cardStyleMap => 'Mapa';

  @override
  String get cardShowMap => 'Mapa do local';

  @override
  String get cardMapPrivate => 'Pescarias privadas não mostram mapa.';

  @override
  String get cardMapPending => 'O mapa chega quando o celular estiver online.';

  @override
  String get cardMapEmpty => 'O OpenStreetMap não tem água mapeada por aqui.';

  @override
  String get cardMapNoPlace => 'Esta pescaria não tem local.';

  @override
  String get cardMapArea => 'O círculo marca a região, nunca o ponto exato.';

  @override
  String get mapAttribution => '© colaboradores do OpenStreetMap';

  @override
  String get settingsMapData => 'Dados de mapa';

  @override
  String get settingsMapDataCredit =>
      '© colaboradores do OpenStreetMap, disponível sob a Open Database License (ODbL).';
}
