// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Generador QR y NFC';

  @override
  String get screenSplashSubtitle => 'Crea y personaliza tu propio código QR';

  @override
  String get tileAppAndroid => 'Abrir App';

  @override
  String get tileAppIos => 'Atajo';

  @override
  String get tileClipboard => 'Portapapeles';

  @override
  String get tileWebsite => 'Sitio Web';

  @override
  String get tileContact => 'Contacto';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => 'Ubicación';

  @override
  String get tileEvent => 'Evento';

  @override
  String get tileEmail => 'Email';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'Generador QR y NFC';

  @override
  String get screenHomeEditModeTitle => 'Modo Edición';

  @override
  String get actionDone => 'Listo';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionConfirm => 'Aceptar';

  @override
  String get tooltipHelp => 'Guía de uso';

  @override
  String get tooltipHistory => 'Historial';

  @override
  String get tooltipDeleteAll => 'Eliminar todo';

  @override
  String get actionCollapseHidden => 'Ocultar menú';

  @override
  String actionShowHidden(int count) {
    return 'Ver menú oculto ($count)';
  }

  @override
  String get screenHelpTitle => 'Guía de uso';

  @override
  String get screenHistoryTitle => 'Historial';

  @override
  String get screenHistoryEmpty => 'No hay historial.';

  @override
  String get labelQrCode => 'Código QR';

  @override
  String get labelNfcTag => 'Etiqueta NFC';

  @override
  String get dialogClearAllTitle => 'Eliminar todo';

  @override
  String get dialogClearAllContent => '¿Desea eliminar todo el historial?';

  @override
  String get dialogDeleteHistoryTitle => 'Eliminar historial';

  @override
  String dialogDeleteHistoryContent(String name) {
    return '¿Desea eliminar el historial de \"$name\"?';
  }

  @override
  String get screenWebsiteTitle => 'Etiqueta de Sitio Web';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'Por favor, ingrese una URL.';

  @override
  String get msgUrlInvalid => 'Por favor, ingrese una URL válida.';

  @override
  String get screenWifiTitle => 'Etiqueta WiFi';

  @override
  String get labelWifiSsid => 'Nombre de red (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'Por favor, ingrese el SSID.';

  @override
  String get labelWifiSecurity => 'Seguridad';

  @override
  String get optionWpa2 => 'WPA2 (Recomendado)';

  @override
  String get optionNoSecurity => 'Ninguna';

  @override
  String get labelWifiPassword => 'Contraseña';

  @override
  String get hintWifiPassword => 'Contraseña';

  @override
  String get screenSmsTitle => 'Etiqueta SMS';

  @override
  String get labelPhoneRequired => 'Número de teléfono *';

  @override
  String get hintPhone => '600-000-000';

  @override
  String get msgPhoneRequired => 'Por favor, ingrese un número de teléfono.';

  @override
  String get labelMessageOptional => 'Mensaje (Opcional)';

  @override
  String get hintSmsMessage => 'Contenido del mensaje';

  @override
  String get screenEmailTitle => 'Etiqueta de Email';

  @override
  String get labelEmailRequired => 'Dirección de email *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => 'Por favor, ingrese una dirección de email.';

  @override
  String get msgEmailInvalid => 'Por favor, ingrese un email válido.';

  @override
  String get labelEmailSubjectOptional => 'Asunto (Opcional)';

  @override
  String get hintEmailSubject => 'Asunto del email';

  @override
  String get labelEmailBodyOptional => 'Cuerpo (Opcional)';

  @override
  String get hintEmailBody => 'Cuerpo del email';

  @override
  String get screenContactTitle => 'Etiqueta de Contacto';

  @override
  String get actionManualInput => 'Entrada manual';

  @override
  String get screenContactManualSubtitle =>
      'Ingrese nombre, teléfono y email manualmente';

  @override
  String get hintSearchByName => 'Buscar por nombre';

  @override
  String get labelNoPhone => 'Sin número de teléfono';

  @override
  String get msgContactPermissionRequired =>
      'Se requiere permiso de acceso a contactos';

  @override
  String get msgContactPermissionHint =>
      'Use la entrada manual o permita el acceso en ajustes.';

  @override
  String get actionOpenSettings => 'Abrir Ajustes';

  @override
  String get msgSearchNoResults => 'Sin resultados de búsqueda.';

  @override
  String get msgNoContacts => 'No hay contactos guardados.';

  @override
  String get screenContactManualTitle => 'Entrada manual';

  @override
  String get labelNameRequired => 'Nombre *';

  @override
  String get hintName => 'Juan Pérez';

  @override
  String get msgNameRequired => 'Por favor, ingrese un nombre.';

  @override
  String get labelPhone => 'Teléfono';

  @override
  String get labelEmail => 'Email';

  @override
  String get screenLocationTitle => 'Etiqueta de Ubicación';

  @override
  String get screenLocationTapHint =>
      'Toque el mapa para seleccionar una ubicación.';

  @override
  String get msgSearchingAddress => 'Buscando dirección...';

  @override
  String get msgAddressUnavailable => 'No se pudo obtener la dirección.';

  @override
  String get labelPlaceNameOptional => 'Nombre del lugar (Opcional)';

  @override
  String get hintPlaceName =>
      'Dejar vacío para usar el nombre del edificio automáticamente.';

  @override
  String get msgSelectLocation =>
      'Por favor, seleccione una ubicación en el mapa.';

  @override
  String get screenEventTitle => 'Etiqueta de Evento';

  @override
  String get labelEventTitleRequired => 'Título del evento *';

  @override
  String get hintEventTitle => 'Título del evento';

  @override
  String get msgEventTitleRequired => 'Por favor, ingrese un título.';

  @override
  String get labelEventStart => 'Inicio';

  @override
  String get labelEventEnd => 'Fin';

  @override
  String get labelEventLocationOptional => 'Lugar/Dirección (Opcional)';

  @override
  String get hintEventLocation => 'Calle Mayor 1...';

  @override
  String get labelEventDescOptional => 'Descripción (Opcional)';

  @override
  String get hintEventDesc => 'Descripción del evento';

  @override
  String get msgEventEndBeforeStart =>
      'La hora de fin debe ser posterior a la de inicio.';

  @override
  String get screenClipboardTitle => 'Etiqueta de Portapapeles';

  @override
  String get msgClipboardEmpty =>
      'El portapapeles está vacío. Ingrese texto manualmente.';

  @override
  String get labelContent => 'Contenido';

  @override
  String get hintClipboardText => 'Texto para guardar en la etiqueta';

  @override
  String get msgContentRequired => 'Por favor, ingrese el contenido.';

  @override
  String get screenIosInputTitle => 'Configuración de App iOS';

  @override
  String get labelShortcutName => 'Nombre del atajo de la app a ejecutar';

  @override
  String get hintShortcutName => 'Ej: MiApp';

  @override
  String get msgAppNameRequired => 'Por favor, ingrese el nombre de la app.';

  @override
  String get screenIosInputGuideTitle => 'Guía de configuración de atajos';

  @override
  String get screenIosInputGuideSteps =>
      '1. Abra la app Atajos (Shortcuts) en su iPhone\n2. Cree un atajo que abra la app deseada\n3. Guarde el atajo con el nombre ingresado arriba\n4. Pulse el botón de abajo para generar QR/NFC';

  @override
  String get actionAppleShortcutsGuide => 'Guía oficial de Atajos de Apple';

  @override
  String get screenAppPickerTitle => 'Seleccionar App';

  @override
  String get hintAppSearch => 'Buscar apps...';

  @override
  String get msgAppListError => 'No se pudo cargar la lista de apps.';

  @override
  String get msgSelectApp => 'Por favor, seleccione una app.';

  @override
  String get screenNfcWriterTitle => 'Escritura NFC';

  @override
  String get msgNfcWaiting =>
      'Acerque la etiqueta NFC a la\nparte trasera del teléfono';

  @override
  String get msgNfcSuccess => '¡Escritura completada!\nVolviendo al inicio...';

  @override
  String get msgNfcError => 'La escritura NFC falló.';

  @override
  String get labelNfcIncludeIos => 'Incluir atajo de iOS';

  @override
  String get labelIosShortcutName => 'Nombre del atajo iOS';

  @override
  String get hintIosShortcutName => 'Ej: WhatsApp';

  @override
  String get screenOutputSelectorTitle => 'Seleccionar método de salida';

  @override
  String get screenOutputQrDesc => 'Escanear con cámara para abrir app';

  @override
  String get screenOutputNfcDesc => 'Acercar etiqueta para abrir app';

  @override
  String get msgNfcCheckFailed => 'Verificación NFC fallida';

  @override
  String get msgNfcSimulator => 'No se puede probar NFC en el simulador';

  @override
  String get msgNfcNotSupported => 'Este dispositivo no soporta NFC';

  @override
  String get msgNfcWriteIosMin =>
      'La escritura NFC requiere iPhone XS o posterior';

  @override
  String get msgNfcUnsupportedDevice => 'Dispositivo sin soporte NFC';

  @override
  String get actionNfcWrite => 'Escribir etiqueta NFC';

  @override
  String get screenQrResultTitle => 'Código QR';

  @override
  String get tabTemplate => 'Plantilla';

  @override
  String get tabShape => 'Forma';

  @override
  String get tabColor => 'Color';

  @override
  String get tabLogo => 'Logo';

  @override
  String get tabText => 'Texto';

  @override
  String get actionSaveGallery => 'Guardar en Galería';

  @override
  String get actionSaveTemplate => 'Guardar Plantilla';

  @override
  String get dialogLowReadabilityTitle => 'Legibilidad baja';

  @override
  String dialogLowReadabilityScore(int score) {
    return 'Legibilidad actual: $score%';
  }

  @override
  String get dialogLowReadabilityWarning =>
      'El código QR podría no ser reconocido\npor algunos escáneres.';

  @override
  String dialogLowReadabilityCause(String issue) {
    return 'Causa principal: $issue';
  }

  @override
  String get actionSaveAnyway => 'Guardar de todos modos';

  @override
  String get dialogSaveTemplateTitle => 'Guardar Plantilla';

  @override
  String get labelTemplateName => 'Nombre de la plantilla';

  @override
  String get hintTemplateName => 'Ej: QR fondo azul';

  @override
  String msgTemplateSaved(String name) {
    return 'Plantilla \"$name\" guardada.';
  }

  @override
  String get msgSaveFailed => 'Error al guardar la imagen.';

  @override
  String get msgPrintFailed =>
      'Error de impresión. Verifique la conexión de la impresora.';

  @override
  String get labelReadability => 'Legibilidad';

  @override
  String get screenTemplateMyTemplates => 'Mis Plantillas';

  @override
  String get actionNoStyle => 'Sin estilo';

  @override
  String msgTemplateApplied(String name) {
    return 'Plantilla \"$name\" aplicada.';
  }

  @override
  String get dialogDeleteTemplateTitle => 'Eliminar Plantilla';

  @override
  String dialogDeleteTemplateContent(String name) {
    return '¿Desea eliminar \"$name\"?';
  }

  @override
  String get msgNoSavedTemplates => 'No hay plantillas guardadas.';

  @override
  String get msgNoSavedTemplatesHint =>
      'Guarde el estilo actual con el botón [Guardar Plantilla] de abajo.';

  @override
  String get tabColorSolid => 'Sólido';

  @override
  String get tabColorGradient => 'Degradado';

  @override
  String get actionPickColor => 'Elegir color';

  @override
  String get labelRecommendedColors => 'Colores recomendados';

  @override
  String get labelGradientPresets => 'Presets de degradado';

  @override
  String get dialogColorPickerTitle => 'Elegir color';

  @override
  String get labelDotShape => 'Forma del punto';

  @override
  String get labelEyeOuter => 'Forma del ojo — Exterior';

  @override
  String get labelEyeInner => 'Forma del ojo — Interior';

  @override
  String get shapeSquare => 'Cuadrado';

  @override
  String get shapeRounded => 'Redondeado';

  @override
  String get shapeCircle => 'Círculo';

  @override
  String get shapeCircleRound => 'Círculo dona';

  @override
  String get shapeSmooth => 'Suave';

  @override
  String get shapeDiamond => 'Diamante';

  @override
  String get shapeStar => 'Estrella';

  @override
  String get actionRandomRegenerate => 'Regenerar aleatorio';

  @override
  String get actionRandomEye => 'Ojo aleatorio';

  @override
  String get actionClear => 'Limpiar';

  @override
  String get labelShowIcon => 'Mostrar icono';

  @override
  String get msgIconUnavailable =>
      'Solo se muestra cuando hay un icono de app o emoji configurado.';

  @override
  String get labelLogoPosition => 'Posición del logo';

  @override
  String get optionCenter => 'Centro';

  @override
  String get optionBottomRight => 'Inferior derecha';

  @override
  String get labelLogoBackground => 'Fondo del logo';

  @override
  String get optionNone => 'Ninguno';

  @override
  String get optionSquare => 'Cuadrado';

  @override
  String get optionCircle => 'Círculo';

  @override
  String get labelTopText => 'Texto superior';

  @override
  String get labelBottomText => 'Texto inferior';

  @override
  String get hintEnterText => 'Ingrese texto';

  @override
  String get screenSettingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Predeterminado del sistema';

  @override
  String msgCopiedToClipboard(String text) {
    return '\"$text\" copiado al portapapeles';
  }

  @override
  String get settingsReadabilityAlert => 'Alerta de legibilidad';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';
}
