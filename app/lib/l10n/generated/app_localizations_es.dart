// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Piscatio';

  @override
  String get navFish => 'Pescar';

  @override
  String get navLogbook => 'Diario';

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
  String get unitInch => 'pulg';

  @override
  String get unitMeter => 'm';

  @override
  String get unitFoot => 'pies';

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
  String get moonNew => 'Luna nueva';

  @override
  String get moonWaxingCrescent => 'Luna creciente';

  @override
  String get moonFirstQuarter => 'Cuarto creciente';

  @override
  String get moonWaxingGibbous => 'Gibosa creciente';

  @override
  String get moonFull => 'Luna llena';

  @override
  String get moonWaningGibbous => 'Gibosa menguante';

  @override
  String get moonLastQuarter => 'Cuarto menguante';

  @override
  String get moonWaningCrescent => 'Luna menguante';

  @override
  String get privacyPrivate => 'Solo yo';

  @override
  String get privacyFriends => 'Amigos';

  @override
  String get privacyApproximate => 'Zona aproximada';

  @override
  String get privacyExact => 'Lugar exacto';

  @override
  String get privacyPrivateDescription =>
      'Las tarjetas nunca muestran dónde pescaste.';

  @override
  String get privacyFriendsDescription =>
      'Por ahora funciona como “Solo yo”. Los amigos llegan en una próxima versión.';

  @override
  String get privacyApproximateDescription =>
      'Las tarjetas muestran solo la región, como la ciudad. El punto se desplaza algunos kilómetros.';

  @override
  String get privacyExactDescription =>
      'Las tarjetas muestran el nombre del lugar. Las coordenadas nunca aparecen.';

  @override
  String get unitsMetric => 'Métrico';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get unitsMetricExample => 'kg, cm, m, °C';

  @override
  String get unitsImperialExample => 'lb, pulg, pies, °F';

  @override
  String get baitTypeNatural => 'Carnada natural';

  @override
  String get baitTypeArtificial => 'Señuelo';

  @override
  String get baitTypeFly => 'Mosca';

  @override
  String get gearTypeCombo => 'Caña y reel';

  @override
  String get gearTypeRod => 'Caña';

  @override
  String get gearTypeReel => 'Reel';

  @override
  String get gearTypeLine => 'Línea';

  @override
  String get tackleTypeOther => 'Otro';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionBack => 'Volver';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String onboardingStepOf(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String get onboardingTagline =>
      'Cada jornada de pesca se vuelve una historia.';

  @override
  String get onboardingLanguageTitle => 'Idioma';

  @override
  String get onboardingUnitsTitle => '¿Cómo mides tus peces?';

  @override
  String get onboardingUnitsHint => 'Puedes cambiarlo después en Ajustes.';

  @override
  String get onboardingLocationTitle => '¿Dónde estás pescando?';

  @override
  String get onboardingLocationWhy =>
      'La ubicación guarda dónde fue cada jornada y permite consultar el clima de ese día.';

  @override
  String get onboardingLocationPrivacy =>
      'El lugar se queda en tu teléfono. Las tarjetas nunca muestran coordenadas y tú decides cuánto revelar.';

  @override
  String get onboardingLocationOffline =>
      'Funciona sin señal. El clima se consulta cuando vuelva la conexión.';

  @override
  String get onboardingLocationAllow => 'Permitir ubicación';

  @override
  String get onboardingLocationSkip => 'Ahora no';

  @override
  String get settingsSectionPreferences => 'Preferencias';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String settingsLanguageDevice(String language) {
    return 'Idioma del dispositivo: $language';
  }

  @override
  String get settingsUnits => 'Unidades';

  @override
  String settingsUnitsValue(String system, String examples) {
    return '$system ($examples)';
  }

  @override
  String get settingsDefaultPrivacy => 'Privacidad predeterminada del lugar';

  @override
  String get settingsLicenses => 'Licencias de código abierto';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get startTripAction => 'Iniciar jornada';

  @override
  String get resumeTripAction => 'Volver a la jornada';

  @override
  String get homeRecentTrips => 'Últimas jornadas';

  @override
  String get homeEmptyTitle => 'Tu primera jornada empieza aquí.';

  @override
  String get homeEmptyBody =>
      'Toca Iniciar jornada cuando llegues al agua. Cada captura lleva tres toques, incluso con las manos mojadas.';

  @override
  String get activeTripLabel => 'Jornada en curso';

  @override
  String activeTripElapsed(String duration) {
    return 'Pescando hace $duration';
  }

  @override
  String activeTripStartedAt(String time) {
    return 'Empezó a las $time';
  }

  @override
  String get activeTripNoLocation => 'Sin ubicación';

  @override
  String get activeTripLocationSaved => 'Ubicación guardada';

  @override
  String get activeTripEmpty =>
      'Aún no hay capturas. Toca + Captura en cuanto el pez salga del agua.';

  @override
  String get activeTripMinimize => 'Minimizar';

  @override
  String get addCatchAction => '+ Captura';

  @override
  String get finishTripAction => 'Finalizar';

  @override
  String get finishTripTitle => '¿Finalizar la jornada?';

  @override
  String get finishTripBody =>
      'El cronómetro se detiene ahora. Horarios y capturas se pueden editar después.';

  @override
  String get finishTripConfirm => 'Finalizar jornada';

  @override
  String catchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas',
      one: '1 captura',
      zero: 'Ninguna captura',
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
  String get catchReleased => 'Liberado';

  @override
  String get speciesUnknown => 'Especie no identificada';

  @override
  String rulerHour(int hours) {
    return '$hours h';
  }

  @override
  String rulerSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Regla del tiempo con $count capturas marcadas',
      one: 'Regla del tiempo con 1 captura marcada',
      zero: 'Regla del tiempo, aún sin capturas',
    );
    return '$_temp0';
  }

  @override
  String get quickCatchTitle => 'Nueva captura';

  @override
  String get quickCatchPhotoTitle => 'Primero la foto';

  @override
  String get quickCatchPhotoHint =>
      'Los datos de ubicación se quitan de la foto antes de guardarla.';

  @override
  String get quickCatchTakePhoto => 'Tomar foto';

  @override
  String get quickCatchGallery => 'Galería';

  @override
  String get quickCatchNoPhoto => 'Sin foto';

  @override
  String get quickCatchSpeciesTitle => '¿Qué pez es?';

  @override
  String get quickCatchChangeSpecies => 'Cambiar';

  @override
  String get quickCatchMoreDetails => 'Más detalles';

  @override
  String get quickCatchMoreDetailsHint =>
      'Peso, largo, carnada, equipo, profundidad';

  @override
  String get quickCatchSave => 'Guardar captura';

  @override
  String get catchSaved => 'Captura guardada';

  @override
  String get photoImportFailed =>
      'No se pudo usar esta foto. La captura se guardó sin ella.';

  @override
  String get speciesSearchHint => 'Buscar: tararira, traíra, bass…';

  @override
  String get speciesSearchClear => 'Borrar búsqueda';

  @override
  String get speciesMostUsed => 'Tus más pescadas';

  @override
  String get speciesAll => 'Todas las especies';

  @override
  String get speciesUnknownAction => 'No sé la especie';

  @override
  String speciesAlsoKnownAs(String name) {
    return 'También: $name';
  }

  @override
  String get speciesNoResults => 'Ninguna especie con ese nombre.';

  @override
  String speciesAddCustom(String name) {
    return 'Agregar “$name” como especie';
  }

  @override
  String get catchWeight => 'Peso';

  @override
  String get catchWeightOunces => 'Onzas';

  @override
  String get catchLength => 'Largo';

  @override
  String get catchDepth => 'Profundidad';

  @override
  String get catchReleasedQuestion => '¿Liberado?';

  @override
  String get catchReleasedYes => 'Lo liberé';

  @override
  String get catchReleasedNo => 'Me lo quedé';

  @override
  String get catchBait => 'Carnada';

  @override
  String get catchGear => 'Equipo';

  @override
  String get catchChooseBait => 'Elegir carnada';

  @override
  String get catchChooseGear => 'Elegir equipo';

  @override
  String get catchNone => 'Ninguno';

  @override
  String get catchNotes => 'Notas';

  @override
  String get tackleNewBait => 'Nueva carnada';

  @override
  String get tackleNewGear => 'Nuevo equipo';

  @override
  String get tackleName => 'Nombre';

  @override
  String get errorInvalidNumber => 'Escribe un número, como 2,5';

  @override
  String get historyEmpty =>
      'Las jornadas finalizadas aparecen aquí, mes a mes.';

  @override
  String get tripNotFound => 'Esta jornada ya no existe.';

  @override
  String get catchNotFound => 'Esta captura ya no existe.';

  @override
  String get tripNoCatches => 'Ninguna captura en esta jornada.';

  @override
  String get tripAddCatch => 'Agregar captura';

  @override
  String tripTimeRange(String start, String end) {
    return 'De $start a $end';
  }

  @override
  String get tripStatDuration => 'pescando';

  @override
  String speciesCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'especies',
      one: 'especie',
    );
    return '$_temp0';
  }

  @override
  String tripBiggestCatch(String species, String measure) {
    return 'La más grande: $species, $measure';
  }

  @override
  String get deleteTripTitle => 'Eliminar jornada';

  @override
  String get deleteTripBody =>
      'Sus capturas y fotos también se eliminarán. No se puede deshacer.';

  @override
  String get deleteCatchTitle => 'Eliminar captura';

  @override
  String get deleteCatchBody => 'La captura y su foto se eliminarán.';

  @override
  String get editTripTitle => 'Editar jornada';

  @override
  String get editTripDate => 'Fecha';

  @override
  String get editTripStart => 'Inicio';

  @override
  String get editTripEnd => 'Fin';

  @override
  String get editTripEndBeforeStart => 'El fin debe ser después del inicio.';

  @override
  String get editTripPlace => 'Nombre del lugar';

  @override
  String get editTripPlaceHelp =>
      'Aparece en las tarjetas solo con “Lugar exacto”.';

  @override
  String get editTripRegion => 'Región';

  @override
  String get editTripRegionHelp =>
      'Ciudad o provincia, como Corrientes. Aparece con “Zona aproximada”.';

  @override
  String get editTripPrivacy => 'Privacidad del lugar';

  @override
  String get catchPhoto => 'Foto';

  @override
  String get catchAddPhoto => 'Agregar foto';

  @override
  String get catchReplacePhoto => 'Cambiar';

  @override
  String get catchRemovePhoto => 'Quitar';

  @override
  String get catchTime => 'Hora de la captura';

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String get weatherPending =>
      'El clima de esta jornada estará listo 2 a 3 días después.';

  @override
  String get weatherUnavailable =>
      'Sin clima para esta jornada (sin ubicación o sin datos).';

  @override
  String get weatherTemperature => 'Temperatura';

  @override
  String get weatherPressure => 'Presión';

  @override
  String get weatherPressureFalling => 'Presión bajando';

  @override
  String get weatherPressureRising => 'Presión subiendo';

  @override
  String get weatherPressureSteady => 'Presión estable';

  @override
  String get weatherWind => 'Viento';

  @override
  String get weatherRain => 'Lluvia';

  @override
  String get weatherSource => 'Clima: NASA POWER';

  @override
  String get compassN => 'N';

  @override
  String get compassNE => 'NE';

  @override
  String get compassE => 'E';

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
  String get settingsWeatherData => 'Datos del clima';

  @override
  String get settingsWeatherDataCredit =>
      'Pescas pasadas: Proyecto NASA POWER, NASA Langley Research Center. Tiempo ahora: MET Norway. Ambos CC BY 4.0.';

  @override
  String get brandName => 'Piscatio';

  @override
  String cardBiggestValue(String species, String measure) {
    return '$species, $measure';
  }

  @override
  String cardCatchNumber(String number) {
    return 'N.º $number';
  }

  @override
  String get cardFieldSpecies => 'Especie';

  @override
  String get cardFieldCommonName => 'Nombre común';

  @override
  String get cardFieldPlace => 'Localidad';

  @override
  String get cardFieldDate => 'Fecha';

  @override
  String get cardFieldTime => 'Hora';

  @override
  String get cardFieldLength => 'Longitud';

  @override
  String get cardFieldWeight => 'Peso';

  @override
  String get cardFieldBait => 'Carnada';

  @override
  String get cardFieldWind => 'Viento';

  @override
  String get cardFieldAir => 'Aire';

  @override
  String get cardFieldPressure => 'Presión';

  @override
  String get cardFieldMoon => 'Luna';

  @override
  String get cardFieldDuration => 'Duración';

  @override
  String get cardFieldBiggest => 'Mayor';

  @override
  String get cardFieldReleased => 'Liberado';

  @override
  String get cardFieldKept => 'Conservado';

  @override
  String get cardFieldFate => 'Destino';

  @override
  String get cardFieldLog => 'Registro de campo';

  @override
  String cardPreviousRecord(String measure) {
    return 'récord anterior $measure';
  }

  @override
  String cardRecordImprovement(String improvement) {
    return 'Récord personal, $improvement';
  }

  @override
  String get cardRecord => 'Récord personal';

  @override
  String get cardFirstOfSpecies => 'Primera de la especie';

  @override
  String cardRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count récords personales',
      one: '1 récord personal',
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
      other: 'y $count más',
      one: 'y 1 más',
    );
    return '$_temp0';
  }

  @override
  String get cardCreate => 'Crear tarjeta';

  @override
  String get cardStyleBoard => 'Regla';

  @override
  String get cardStyleChart => 'Carta';

  @override
  String get cardStyleTag => 'Etiqueta';

  @override
  String get cardFormatStory => 'Historia';

  @override
  String get cardFormatSquare => 'Cuadrado';

  @override
  String get cardShowPlace => 'Mostrar lugar';

  @override
  String get cardPlacePrivate =>
      'Esta salida es privada: la tarjeta no muestra dónde fue.';

  @override
  String get cardPlaceRegion => 'Muestra solo la región, nunca el punto.';

  @override
  String get cardPlaceUnknown =>
      'No hay nombre de lugar guardado en esta salida.';

  @override
  String get cardShare => 'Compartir';

  @override
  String get cardShareFailed =>
      'No se pudo crear la imagen. Inténtalo de nuevo.';

  @override
  String cardPreviewLabel(String style, String format) {
    return 'Vista previa de la tarjeta: $style, $format';
  }

  @override
  String get actionClose => 'Cerrar';

  @override
  String get summaryTitle => 'Salida terminada';

  @override
  String get summaryRecords => 'Récords';

  @override
  String summaryTopBait(String bait) {
    return 'Carnada con más capturas: $bait';
  }

  @override
  String summaryRecordLine(String species, String measure) {
    return '$species, $measure';
  }

  @override
  String get bootStepDatabase => 'Abriendo tu diario…';

  @override
  String get bootStepCatalog => 'Cargando las especies…';

  @override
  String get bootSlow => 'Está tardando más de lo normal.';

  @override
  String get bootFailedTitle => 'La app no pudo abrir';

  @override
  String get bootFailedBody =>
      'Haz una captura de esta pantalla y envíanosla. Tus datos siguen en el teléfono.';

  @override
  String get bootRetry => 'Intentar de nuevo';

  @override
  String get bootCopyDetails => 'Copiar detalles';

  @override
  String get brandTagline => 'Diario de pesca';

  @override
  String get cardSectionStyle => 'Estilo';

  @override
  String get cardSectionPhoto => 'Foto';

  @override
  String get cardSectionDetails => 'Detalles';

  @override
  String get cardSectionCaption => 'Leyenda';

  @override
  String get cardNoPhoto => 'Sin foto';

  @override
  String get cardNoPhotos => 'No hay fotos para la tarjeta.';

  @override
  String cardPhotoOption(String number) {
    return 'Foto $number';
  }

  @override
  String get cardShowWeather => 'Clima y luna';

  @override
  String get cardShowBait => 'Carnada';

  @override
  String get cardCaptionHint => 'Escribe una leyenda (opcional)';

  @override
  String get cardFieldNotes => 'Notas';

  @override
  String get navStats => 'Números';

  @override
  String get statsTitle => 'Tus números';

  @override
  String get statsEmpty => 'Tus números aparecen después de tu primera salida.';

  @override
  String statsTripsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'salidas',
      one: 'salida',
    );
    return '$_temp0';
  }

  @override
  String statsReleased(String percent) {
    return '$percent liberados';
  }

  @override
  String statsPerHour(String rate) {
    return '$rate por hora de pesca';
  }

  @override
  String get statsByHourTitle => 'Capturas por hora del día';

  @override
  String statsPeakHour(String start, String end) {
    return 'Más capturas entre $start y $end';
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
  String get statsSpeciesTitle => 'Especies más pescadas';

  @override
  String get statsBaitsTitle => 'Carnadas que más pescan';

  @override
  String get statsRecordsTitle => 'Récords personales';

  @override
  String get statsBestTrip => 'Mejor salida';

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
  String get tackleBaits => 'Carnadas';

  @override
  String get tackleGear => 'Equipos';

  @override
  String get tackleEditBait => 'Editar carnada';

  @override
  String get tackleEditGear => 'Editar equipo';

  @override
  String get tackleArchive => 'Archivar';

  @override
  String get tackleRestore => 'Restaurar';

  @override
  String get tackleArchived => 'Archivados';

  @override
  String get tackleArchivedNote =>
      'Siguen en las capturas antiguas, pero salen de las listas.';

  @override
  String get tackleEmptyBaits =>
      'Aún no hay carnadas. Agrega las que más usas.';

  @override
  String get tackleEmptyGear =>
      'Aún no hay equipos. Agrega cañas, carretes y líneas.';

  @override
  String get settingsSectionTackle => 'Carnadas y equipos';

  @override
  String settingsBaitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carnadas',
      one: '1 carnada',
      zero: 'Ninguna aún',
    );
    return '$_temp0';
  }

  @override
  String settingsGearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos',
      one: '1 equipo',
      zero: 'Ninguno aún',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionData => 'Tus datos';

  @override
  String get settingsExport => 'Exportar datos';

  @override
  String get settingsExportHint =>
      'Archivo JSON con salidas, capturas y carnadas. Las fotos quedan en el teléfono.';

  @override
  String get settingsExportFailed => 'No se pudo exportar. Inténtalo de nuevo.';

  @override
  String get settingsWipe => 'Borrar todos los datos';

  @override
  String get settingsWipeHint =>
      'Salidas, capturas, fotos y carnadas. No se puede deshacer.';

  @override
  String get wipeTitle => '¿Borrar todos los datos?';

  @override
  String get wipeBody =>
      'Todo lo que registraste sale de este teléfono: salidas, capturas, fotos, carnadas y ajustes. Exporta antes si quieres guardar una copia.';

  @override
  String get wipeConfirm => 'Borrar todo';

  @override
  String get pastTripAction => 'Registrar salida pasada';

  @override
  String get pastTripTitle => 'Salida pasada';

  @override
  String get pastTripPhotos => 'Fotos de la salida';

  @override
  String get pastTripPhotosHint =>
      'Cada foto se vuelve una captura. Su fecha y lugar sugieren los de la salida.';

  @override
  String get pastTripAddPhoto => 'Agregar foto';

  @override
  String get pastTripSuggested => 'Fecha y lugar sugeridos por las fotos.';

  @override
  String get pastTripSave => 'Guardar salida';

  @override
  String get pastTripPhotoFailed =>
      'No se pudo leer esta foto. Prueba con otra.';

  @override
  String get placeSearchAction => 'Buscar lugar por nombre';

  @override
  String get placeSearchHint => 'Represa, río, ciudad…';

  @override
  String get placeSearchEmpty => 'No se encontró ningún lugar con ese nombre.';

  @override
  String get placeSearchFailed =>
      'Sin conexión para buscar. Inténtalo de nuevo.';

  @override
  String get placeSearchPointSaved => 'Punto del lugar marcado';

  @override
  String get cardSectionTheme => 'Tema';

  @override
  String get cardThemeRedHead => 'Cabeza roja';

  @override
  String get cardThemePaper => 'Papel';

  @override
  String get cardThemeTucunare => 'Tucunaré';

  @override
  String get cardThemeDawn => 'Amanecer';

  @override
  String get cardThemeMoon => 'Luna';

  @override
  String get cardThemeRiver => 'Río';

  @override
  String get cardFilterNone => 'Original';

  @override
  String get cardFilterDuotone => 'Duotono';

  @override
  String get cardFilterInk => 'Tinta china';

  @override
  String get cardFilterEngraving => 'Grabado';

  @override
  String get cardFilterScreenprint => 'Serigrafía';

  @override
  String get cardFilterHalftone => 'Trama';

  @override
  String get cardFilterWorking => 'Aplicando el filtro';

  @override
  String get cardFilterFailed => 'No se pudo aplicar el filtro a esta foto.';

  @override
  String get unitKilometer => 'km';

  @override
  String get unitMile => 'mi';

  @override
  String get cardStyleMap => 'Mapa';

  @override
  String get cardShowMap => 'Mapa del lugar';

  @override
  String get cardMapPrivate => 'Las salidas privadas no muestran mapa.';

  @override
  String get cardMapPending =>
      'El mapa llega cuando el teléfono tenga conexión.';

  @override
  String get cardMapEmpty => 'OpenStreetMap no tiene agua mapeada por aquí.';

  @override
  String get cardMapNoPlace => 'Esta salida no tiene lugar.';

  @override
  String get cardMapArea => 'El círculo marca la zona, nunca el punto exacto.';

  @override
  String get mapAttribution => '© colaboradores de OpenStreetMap';

  @override
  String get settingsMapData => 'Datos de mapa';

  @override
  String get settingsMapDataCredit =>
      '© colaboradores de OpenStreetMap, disponible bajo la Open Database License (ODbL).';

  @override
  String get cardStyleCover => 'Portada';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsSignInHint => 'Guarda tu diario y úsalo en otro teléfono';

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get accountIntro =>
      'Inicia sesión para guardar tu diario y tus fotos en el servidor y verlos en tus otros teléfonos. Sin cuenta, todo sigue funcionando en este teléfono.';

  @override
  String get accountEmail => 'Correo electrónico';

  @override
  String get accountSendCode => 'Enviar código';

  @override
  String accountCodeSent(String email) {
    return 'Enviamos un código de 6 dígitos a $email. Vale por 10 minutos.';
  }

  @override
  String get accountCode => 'Código';

  @override
  String get accountSignIn => 'Iniciar sesión';

  @override
  String get accountChangeEmail => 'Usar otro correo';

  @override
  String get accountResendCode => 'Enviar otro código';

  @override
  String get accountServer => 'Servidor';

  @override
  String get accountServerHint =>
      'Cámbialo solo si tienes tu propio servidor Piscatio.';

  @override
  String get accountServerInvalid =>
      'Escribe una dirección que empiece con https://';

  @override
  String get accountErrorCodeWrong =>
      'Código incorrecto. Revisa el correo y vuelve a intentarlo.';

  @override
  String get accountErrorCodeExpired => 'Este código venció. Pide otro.';

  @override
  String get accountErrorEmailInvalid => 'Revisa la dirección de correo.';

  @override
  String get accountErrorTooMany => 'Demasiados intentos. Espera unos minutos.';

  @override
  String get accountErrorOffline =>
      'No se pudo conectar con el servidor. Revisa la conexión y vuelve a intentarlo.';

  @override
  String accountSyncedToday(String time) {
    return 'Sincronizado hoy a las $time';
  }

  @override
  String accountSyncedOn(String date, String time) {
    return 'Sincronizado el $date a las $time';
  }

  @override
  String get accountNeverSynced => 'Aún sin sincronizar';

  @override
  String get accountSyncSoon => 'Sincronizando ahora';

  @override
  String get accountSyncRetrying =>
      'Sin conexión con el servidor. Lo intentará de nuevo solo.';

  @override
  String get accountSyncNow => 'Sincronizar ahora';

  @override
  String get accountPrivacyNote =>
      'El servidor guarda el lugar exacto para que tus teléfonos lo muestren. Nadie más lo ve: las tarjetas siguen la privacidad de cada pesca.';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountSignOutHint => 'Tu diario sigue en este teléfono.';

  @override
  String get accountDelete => 'Eliminar cuenta';

  @override
  String get accountDeleteHint => 'Borra la cuenta y la copia en el servidor.';

  @override
  String get accountDeleteTitle => '¿Eliminar tu cuenta?';

  @override
  String get accountDeleteBody =>
      'El servidor borra la cuenta, las pescas y las fotos. El diario en este teléfono y en los otros se queda. No se puede deshacer.';

  @override
  String get accountDeleted => 'Cuenta eliminada';

  @override
  String get wipeSignedInNote =>
      'Se cerrará tu sesión. La copia en el servidor se queda: para borrarla, elimina la cuenta.';

  @override
  String get liveWeatherTitle => 'Tiempo ahora';

  @override
  String get liveWeatherSource => 'Datos: MET Norway';

  @override
  String get liveWeatherRainNextHour => 'Lluvia en la próxima hora';
}
