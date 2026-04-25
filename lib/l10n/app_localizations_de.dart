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
  String get actionEdit => 'Bearbeiten';

  @override
  String actionDeleteCount(int count) {
    return '$count löschen';
  }

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
  String get tooltipFavorite => '즐겨찾기';

  @override
  String get tooltipUnfavorite => '즐겨찾기 해제';

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
  String get actionSaveSvg => 'SVG 저장';

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
  String get templateSectionFavorites => '내 즐겨찾기';

  @override
  String get templateEmptyFavorites =>
      '즐겨찾기한 QR이 없습니다.\n홈 화면에서 QR을 즐겨찾기에 추가해 보세요.';

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
  String get drawerSvgStorage => 'SVG 저장함';

  @override
  String get svgStorageEmpty => '저장된 SVG 파일이 없습니다';

  @override
  String get svgStorageDeleteConfirm => '이 SVG 파일을 삭제하시겠습니까?';

  @override
  String get drawerAppInfo => '프로그램 정보';

  @override
  String get appInfoBuild => '빌드';

  @override
  String get appInfoTemplateEngine => '템플릿 엔진';

  @override
  String get appInfoTemplateSchema => '템플릿 스키마';

  @override
  String get legalPrivacyPolicy => '개인정보처리방침';

  @override
  String get legalTermsOfService => '이용약관';

  @override
  String get legalAccountDeletion => '계정 삭제 안내';

  @override
  String get legalSupport => '문의하기';

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

  @override
  String get labelCustomGradient => 'Benutzerdefinierter Verlauf';

  @override
  String get labelGradientType => 'Typ';

  @override
  String get optionLinear => 'Linear';

  @override
  String get optionRadial => 'Radial';

  @override
  String get labelAngle => 'Winkel';

  @override
  String get labelCenter => 'Mitte';

  @override
  String get optionCenterCenter => 'Mitte';

  @override
  String get optionCenterTopLeft => 'Oben links';

  @override
  String get optionCenterTopRight => 'Oben rechts';

  @override
  String get optionCenterBottomLeft => 'Unten links';

  @override
  String get optionCenterBottomRight => 'Unten rechts';

  @override
  String get labelColorStops => 'Farbpunkte';

  @override
  String get actionAddStop => 'Hinzufügen';

  @override
  String get actionDeleteStop => 'Löschen';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get signupTitle => 'Registrieren';

  @override
  String get continueWithGoogle => 'Mit Google fortfahren';

  @override
  String get continueWithApple => 'Mit Apple fortfahren';

  @override
  String get loginWithEmail => 'Mit E-Mail anmelden';

  @override
  String get useWithoutLogin => 'Ohne Anmeldung nutzen';

  @override
  String get orDivider => 'oder';

  @override
  String get noAccountYet => 'Noch kein Konto?';

  @override
  String get signUp => 'Registrieren';

  @override
  String get nickname => 'Spitzname';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get passwordConfirm => 'Passwort bestätigen';

  @override
  String get passwordMinLength =>
      'Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get passwordMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get invalidEmail => 'Bitte gültige E-Mail eingeben';

  @override
  String get nicknameRequired => 'Bitte Spitznamen eingeben';

  @override
  String get profileTitle => 'Mein Profil';

  @override
  String get changePhoto => 'Foto ändern';

  @override
  String get loginMethod => 'Anmeldemethode';

  @override
  String get joinDate => 'Beitrittsdatum';

  @override
  String get syncStatus => 'Synchronisierungsstatus';

  @override
  String get synced => 'Synchronisiert';

  @override
  String get syncing => 'Synchronisierung...';

  @override
  String get syncError => 'Synchronisierung fehlgeschlagen';

  @override
  String get lastSynced => 'Letzte Synchronisierung';

  @override
  String get justNow => 'Gerade eben';

  @override
  String get manualSync => 'Jetzt synchronisieren';

  @override
  String get logout => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountConfirm =>
      'Möchten Sie Ihr Konto wirklich löschen? Alle Cloud-Daten werden gelöscht.';

  @override
  String get logoutConfirm =>
      'Möchten Sie sich abmelden? Lokale Daten bleiben erhalten.';

  @override
  String get accountSection => 'Konto';

  @override
  String get syncSection => 'Synchronisierung';

  @override
  String get loginPrompt => 'Anmelden';

  @override
  String get cloudSync => 'Cloud-Synchronisierung';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get labelSavePreset => 'Preset speichern';

  @override
  String get hintPresetName => 'Preset-Name';

  @override
  String get labelBoundaryShape => 'QR-Rahmenform';

  @override
  String get labelAnimation => 'Animation';

  @override
  String get labelCustomDot => 'Benutzerdefinierter Punkt';

  @override
  String get labelCustomEye => 'Benutzerdefiniertes Auge';

  @override
  String get labelCustomBoundary => 'Benutzerdefinierter Rahmen';

  @override
  String get labelCustomAnimation => 'Benutzerdefinierte Animation';

  @override
  String get actionApply => 'Anwenden';

  @override
  String get sliderVertices => 'Ecken';

  @override
  String get sliderInnerRadius => 'Innenradius';

  @override
  String get sliderRoundness => 'Rundung';

  @override
  String get sliderRotation => 'Drehung';

  @override
  String get sliderDotScale => 'Größe';

  @override
  String get labelSymmetric => 'Symmetrisch';

  @override
  String get labelAsymmetric => 'Asymmetrisch';

  @override
  String get sliderSfM => 'Symmetrie (m)';

  @override
  String get sliderSfN1 => 'Krümmung 1';

  @override
  String get sliderSfN2 => 'Krümmung 2';

  @override
  String get sliderSfN3 => 'Krümmung 3';

  @override
  String get sliderSfA => 'X-Skalierung';

  @override
  String get sliderSfB => 'Y-Skalierung';

  @override
  String get sliderOuterN => 'Außenform';

  @override
  String get sliderInnerN => 'Innenform';

  @override
  String get sliderCornerQ1 => 'Q1 모서리';

  @override
  String get sliderCornerQ2 => 'Q2 모서리';

  @override
  String get sliderCornerQ3 => 'Q3 모서리';

  @override
  String get sliderCornerQ4 => 'Q4 모서리';

  @override
  String get labelBoundaryType => 'Rahmentyp';

  @override
  String get sliderSuperellipseN => 'Form N';

  @override
  String get sliderStarVertices => 'Sternspitzen';

  @override
  String get sliderStarInnerRadius => 'Sterntiefe';

  @override
  String get sliderPadding => 'Abstand';

  @override
  String get sliderFrameScale => '프레임 크기';

  @override
  String get labelMarginPattern => '마진 패턴';

  @override
  String get sliderPatternDensity => '패턴 밀도';

  @override
  String get patternNone => '없음';

  @override
  String get patternQrDots => '도트';

  @override
  String get patternMaze => '미로';

  @override
  String get patternZigzag => '지그재그';

  @override
  String get patternWave => '물결';

  @override
  String get patternGrid => '격자';

  @override
  String get sliderSpeed => 'Geschwindigkeit';

  @override
  String get sliderAmplitude => 'Amplitude';

  @override
  String get sliderFrequency => 'Frequenz';

  @override
  String get optionLogoTypeLogo => 'Logo';

  @override
  String get optionLogoTypeImage => 'Bild';

  @override
  String get optionLogoTypeText => 'Text';

  @override
  String get labelLogoTabPosition => 'Position';

  @override
  String get labelLogoTabBackground => 'Hintergrund';

  @override
  String get labelLogoCategory => 'Kategorie';

  @override
  String get labelLogoGallery => 'Aus Galerie wählen';

  @override
  String get labelLogoRecrop => 'Neu zuschneiden';

  @override
  String get labelLogoTextContent => 'Text';

  @override
  String get hintLogoTextContent => 'Logo-Text';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryCoin => 'Krypto';

  @override
  String get categoryBrand => 'Marke';

  @override
  String get categoryEmoji => 'Emoji';

  @override
  String get msgLogoLoadFailed => 'Symbol konnte nicht geladen werden';

  @override
  String get msgLogoCropFailed => 'Bild konnte nicht verarbeitet werden';

  @override
  String get labelLogoBackgroundColor => 'Farbe';

  @override
  String get actionLogoBackgroundReset => 'Standard';

  @override
  String get optionRectangle => 'Quadrat';

  @override
  String get optionRoundedRectangle => 'Kreis';

  @override
  String get labelLogoType => 'Typ';

  @override
  String get tileScanner => 'QR 스캐너';

  @override
  String get scannerPermissionTitle => '카메라 권한 필요';

  @override
  String get scannerPermissionDesc => 'QR 코드를 스캔하려면 카메라 접근 권한이 필요합니다.';

  @override
  String get scannerPermissionOpenSettings => '설정으로 이동';

  @override
  String get scannerPermissionGalleryFallback => '갤러리에서 선택';

  @override
  String get scannerFlashOn => '플래시 켜기';

  @override
  String get scannerFlashOff => '플래시 끄기';

  @override
  String get scannerGalleryImport => '갤러리에서 QR 코드 불러오기';

  @override
  String get scannerGalleryFail => '이미지에서 QR 코드를 인식할 수 없습니다.';

  @override
  String get scanResultTitle => '스캔 결과';

  @override
  String get scanActionOpenBrowser => '열기';

  @override
  String get scanActionCopyLink => '링크 복사';

  @override
  String get scanActionCopySsid => 'SSID 복사';

  @override
  String get scanActionCopyPassword => '비밀번호 복사';

  @override
  String get scanActionCopyAll => '전체 복사';

  @override
  String get scanActionShare => '공유';

  @override
  String get scanActionOpenApp => '앱 열기';

  @override
  String get scanActionCustomize => '꾸미기';

  @override
  String get historyTabCreated => '생성이력';

  @override
  String get historyTabScanned => '스캔이력';

  @override
  String get historySearchHint => '검색...';

  @override
  String get historyFilterAll => '전체';

  @override
  String get historyEmpty => '이력이 없습니다.';

  @override
  String get actionFavorite => '즐겨찾기';

  @override
  String get actionStartCustomize => 'QR 만들기';

  @override
  String get actionNext => '다음';

  @override
  String get actionCreateNew => '새로 만들기';

  @override
  String get actionEditAgain => '편집하기';

  @override
  String get actionRename => '이름 변경';

  @override
  String get sheetCreateTitle => '새로 만들기';

  @override
  String get homeEmptyTitle => '첫 QR을 만들어 보세요';

  @override
  String get dialogRenameTitle => '이름 변경';

  @override
  String get hintTaskName => '작업 이름';

  @override
  String get dialogDeleteTitle => '삭제';

  @override
  String dialogDeleteContent(String name) {
    return '$name 을(를) 삭제하시겠습니까?';
  }

  @override
  String get msgNoThumbnail => '미리보기 이미지가 없습니다';

  @override
  String get msgSavedToGallery => '갤러리에 저장되었습니다';

  @override
  String get msgSvgSaved => 'SVG 파일이 저장되었습니다';

  @override
  String get labelQr => 'QR';

  @override
  String get timeJustNow => '방금';

  @override
  String timeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get actionSelectAll => '모두선택';

  @override
  String get actionDeleteAll => '모두삭제';

  @override
  String get dialogDeleteAllTitle => '전체 삭제';

  @override
  String get dialogDeleteAllContent => '모든 QR을 삭제하시겠습니까?';

  @override
  String get dialogDeleteSelectedTitle => '선택 삭제';

  @override
  String dialogDeleteSelectedContent(int count) {
    return '$count개의 QR을 삭제하시겠습니까?';
  }
}
