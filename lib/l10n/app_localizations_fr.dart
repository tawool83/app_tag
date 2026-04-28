// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Générateur QR et NFC';

  @override
  String get screenSplashSubtitle =>
      'Créez et personnalisez vos propres codes QR';

  @override
  String get tileAppAndroid => 'Lancer l\'app';

  @override
  String get tileAppIos => 'Raccourci';

  @override
  String get tileClipboard => 'Presse-papiers';

  @override
  String get tileWebsite => 'Site Web';

  @override
  String get tileContact => 'Contact';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => 'Emplacement';

  @override
  String get tileEvent => 'Événement';

  @override
  String get tileEmail => 'Email';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'Générateur QR et NFC';

  @override
  String get screenHomeEditModeTitle => 'Mode Édition';

  @override
  String get actionDone => 'Terminé';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String actionDeleteCount(int count) {
    return 'Supprimer $count';
  }

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionShare => 'Partager';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionConfirm => 'OK';

  @override
  String get tooltipHelp => 'Guide d\'utilisation';

  @override
  String get tooltipFavorite => '즐겨찾기';

  @override
  String get tooltipUnfavorite => '즐겨찾기 해제';

  @override
  String get tooltipHistory => 'Historique';

  @override
  String get tooltipDeleteAll => 'Tout supprimer';

  @override
  String get actionCollapseHidden => 'Réduire le menu masqué';

  @override
  String actionShowHidden(int count) {
    return 'Voir le menu masqué ($count)';
  }

  @override
  String get screenHelpTitle => 'Guide d\'utilisation';

  @override
  String get screenHistoryTitle => 'Historique';

  @override
  String get screenHistoryEmpty => 'Aucun historique.';

  @override
  String get labelQrCode => 'Code QR';

  @override
  String get labelNfcTag => 'Tag NFC';

  @override
  String get dialogClearAllTitle => 'Tout supprimer';

  @override
  String get dialogClearAllContent =>
      'Voulez-vous supprimer tout l\'historique ?';

  @override
  String get dialogDeleteHistoryTitle => 'Supprimer l\'historique';

  @override
  String dialogDeleteHistoryContent(String name) {
    return 'Voulez-vous supprimer l\'historique de « $name » ?';
  }

  @override
  String get screenWebsiteTitle => 'Tag Site Web';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'Veuillez saisir une URL.';

  @override
  String get msgUrlInvalid => 'Veuillez saisir une URL valide.';

  @override
  String get screenWifiTitle => 'Tag WiFi';

  @override
  String get labelWifiSsid => 'Nom du réseau (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'Veuillez saisir le SSID.';

  @override
  String get labelWifiSecurity => 'Sécurité';

  @override
  String get optionWpa2 => 'WPA2 (Recommandé)';

  @override
  String get optionNoSecurity => 'Aucune';

  @override
  String get labelWifiPassword => 'Mot de passe';

  @override
  String get hintWifiPassword => 'Mot de passe';

  @override
  String get screenSmsTitle => 'Tag SMS';

  @override
  String get labelPhoneRequired => 'Numéro de téléphone *';

  @override
  String get hintPhone => '06-00-00-00-00';

  @override
  String get msgPhoneRequired => 'Veuillez saisir un numéro de téléphone.';

  @override
  String get labelMessageOptional => 'Message (Facultatif)';

  @override
  String get hintSmsMessage => 'Contenu du message';

  @override
  String get screenEmailTitle => 'Tag Email';

  @override
  String get labelEmailRequired => 'Adresse email *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => 'Veuillez saisir une adresse email.';

  @override
  String get msgEmailInvalid => 'Veuillez saisir une adresse email valide.';

  @override
  String get labelEmailSubjectOptional => 'Objet (Facultatif)';

  @override
  String get hintEmailSubject => 'Objet de l\'email';

  @override
  String get labelEmailBodyOptional => 'Corps (Facultatif)';

  @override
  String get hintEmailBody => 'Corps de l\'email';

  @override
  String get screenContactTitle => 'Tag Contact';

  @override
  String get actionManualInput => 'Saisie manuelle';

  @override
  String get screenContactManualSubtitle =>
      'Saisissez le nom, le téléphone et l\'email manuellement';

  @override
  String get hintSearchByName => 'Rechercher par nom';

  @override
  String get labelNoPhone => 'Pas de numéro de téléphone';

  @override
  String get msgContactPermissionRequired => 'L\'accès aux contacts est requis';

  @override
  String get msgContactPermissionHint =>
      'Utilisez la saisie manuelle ou autorisez l\'accès dans les paramètres.';

  @override
  String get actionOpenSettings => 'Ouvrir les Paramètres';

  @override
  String get msgSearchNoResults => 'Aucun résultat de recherche.';

  @override
  String get msgNoContacts => 'Aucun contact enregistré.';

  @override
  String get screenContactManualTitle => 'Saisie manuelle';

  @override
  String get labelNameRequired => 'Nom *';

  @override
  String get hintName => 'Jean Dupont';

  @override
  String get msgNameRequired => 'Veuillez saisir un nom.';

  @override
  String get labelPhone => 'Téléphone';

  @override
  String get labelEmail => 'Email';

  @override
  String get screenLocationTitle => 'Tag Emplacement';

  @override
  String get screenLocationTapHint =>
      'Appuyez sur la carte pour sélectionner un emplacement.';

  @override
  String get msgSearchingAddress => 'Recherche d\'adresse...';

  @override
  String get msgAddressUnavailable => 'Impossible de récupérer l\'adresse.';

  @override
  String get labelPlaceNameOptional => 'Nom du lieu (Facultatif)';

  @override
  String get hintPlaceName =>
      'Laissez vide pour utiliser automatiquement le nom du bâtiment.';

  @override
  String get msgSelectLocation =>
      'Veuillez sélectionner un emplacement sur la carte.';

  @override
  String get screenEventTitle => 'Tag Événement';

  @override
  String get labelEventTitleRequired => 'Titre de l\'événement *';

  @override
  String get hintEventTitle => 'Titre de l\'événement';

  @override
  String get msgEventTitleRequired => 'Veuillez saisir un titre.';

  @override
  String get labelEventStart => 'Début';

  @override
  String get labelEventEnd => 'Fin';

  @override
  String get labelEventLocationOptional => 'Lieu/Adresse (Facultatif)';

  @override
  String get hintEventLocation => '1 Rue de Rivoli, Paris...';

  @override
  String get labelEventDescOptional => 'Description (Facultatif)';

  @override
  String get hintEventDesc => 'Description de l\'événement';

  @override
  String get msgEventEndBeforeStart =>
      'L\'heure de fin doit être postérieure à l\'heure de début.';

  @override
  String get screenClipboardTitle => 'Tag Presse-papiers';

  @override
  String get msgClipboardEmpty =>
      'Le presse-papiers est vide. Saisissez le texte manuellement.';

  @override
  String get labelContent => 'Contenu';

  @override
  String get hintClipboardText => 'Texte à enregistrer dans le tag';

  @override
  String get msgContentRequired => 'Veuillez saisir le contenu.';

  @override
  String get screenIosInputTitle => 'Configuration App iOS';

  @override
  String get labelShortcutName => 'Nom du raccourci de l\'app à lancer';

  @override
  String get hintShortcutName => 'Ex : MonApp';

  @override
  String get msgAppNameRequired => 'Veuillez saisir le nom de l\'app.';

  @override
  String get screenIosInputGuideTitle =>
      'Guide de configuration des raccourcis';

  @override
  String get screenIosInputGuideSteps =>
      '1. Ouvrez l\'app Raccourcis (Shortcuts) sur votre iPhone\n2. Créez un raccourci qui ouvre l\'app souhaitée\n3. Enregistrez le raccourci avec le nom saisi ci-dessus\n4. Appuyez sur le bouton ci-dessous pour générer le QR/NFC';

  @override
  String get actionAppleShortcutsGuide => 'Guide officiel des Raccourcis Apple';

  @override
  String get screenAppPickerTitle => 'Sélectionner une App';

  @override
  String get hintAppSearch => 'Rechercher des apps...';

  @override
  String get msgAppListError => 'Impossible de charger la liste des apps.';

  @override
  String get msgSelectApp => 'Veuillez sélectionner une app.';

  @override
  String get screenNfcWriterTitle => 'Écriture NFC';

  @override
  String get msgNfcWaiting =>
      'Approchez le tag NFC de\nl\'arrière de votre téléphone';

  @override
  String get msgNfcSuccess => 'Écriture terminée !\nRetour à l\'accueil...';

  @override
  String get msgNfcError => 'L\'écriture NFC a échoué.';

  @override
  String get labelNfcIncludeIos => 'Inclure le raccourci iOS';

  @override
  String get labelIosShortcutName => 'Nom du raccourci iOS';

  @override
  String get hintIosShortcutName => 'Ex : WhatsApp';

  @override
  String get screenOutputSelectorTitle => 'Choisir le mode de sortie';

  @override
  String get screenOutputQrDesc => 'Scanner avec la caméra pour lancer l\'app';

  @override
  String get screenOutputNfcDesc => 'Approcher le tag pour lancer l\'app';

  @override
  String get msgNfcCheckFailed => 'Vérification NFC échouée';

  @override
  String get msgNfcSimulator => 'Impossible de tester NFC sur le simulateur';

  @override
  String get msgNfcNotSupported => 'Cet appareil ne supporte pas le NFC';

  @override
  String get msgNfcWriteIosMin =>
      'L\'écriture NFC nécessite un iPhone XS ou ultérieur';

  @override
  String get msgNfcUnsupportedDevice => 'Appareil non compatible NFC';

  @override
  String get actionNfcWrite => 'Écrire le tag NFC';

  @override
  String get screenQrResultTitle => 'Code QR';

  @override
  String get tabTemplate => 'Modèle';

  @override
  String get tabShape => 'Forme';

  @override
  String get tabBackground => '배경';

  @override
  String get tabColor => 'Couleur';

  @override
  String get tabLogo => 'Logo';

  @override
  String get tabText => 'Texte';

  @override
  String get actionSaveGallery => 'Enregistrer dans la Galerie';

  @override
  String get actionSaveSvg => 'SVG 저장';

  @override
  String get actionSaveTemplate => 'Enregistrer le Modèle';

  @override
  String get dialogLowReadabilityTitle => 'Lisibilité faible';

  @override
  String dialogLowReadabilityScore(int score) {
    return 'Lisibilité actuelle : $score%';
  }

  @override
  String get dialogLowReadabilityWarning =>
      'Le code QR pourrait ne pas être reconnu\npar certains scanners.';

  @override
  String dialogLowReadabilityCause(String issue) {
    return 'Cause principale : $issue';
  }

  @override
  String get actionSaveAnyway => 'Enregistrer quand même';

  @override
  String get dialogSaveTemplateTitle => 'Enregistrer le Modèle';

  @override
  String get labelTemplateName => 'Nom du modèle';

  @override
  String get hintTemplateName => 'Ex : QR fond bleu';

  @override
  String msgTemplateSaved(String name) {
    return 'Modèle « $name » enregistré.';
  }

  @override
  String get msgSaveFailed => 'Échec de l\'enregistrement de l\'image.';

  @override
  String get msgPrintFailed =>
      'Échec de l\'impression. Vérifiez la connexion de l\'imprimante.';

  @override
  String get labelReadability => 'Lisibilité';

  @override
  String get screenTemplateMyTemplates => 'Mes Modèles';

  @override
  String get templateSectionFavorites => '내 즐겨찾기';

  @override
  String get templateEmptyFavorites =>
      '즐겨찾기한 QR이 없습니다.\n홈 화면에서 QR을 즐겨찾기에 추가해 보세요.';

  @override
  String get dialogDeleteTemplateTitle => 'Supprimer le Modèle';

  @override
  String dialogDeleteTemplateContent(String name) {
    return 'Voulez-vous supprimer « $name » ?';
  }

  @override
  String get msgNoSavedTemplates => 'Aucun modèle enregistré.';

  @override
  String get msgNoSavedTemplatesHint =>
      'Enregistrez le style actuel avec le bouton [Enregistrer le Modèle] ci-dessous.';

  @override
  String get tabColorSolid => 'Uni';

  @override
  String get tabColorGradient => 'Dégradé';

  @override
  String get colorTargetBoth => '동시';

  @override
  String get colorTargetQr => 'QR';

  @override
  String get colorTargetBg => '배경';

  @override
  String get actionPickColor => 'Choisir une couleur';

  @override
  String get labelRecommendedColors => 'Couleurs recommandées';

  @override
  String get labelGradientPresets => 'Préréglages de dégradé';

  @override
  String get dialogColorPickerTitle => 'Choisir une couleur';

  @override
  String get labelDotShape => 'Forme du point';

  @override
  String get labelEyeOuter => 'Forme de l\'œil — Extérieur';

  @override
  String get labelEyeInner => 'Forme de l\'œil — Intérieur';

  @override
  String get shapeSquare => 'Carré';

  @override
  String get shapeRounded => 'Arrondi';

  @override
  String get shapeCircle => 'Cercle';

  @override
  String get shapeCircleRound => 'Cercle donut';

  @override
  String get shapeSmooth => 'Lisse';

  @override
  String get shapeDiamond => 'Diamant';

  @override
  String get shapeStar => 'Étoile';

  @override
  String get actionClear => 'Effacer';

  @override
  String get labelShowIcon => 'Afficher l\'icône';

  @override
  String get msgIconUnavailable =>
      'Affiché uniquement lorsqu\'une icône d\'app ou un emoji est défini.';

  @override
  String get labelLogoPosition => 'Position du logo';

  @override
  String get optionCenter => 'Centre';

  @override
  String get optionBottomRight => 'En bas à droite';

  @override
  String get labelLogoBackground => 'Fond du logo';

  @override
  String get optionNone => 'Aucun';

  @override
  String get optionSquare => 'Carré';

  @override
  String get optionCircle => 'Cercle';

  @override
  String get labelTopText => 'Texte en haut';

  @override
  String get labelCenterText => '중앙';

  @override
  String get labelBottomText => 'Texte en bas';

  @override
  String get labelBandHorizontal => '가로띠';

  @override
  String get labelBandVertical => '세로띠';

  @override
  String get labelBgSquare => '사각';

  @override
  String get labelBgCircle => '원형';

  @override
  String get labelTextBackground => '배경';

  @override
  String get optionTextBgNone => '없음';

  @override
  String get optionTextBgFilled => '채움';

  @override
  String get labelTextBgColor => '배경색';

  @override
  String get labelTextColor => '글자색';

  @override
  String get labelTextSize => '크기';

  @override
  String get hintEnterText => 'Saisissez du texte';

  @override
  String get screenSettingsTitle => 'Paramètres';

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
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Par défaut du système';

  @override
  String msgCopiedToClipboard(String text) {
    return '« $text » copié dans le presse-papiers';
  }

  @override
  String get settingsReadabilityAlert => 'Alerte de lisibilité';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';

  @override
  String get labelCustomGradient => 'Dégradé personnalisé';

  @override
  String get labelGradientType => 'Type';

  @override
  String get optionLinear => 'Linéaire';

  @override
  String get optionRadial => 'Radial';

  @override
  String get labelAngle => 'Angle';

  @override
  String get labelCenter => 'Centre';

  @override
  String get optionCenterCenter => 'Centre';

  @override
  String get optionCenterTopLeft => 'Haut gauche';

  @override
  String get optionCenterTopRight => 'Haut droite';

  @override
  String get optionCenterBottomLeft => 'Bas gauche';

  @override
  String get optionCenterBottomRight => 'Bas droite';

  @override
  String get labelColorStops => 'Points de couleur';

  @override
  String get actionAddStop => 'Ajouter';

  @override
  String get actionDeleteStop => 'Supprimer';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get signupTitle => 'Inscription';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get loginWithEmail => 'Se connecter par email';

  @override
  String get useWithoutLogin => 'Utiliser sans connexion';

  @override
  String get orDivider => 'ou';

  @override
  String get noAccountYet => 'Pas encore de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get nickname => 'Pseudo';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordConfirm => 'Confirmer le mot de passe';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get invalidEmail => 'Veuillez entrer un email valide';

  @override
  String get nicknameRequired => 'Veuillez entrer un pseudo';

  @override
  String get profileTitle => 'Mon Profil';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get loginMethod => 'Méthode de connexion';

  @override
  String get joinDate => 'Date d\'inscription';

  @override
  String get syncStatus => 'État de synchronisation';

  @override
  String get synced => 'Synchronisé';

  @override
  String get syncing => 'Synchronisation...';

  @override
  String get syncError => 'Échec de synchronisation';

  @override
  String get lastSynced => 'Dernière synchronisation';

  @override
  String get justNow => 'À l\'instant';

  @override
  String get manualSync => 'Synchroniser maintenant';

  @override
  String get logout => 'Déconnexion';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountConfirm =>
      'Voulez-vous vraiment supprimer votre compte ? Toutes les données cloud seront supprimées.';

  @override
  String get logoutConfirm =>
      'Voulez-vous vous déconnecter ? Les données locales seront conservées.';

  @override
  String get accountSection => 'Compte';

  @override
  String get syncSection => 'Synchronisation';

  @override
  String get loginPrompt => 'Se connecter';

  @override
  String get cloudSync => 'Synchronisation cloud';

  @override
  String get cancel => 'Annuler';

  @override
  String get labelSavePreset => 'Enregistrer le preset';

  @override
  String get hintPresetName => 'Nom du preset';

  @override
  String get labelBoundaryShape => 'Forme du contour QR';

  @override
  String get labelQuietZoneBorder => '테두리선';

  @override
  String get labelBorderWidth => '두께';

  @override
  String get labelAnimation => 'Animation';

  @override
  String get labelCustomDot => 'Point personnalisé';

  @override
  String get labelCustomEye => 'Œil personnalisé';

  @override
  String get labelCustomBoundary => 'Contour personnalisé';

  @override
  String get labelCustomAnimation => 'Animation personnalisée';

  @override
  String get actionApply => 'Appliquer';

  @override
  String get sliderVertices => 'Sommets';

  @override
  String get sliderInnerRadius => 'Rayon interne';

  @override
  String get sliderRoundness => 'Arrondi';

  @override
  String get sliderRotation => 'Rotation';

  @override
  String get sliderDotScale => 'Taille';

  @override
  String get labelSymmetric => 'Symétrique';

  @override
  String get labelAsymmetric => 'Asymétrique';

  @override
  String get sliderSfM => 'Symétrie (m)';

  @override
  String get sliderSfN1 => 'Courbure 1';

  @override
  String get sliderSfN2 => 'Courbure 2';

  @override
  String get sliderSfN3 => 'Courbure 3';

  @override
  String get sliderSfA => 'Échelle X';

  @override
  String get sliderSfB => 'Échelle Y';

  @override
  String get sliderOuterN => 'Forme extérieure';

  @override
  String get sliderInnerN => 'Forme intérieure';

  @override
  String get sliderCornerQ1 => 'Q1 모서리';

  @override
  String get sliderCornerQ2 => 'Q2 모서리';

  @override
  String get sliderCornerQ3 => 'Q3 모서리';

  @override
  String get sliderCornerQ4 => 'Q4 모서리';

  @override
  String get labelBoundaryType => 'Type de contour';

  @override
  String get sliderSuperellipseN => 'Forme N';

  @override
  String get sliderStarVertices => 'Pointes d\'étoile';

  @override
  String get sliderStarInnerRadius => 'Profondeur';

  @override
  String get sliderPadding => 'Marge';

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
  String get labelFrameColors => '프레임 색상';

  @override
  String get labelBorderStyle => '선 종류';

  @override
  String get labelBorderColor => '선 색상';

  @override
  String get sliderBorderWidth => '선 두께';

  @override
  String get labelPatternColor => '패턴 색상';

  @override
  String get borderNone => '없음';

  @override
  String get borderSolid => '실선';

  @override
  String get borderDashed => '파선';

  @override
  String get borderDotted => '점선';

  @override
  String get borderDashDot => '일점쇄선';

  @override
  String get borderDouble => '이중선';

  @override
  String get boundaryNone => '없음';

  @override
  String get boundaryCircle => '원형';

  @override
  String get boundarySuperellipse => '슈퍼타원';

  @override
  String get boundaryStar => '별';

  @override
  String get boundaryHeart => '하트';

  @override
  String get boundaryHexagon => '육각형';

  @override
  String get labelFontFamily => '글꼴';

  @override
  String get sliderSpeed => 'Vitesse';

  @override
  String get sliderAmplitude => 'Amplitude';

  @override
  String get sliderFrequency => 'Fréquence';

  @override
  String get optionLogoTypeLogo => 'Logo';

  @override
  String get optionLogoTypeImage => 'Image';

  @override
  String get optionLogoTypeText => 'Texte';

  @override
  String get labelLogoTabPosition => 'Position';

  @override
  String get labelLogoTabBackground => 'Fond';

  @override
  String get labelLogoCategory => 'Catégorie';

  @override
  String get labelLogoGallery => 'Choisir depuis la galerie';

  @override
  String get labelLogoRecrop => 'Recadrer';

  @override
  String get labelLogoTextContent => 'Texte';

  @override
  String get hintLogoTextContent => 'Texte du logo';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryCoin => 'Pièce';

  @override
  String get categoryBrand => 'Marque';

  @override
  String get categoryEmoji => 'Emoji';

  @override
  String get msgLogoLoadFailed => 'Impossible de charger l\'icône';

  @override
  String get msgLogoCropFailed => 'Échec du traitement d\'image';

  @override
  String get labelLogoBackgroundColor => 'Couleur';

  @override
  String get actionLogoBackgroundReset => 'Défaut';

  @override
  String get optionRectangle => 'Carré';

  @override
  String get optionRoundedRectangle => 'Cercle';

  @override
  String get labelLogoType => 'Type';

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

  @override
  String get labelEvenSpacing => '균등 분할';
}
