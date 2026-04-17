// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'QR- & NFC-Generator';

  @override
  String get screenSplashSubtitle =>
      'Erstellen und gestalten Sie Ihren eigenen QR-Code';

  @override
  String get tileAppAndroid => 'App starten';

  @override
  String get tileAppIos => 'Kurzbefehl';

  @override
  String get tileClipboard => 'Zwischenablage';

  @override
  String get tileWebsite => 'Webseite';

  @override
  String get tileContact => 'Kontakt';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => 'Standort';

  @override
  String get tileEvent => 'Termin';

  @override
  String get tileEmail => 'E-Mail';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'QR- & NFC-Generator';

  @override
  String get screenHomeEditModeTitle => 'Bearbeitungsmodus';

  @override
  String get actionDone => 'Fertig';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionShare => 'Teilen';

  @override
  String get actionRetry => 'Wiederholen';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionConfirm => 'OK';

  @override
  String get tooltipHelp => 'Hilfe';

  @override
  String get tooltipHistory => 'Verlauf';

  @override
  String get tooltipDeleteAll => 'Alle löschen';

  @override
  String get actionCollapseHidden => 'Verstecktes Menü einklappen';

  @override
  String actionShowHidden(int count) {
    return 'Verstecktes Menü anzeigen ($count)';
  }

  @override
  String get screenHelpTitle => 'Hilfe';

  @override
  String get screenHistoryTitle => 'Verlauf';

  @override
  String get screenHistoryEmpty => 'Kein Verlauf vorhanden.';

  @override
  String get labelQrCode => 'QR-Code';

  @override
  String get labelNfcTag => 'NFC-Tag';

  @override
  String get dialogClearAllTitle => 'Alle löschen';

  @override
  String get dialogClearAllContent =>
      'Möchten Sie den gesamten Verlauf löschen?';

  @override
  String get dialogDeleteHistoryTitle => 'Verlauf löschen';

  @override
  String dialogDeleteHistoryContent(String name) {
    return 'Möchten Sie den Verlauf von \'$name\' löschen?';
  }

  @override
  String get screenWebsiteTitle => 'Webseiten-Tag';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'Bitte geben Sie eine URL ein.';

  @override
  String get msgUrlInvalid => 'Bitte geben Sie eine gültige URL ein.';

  @override
  String get screenWifiTitle => 'WiFi-Tag';

  @override
  String get labelWifiSsid => 'Netzwerkname (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'Bitte geben Sie die SSID ein.';

  @override
  String get labelWifiSecurity => 'Sicherheit';

  @override
  String get optionWpa2 => 'WPA2 (Empfohlen)';

  @override
  String get optionNoSecurity => 'Keine';

  @override
  String get labelWifiPassword => 'Passwort';

  @override
  String get hintWifiPassword => 'Passwort';

  @override
  String get screenSmsTitle => 'SMS-Tag';

  @override
  String get labelPhoneRequired => 'Telefonnummer *';

  @override
  String get hintPhone => '0170-0000000';

  @override
  String get msgPhoneRequired => 'Bitte geben Sie eine Telefonnummer ein.';

  @override
  String get labelMessageOptional => 'Nachricht (Optional)';

  @override
  String get hintSmsMessage => 'Nachrichteninhalt';

  @override
  String get screenEmailTitle => 'E-Mail-Tag';

  @override
  String get labelEmailRequired => 'E-Mail-Adresse *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => 'Bitte geben Sie eine E-Mail-Adresse ein.';

  @override
  String get msgEmailInvalid =>
      'Bitte geben Sie eine gültige E-Mail-Adresse ein.';

  @override
  String get labelEmailSubjectOptional => 'Betreff (Optional)';

  @override
  String get hintEmailSubject => 'E-Mail-Betreff';

  @override
  String get labelEmailBodyOptional => 'Inhalt (Optional)';

  @override
  String get hintEmailBody => 'E-Mail-Inhalt';

  @override
  String get screenContactTitle => 'Kontakt-Tag';

  @override
  String get actionManualInput => 'Manuelle Eingabe';

  @override
  String get screenContactManualSubtitle =>
      'Name, Telefonnummer und E-Mail manuell eingeben';

  @override
  String get hintSearchByName => 'Nach Name suchen';

  @override
  String get labelNoPhone => 'Keine Telefonnummer';

  @override
  String get msgContactPermissionRequired =>
      'Zugriff auf Kontakte erforderlich';

  @override
  String get msgContactPermissionHint =>
      'Verwenden Sie die manuelle Eingabe oder erlauben Sie den Zugriff in den Einstellungen.';

  @override
  String get actionOpenSettings => 'Einstellungen öffnen';

  @override
  String get msgSearchNoResults => 'Keine Suchergebnisse.';

  @override
  String get msgNoContacts => 'Keine gespeicherten Kontakte.';

  @override
  String get screenContactManualTitle => 'Manuelle Eingabe';

  @override
  String get labelNameRequired => 'Name *';

  @override
  String get hintName => 'Max Mustermann';

  @override
  String get msgNameRequired => 'Bitte geben Sie einen Namen ein.';

  @override
  String get labelPhone => 'Telefon';

  @override
  String get labelEmail => 'E-Mail';

  @override
  String get screenLocationTitle => 'Standort-Tag';

  @override
  String get screenLocationTapHint =>
      'Tippen Sie auf die Karte, um einen Standort auszuwählen.';

  @override
  String get msgSearchingAddress => 'Adresse wird gesucht...';

  @override
  String get msgAddressUnavailable => 'Adresse konnte nicht abgerufen werden.';

  @override
  String get labelPlaceNameOptional => 'Ortsname (Optional)';

  @override
  String get hintPlaceName =>
      'Leer lassen, um den Gebäudenamen automatisch zu verwenden.';

  @override
  String get msgSelectLocation =>
      'Bitte wählen Sie einen Standort auf der Karte.';

  @override
  String get screenEventTitle => 'Termin-Tag';

  @override
  String get labelEventTitleRequired => 'Veranstaltungstitel *';

  @override
  String get hintEventTitle => 'Veranstaltungstitel';

  @override
  String get msgEventTitleRequired => 'Bitte geben Sie einen Titel ein.';

  @override
  String get labelEventStart => 'Beginn';

  @override
  String get labelEventEnd => 'Ende';

  @override
  String get labelEventLocationOptional => 'Ort/Adresse (Optional)';

  @override
  String get hintEventLocation => 'Berliner Str. 1...';

  @override
  String get labelEventDescOptional => 'Beschreibung (Optional)';

  @override
  String get hintEventDesc => 'Veranstaltungsbeschreibung';

  @override
  String get msgEventEndBeforeStart =>
      'Die Endzeit muss nach der Startzeit liegen.';

  @override
  String get screenClipboardTitle => 'Zwischenablage-Tag';

  @override
  String get msgClipboardEmpty =>
      'Zwischenablage ist leer. Geben Sie Text manuell ein.';

  @override
  String get labelContent => 'Inhalt';

  @override
  String get hintClipboardText => 'Text zum Speichern im Tag';

  @override
  String get msgContentRequired => 'Bitte geben Sie den Inhalt ein.';

  @override
  String get screenIosInputTitle => 'iOS App-Start Einstellung';

  @override
  String get labelShortcutName => 'Kurzbefehlname der zu startenden App';

  @override
  String get hintShortcutName => 'z.B.: MeineApp';

  @override
  String get msgAppNameRequired => 'Bitte geben Sie den App-Namen ein.';

  @override
  String get screenIosInputGuideTitle => 'Kurzbefehl-Einrichtung';

  @override
  String get screenIosInputGuideSteps =>
      '1. Öffnen Sie die Kurzbefehle-App auf Ihrem iPhone\n2. Erstellen Sie einen Kurzbefehl, der die gewünschte App öffnet\n3. Speichern Sie den Kurzbefehl mit dem oben eingegebenen Namen\n4. Drücken Sie die Taste unten, um QR/NFC zu erstellen';

  @override
  String get actionAppleShortcutsGuide =>
      'Offizieller Apple Kurzbefehle-Leitfaden';

  @override
  String get screenAppPickerTitle => 'App auswählen';

  @override
  String get hintAppSearch => 'Apps suchen...';

  @override
  String get msgAppListError => 'App-Liste konnte nicht geladen werden.';

  @override
  String get msgSelectApp => 'Bitte wählen Sie eine App aus.';

  @override
  String get screenNfcWriterTitle => 'NFC-Schreibvorgang';

  @override
  String get msgNfcWaiting =>
      'Halten Sie den NFC-Tag an die\nRückseite Ihres Smartphones';

  @override
  String get msgNfcSuccess =>
      'Schreibvorgang abgeschlossen!\nZurück zur Startseite...';

  @override
  String get msgNfcError => 'NFC-Schreibvorgang fehlgeschlagen.';

  @override
  String get labelNfcIncludeIos => 'iOS-Kurzbefehl mitschreiben';

  @override
  String get labelIosShortcutName => 'iOS Kurzbefehlname';

  @override
  String get hintIosShortcutName => 'z.B.: WhatsApp';

  @override
  String get screenOutputSelectorTitle => 'Ausgabemethode wählen';

  @override
  String get screenOutputQrDesc => 'Mit Kamera scannen, um App zu starten';

  @override
  String get screenOutputNfcDesc => 'Tag berühren, um App zu starten';

  @override
  String get msgNfcCheckFailed => 'NFC-Prüfung fehlgeschlagen';

  @override
  String get msgNfcSimulator => 'NFC kann im Simulator nicht getestet werden';

  @override
  String get msgNfcNotSupported => 'Dieses Gerät unterstützt kein NFC';

  @override
  String get msgNfcWriteIosMin =>
      'NFC-Schreiben erfordert iPhone XS oder neuer';

  @override
  String get msgNfcUnsupportedDevice => 'Gerät ohne NFC-Unterstützung';

  @override
  String get actionNfcWrite => 'NFC-Tag beschreiben';

  @override
  String get screenQrResultTitle => 'QR-Code';

  @override
  String get tabTemplate => 'Vorlage';

  @override
  String get tabShape => 'Form';

  @override
  String get tabColor => 'Farbe';

  @override
  String get tabLogo => 'Logo';

  @override
  String get tabText => 'Text';

  @override
  String get actionSaveGallery => 'In Galerie speichern';

  @override
  String get actionSaveTemplate => 'Vorlage speichern';

  @override
  String get dialogLowReadabilityTitle => 'Niedrige Lesbarkeit';

  @override
  String dialogLowReadabilityScore(int score) {
    return 'Aktuelle Lesbarkeit: $score%';
  }

  @override
  String get dialogLowReadabilityWarning =>
      'Der QR-Code wird möglicherweise\nvon einigen Scannern nicht erkannt.';

  @override
  String dialogLowReadabilityCause(String issue) {
    return 'Hauptursache: $issue';
  }

  @override
  String get actionSaveAnyway => 'Trotzdem speichern';

  @override
  String get dialogSaveTemplateTitle => 'Vorlage speichern';

  @override
  String get labelTemplateName => 'Vorlagenname';

  @override
  String get hintTemplateName => 'z.B.: Blauer Hintergrund QR';

  @override
  String msgTemplateSaved(String name) {
    return 'Vorlage \'$name\' wurde gespeichert.';
  }

  @override
  String get msgSaveFailed => 'Bild konnte nicht gespeichert werden.';

  @override
  String get msgPrintFailed =>
      'Druck fehlgeschlagen. Bitte überprüfen Sie die Druckerverbindung.';

  @override
  String get labelReadability => 'Lesbarkeit';

  @override
  String get screenTemplateMyTemplates => 'Meine Vorlagen';

  @override
  String get actionNoStyle => 'Kein Stil';

  @override
  String msgTemplateApplied(String name) {
    return 'Vorlage \'$name\' wurde angewendet.';
  }

  @override
  String get dialogDeleteTemplateTitle => 'Vorlage löschen';

  @override
  String dialogDeleteTemplateContent(String name) {
    return 'Möchten Sie \'$name\' löschen?';
  }

  @override
  String get msgNoSavedTemplates => 'Keine gespeicherten Vorlagen.';

  @override
  String get msgNoSavedTemplatesHint =>
      'Speichern Sie den aktuellen Stil mit der Taste [Vorlage speichern] unten.';

  @override
  String get tabColorSolid => 'Einfarbig';

  @override
  String get tabColorGradient => 'Verlauf';

  @override
  String get actionPickColor => 'Farbe wählen';

  @override
  String get labelRecommendedColors => 'Empfohlene Farben';

  @override
  String get labelGradientPresets => 'Verlauf-Voreinstellungen';

  @override
  String get dialogColorPickerTitle => 'Farbe wählen';

  @override
  String get labelDotShape => 'Punktform';

  @override
  String get labelEyeOuter => 'Augenform — Außen';

  @override
  String get labelEyeInner => 'Augenform — Innen';

  @override
  String get shapeSquare => 'Quadrat';

  @override
  String get shapeRounded => 'Abgerundet';

  @override
  String get shapeCircle => 'Kreis';

  @override
  String get shapeCircleRound => 'Kreis-Donut';

  @override
  String get shapeSmooth => 'Glatt';

  @override
  String get shapeDiamond => 'Raute';

  @override
  String get shapeStar => 'Stern';

  @override
  String get actionRandomRegenerate => 'Zufällig neu generieren';

  @override
  String get actionRandomEye => 'Zufällige Augenform';

  @override
  String get actionClear => 'Zurücksetzen';

  @override
  String get labelShowIcon => 'Symbol anzeigen';

  @override
  String get msgIconUnavailable =>
      'Wird nur angezeigt, wenn ein App-Symbol oder Emoji festgelegt ist.';

  @override
  String get labelLogoPosition => 'Logo-Position';

  @override
  String get optionCenter => 'Mitte';

  @override
  String get optionBottomRight => 'Unten rechts';

  @override
  String get labelLogoBackground => 'Logo-Hintergrund';

  @override
  String get optionNone => 'Keiner';

  @override
  String get optionSquare => 'Quadrat';

  @override
  String get optionCircle => 'Kreis';

  @override
  String get labelTopText => 'Oberer Text';

  @override
  String get labelBottomText => 'Unterer Text';

  @override
  String get hintEnterText => 'Text eingeben';

  @override
  String get screenSettingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemstandard';

  @override
  String msgCopiedToClipboard(String text) {
    return '\'$text\' in die Zwischenablage kopiert';
  }

  @override
  String get settingsReadabilityAlert => 'Lesbarkeitswarnung';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';
}
