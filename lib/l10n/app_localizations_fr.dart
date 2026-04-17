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
  String get tabColor => 'Couleur';

  @override
  String get tabLogo => 'Logo';

  @override
  String get tabText => 'Texte';

  @override
  String get actionSaveGallery => 'Enregistrer dans la Galerie';

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
  String get actionNoStyle => 'Sans style';

  @override
  String msgTemplateApplied(String name) {
    return 'Modèle « $name » appliqué.';
  }

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
  String get actionRandomRegenerate => 'Regénérer aléatoirement';

  @override
  String get actionRandomEye => 'Œil aléatoire';

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
  String get labelBottomText => 'Texte en bas';

  @override
  String get hintEnterText => 'Saisissez du texte';

  @override
  String get screenSettingsTitle => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Par défaut du système';

  @override
  String msgCopiedToClipboard(String text) {
    return '« $text » copié dans le presse-papiers';
  }

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';
}
