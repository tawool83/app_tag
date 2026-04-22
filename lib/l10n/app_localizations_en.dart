// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QR & NFC Generator';

  @override
  String get screenSplashSubtitle => 'Create and customize your own QR codes';

  @override
  String get tileAppAndroid => 'Launch App';

  @override
  String get tileAppIos => 'Shortcut';

  @override
  String get tileClipboard => 'Clipboard';

  @override
  String get tileWebsite => 'Website';

  @override
  String get tileContact => 'Contact';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => 'Location';

  @override
  String get tileEvent => 'Event';

  @override
  String get tileEmail => 'Email';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'QR & NFC Generator';

  @override
  String get screenHomeEditModeTitle => 'Edit Mode';

  @override
  String get actionDone => 'Done';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String actionDeleteCount(int count) {
    return 'Delete $count';
  }

  @override
  String get actionSave => 'Save';

  @override
  String get actionShare => 'Share';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'OK';

  @override
  String get tooltipHelp => 'Help';

  @override
  String get tooltipHistory => 'History';

  @override
  String get tooltipDeleteAll => 'Delete All';

  @override
  String get actionCollapseHidden => 'Collapse hidden menu';

  @override
  String actionShowHidden(int count) {
    return 'Show hidden menu ($count)';
  }

  @override
  String get screenHelpTitle => 'Help';

  @override
  String get screenHistoryTitle => 'History';

  @override
  String get screenHistoryEmpty => 'No history yet.';

  @override
  String get labelQrCode => 'QR Code';

  @override
  String get labelNfcTag => 'NFC Tag';

  @override
  String get dialogClearAllTitle => 'Delete All';

  @override
  String get dialogClearAllContent =>
      'Are you sure you want to delete all history?';

  @override
  String get dialogDeleteHistoryTitle => 'Delete History';

  @override
  String dialogDeleteHistoryContent(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get screenWebsiteTitle => 'Website Tag';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'Please enter a URL.';

  @override
  String get msgUrlInvalid => 'Please enter a valid URL.';

  @override
  String get screenWifiTitle => 'WiFi Tag';

  @override
  String get labelWifiSsid => 'Network Name (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'Please enter the SSID.';

  @override
  String get labelWifiSecurity => 'Security';

  @override
  String get optionWpa2 => 'WPA2 (Recommended)';

  @override
  String get optionNoSecurity => 'None';

  @override
  String get labelWifiPassword => 'Password';

  @override
  String get hintWifiPassword => 'Password';

  @override
  String get screenSmsTitle => 'SMS Tag';

  @override
  String get labelPhoneRequired => 'Phone Number *';

  @override
  String get hintPhone => '010-0000-0000';

  @override
  String get msgPhoneRequired => 'Please enter a phone number.';

  @override
  String get labelMessageOptional => 'Message (Optional)';

  @override
  String get hintSmsMessage => 'Message content';

  @override
  String get screenEmailTitle => 'Email Tag';

  @override
  String get labelEmailRequired => 'Email Address *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => 'Please enter an email address.';

  @override
  String get msgEmailInvalid => 'Please enter a valid email address.';

  @override
  String get labelEmailSubjectOptional => 'Subject (Optional)';

  @override
  String get hintEmailSubject => 'Email subject';

  @override
  String get labelEmailBodyOptional => 'Body (Optional)';

  @override
  String get hintEmailBody => 'Email body';

  @override
  String get screenContactTitle => 'Contact Tag';

  @override
  String get actionManualInput => 'Manual Input';

  @override
  String get screenContactManualSubtitle =>
      'Enter name, phone number, and email manually';

  @override
  String get hintSearchByName => 'Search by name';

  @override
  String get labelNoPhone => 'No phone number';

  @override
  String get msgContactPermissionRequired =>
      'Contact access permission is required';

  @override
  String get msgContactPermissionHint =>
      'Use manual input or allow permission in settings.';

  @override
  String get actionOpenSettings => 'Open Settings';

  @override
  String get msgSearchNoResults => 'No search results.';

  @override
  String get msgNoContacts => 'No saved contacts.';

  @override
  String get screenContactManualTitle => 'Manual Input';

  @override
  String get labelNameRequired => 'Name *';

  @override
  String get hintName => 'John Doe';

  @override
  String get msgNameRequired => 'Please enter a name.';

  @override
  String get labelPhone => 'Phone';

  @override
  String get labelEmail => 'Email';

  @override
  String get screenLocationTitle => 'Location Tag';

  @override
  String get screenLocationTapHint => 'Tap the map to select a location.';

  @override
  String get msgSearchingAddress => 'Searching address...';

  @override
  String get msgAddressUnavailable => 'Unable to retrieve address.';

  @override
  String get labelPlaceNameOptional => 'Place Name (Optional)';

  @override
  String get hintPlaceName =>
      'Leave empty to use the building name automatically.';

  @override
  String get msgSelectLocation => 'Please select a location on the map.';

  @override
  String get screenEventTitle => 'Event Tag';

  @override
  String get labelEventTitleRequired => 'Event Title *';

  @override
  String get hintEventTitle => 'Event title';

  @override
  String get msgEventTitleRequired => 'Please enter a title.';

  @override
  String get labelEventStart => 'Start';

  @override
  String get labelEventEnd => 'End';

  @override
  String get labelEventLocationOptional => 'Location/Address (Optional)';

  @override
  String get hintEventLocation => '123 Main St...';

  @override
  String get labelEventDescOptional => 'Description (Optional)';

  @override
  String get hintEventDesc => 'Event description';

  @override
  String get msgEventEndBeforeStart => 'End time must be after start time.';

  @override
  String get screenClipboardTitle => 'Clipboard Tag';

  @override
  String get msgClipboardEmpty => 'Clipboard is empty. Enter text manually.';

  @override
  String get labelContent => 'Content';

  @override
  String get hintClipboardText => 'Text to save to tag';

  @override
  String get msgContentRequired => 'Please enter content.';

  @override
  String get screenIosInputTitle => 'iOS App Launch Setup';

  @override
  String get labelShortcutName => 'Shortcut name of the app to launch';

  @override
  String get hintShortcutName => 'e.g.: MyApp';

  @override
  String get msgAppNameRequired => 'Please enter an app name.';

  @override
  String get screenIosInputGuideTitle => 'Shortcut Setup Guide';

  @override
  String get screenIosInputGuideSteps =>
      '1. Open the Shortcuts app on your iPhone\n2. Create a shortcut that opens the desired app\n3. Save the shortcut with the name entered above\n4. Press the button below to generate QR/NFC';

  @override
  String get actionAppleShortcutsGuide => 'Apple Shortcuts Official Guide';

  @override
  String get screenAppPickerTitle => 'Select App';

  @override
  String get hintAppSearch => 'Search apps...';

  @override
  String get msgAppListError => 'Unable to load app list.';

  @override
  String get msgSelectApp => 'Please select an app.';

  @override
  String get screenNfcWriterTitle => 'NFC Write';

  @override
  String get msgNfcWaiting => 'Hold the NFC tag near the\nback of your phone';

  @override
  String get msgNfcSuccess => 'Write complete!\nReturning to home...';

  @override
  String get msgNfcError => 'NFC write failed.';

  @override
  String get labelNfcIncludeIos => 'Also write iOS shortcut';

  @override
  String get labelIosShortcutName => 'iOS Shortcut Name';

  @override
  String get hintIosShortcutName => 'e.g.: KakaoTalk';

  @override
  String get screenOutputSelectorTitle => 'Select Output Method';

  @override
  String get screenOutputQrDesc => 'Scan with camera to launch app';

  @override
  String get screenOutputNfcDesc => 'Tap tag to launch app';

  @override
  String get msgNfcCheckFailed => 'NFC check failed';

  @override
  String get msgNfcSimulator => 'Cannot test NFC on simulator';

  @override
  String get msgNfcNotSupported => 'This device does not support NFC';

  @override
  String get msgNfcWriteIosMin => 'NFC writing requires iPhone XS or later';

  @override
  String get msgNfcUnsupportedDevice => 'NFC unsupported device';

  @override
  String get actionNfcWrite => 'Write NFC Tag';

  @override
  String get screenQrResultTitle => 'QR Code';

  @override
  String get tabTemplate => 'Template';

  @override
  String get tabShape => 'Shape';

  @override
  String get tabColor => 'Color';

  @override
  String get tabLogo => 'Logo';

  @override
  String get tabText => 'Text';

  @override
  String get actionSaveGallery => 'Save to Gallery';

  @override
  String get actionSaveTemplate => 'Save Template';

  @override
  String get dialogLowReadabilityTitle => 'Low Readability';

  @override
  String dialogLowReadabilityScore(int score) {
    return 'Current readability: $score%';
  }

  @override
  String get dialogLowReadabilityWarning =>
      'The QR code may not be recognized\nby some scanners.';

  @override
  String dialogLowReadabilityCause(String issue) {
    return 'Main cause: $issue';
  }

  @override
  String get actionSaveAnyway => 'Save Anyway';

  @override
  String get dialogSaveTemplateTitle => 'Save Template';

  @override
  String get labelTemplateName => 'Template Name';

  @override
  String get hintTemplateName => 'e.g.: Blue Background QR';

  @override
  String msgTemplateSaved(String name) {
    return 'Template \"$name\" has been saved.';
  }

  @override
  String get msgSaveFailed => 'Failed to save image.';

  @override
  String get msgPrintFailed =>
      'Print failed. Please check the printer connection.';

  @override
  String get labelReadability => 'Readability';

  @override
  String get screenTemplateMyTemplates => 'My Templates';

  @override
  String get actionNoStyle => 'No Style';

  @override
  String msgTemplateApplied(String name) {
    return 'Template \"$name\" has been applied.';
  }

  @override
  String get dialogDeleteTemplateTitle => 'Delete Template';

  @override
  String dialogDeleteTemplateContent(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get msgNoSavedTemplates => 'No saved templates.';

  @override
  String get msgNoSavedTemplatesHint =>
      'Save your current style using the [Save Template] button below.';

  @override
  String get tabColorSolid => 'Solid';

  @override
  String get tabColorGradient => 'Gradient';

  @override
  String get actionPickColor => 'Pick Color';

  @override
  String get labelRecommendedColors => 'Recommended Colors';

  @override
  String get labelGradientPresets => 'Gradient Presets';

  @override
  String get dialogColorPickerTitle => 'Pick a Color';

  @override
  String get labelDotShape => 'Dot Shape';

  @override
  String get labelEyeOuter => 'Eye Shape — Outer';

  @override
  String get labelEyeInner => 'Eye Shape — Inner';

  @override
  String get shapeSquare => 'Square';

  @override
  String get shapeRounded => 'Rounded';

  @override
  String get shapeCircle => 'Circle';

  @override
  String get shapeCircleRound => 'Circle Donut';

  @override
  String get shapeSmooth => 'Smooth';

  @override
  String get shapeDiamond => 'Diamond';

  @override
  String get shapeStar => 'Star';

  @override
  String get actionClear => 'Clear';

  @override
  String get labelShowIcon => 'Show Icon';

  @override
  String get msgIconUnavailable =>
      'Only displayed when an app icon or emoji is set.';

  @override
  String get labelLogoPosition => 'Logo Position';

  @override
  String get optionCenter => 'Center';

  @override
  String get optionBottomRight => 'Bottom Right';

  @override
  String get labelLogoBackground => 'Logo Background';

  @override
  String get optionNone => 'None';

  @override
  String get optionSquare => 'Square';

  @override
  String get optionCircle => 'Circle';

  @override
  String get labelTopText => 'Top Text';

  @override
  String get labelBottomText => 'Bottom Text';

  @override
  String get hintEnterText => 'Enter text';

  @override
  String get screenSettingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System Default';

  @override
  String msgCopiedToClipboard(String text) {
    return '\"$text\" copied to clipboard';
  }

  @override
  String get settingsReadabilityAlert => 'Readability alert';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';

  @override
  String get labelCustomGradient => 'Custom Gradient';

  @override
  String get labelGradientType => 'Type';

  @override
  String get optionLinear => 'Linear';

  @override
  String get optionRadial => 'Radial';

  @override
  String get labelAngle => 'Angle';

  @override
  String get labelCenter => 'Center';

  @override
  String get optionCenterCenter => 'Center';

  @override
  String get optionCenterTopLeft => 'Top Left';

  @override
  String get optionCenterTopRight => 'Top Right';

  @override
  String get optionCenterBottomLeft => 'Bottom Left';

  @override
  String get optionCenterBottomRight => 'Bottom Right';

  @override
  String get labelColorStops => 'Color Stops';

  @override
  String get actionAddStop => 'Add';

  @override
  String get actionDeleteStop => 'Delete';

  @override
  String get loginTitle => 'Log In';

  @override
  String get signupTitle => 'Sign Up';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get loginWithEmail => 'Log in with Email';

  @override
  String get useWithoutLogin => 'Use without logging in';

  @override
  String get orDivider => 'or';

  @override
  String get noAccountYet => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get nickname => 'Nickname';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordConfirm => 'Confirm Password';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get nicknameRequired => 'Please enter a nickname';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get loginMethod => 'Login Method';

  @override
  String get joinDate => 'Joined';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get synced => 'Synced';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncError => 'Sync Failed';

  @override
  String get lastSynced => 'Last Synced';

  @override
  String get justNow => 'Just now';

  @override
  String get manualSync => 'Sync Now';

  @override
  String get logout => 'Log Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? All cloud data will be permanently deleted.';

  @override
  String get logoutConfirm =>
      'Are you sure you want to log out? Local data will be kept.';

  @override
  String get accountSection => 'Account';

  @override
  String get syncSection => 'Sync';

  @override
  String get loginPrompt => 'Log In';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get cancel => 'Cancel';

  @override
  String get labelSavePreset => 'Save Preset';

  @override
  String get hintPresetName => 'Preset name';

  @override
  String get labelBoundaryShape => 'QR Outline Shape';

  @override
  String get labelAnimation => 'Animation';

  @override
  String get labelCustomDot => 'Custom Dot';

  @override
  String get labelCustomEye => 'Custom Eye';

  @override
  String get labelCustomBoundary => 'Custom Outline';

  @override
  String get labelCustomAnimation => 'Custom Animation';

  @override
  String get actionApply => 'Apply';

  @override
  String get sliderVertices => 'Vertices';

  @override
  String get sliderInnerRadius => 'Inner Radius';

  @override
  String get sliderRoundness => 'Roundness';

  @override
  String get sliderRotation => 'Rotation';

  @override
  String get sliderDotScale => 'Size';

  @override
  String get labelSymmetric => 'Symmetric';

  @override
  String get labelAsymmetric => 'Asymmetric';

  @override
  String get sliderSfM => 'Symmetry (m)';

  @override
  String get sliderSfN1 => 'Curvature 1';

  @override
  String get sliderSfN2 => 'Curvature 2';

  @override
  String get sliderSfN3 => 'Curvature 3';

  @override
  String get sliderSfA => 'X Scale';

  @override
  String get sliderSfB => 'Y Scale';

  @override
  String get sliderOuterN => 'Outer Shape';

  @override
  String get sliderInnerN => 'Inner Shape';

  @override
  String get sliderCornerQ1 => 'Q1 모서리';

  @override
  String get sliderCornerQ2 => 'Q2 모서리';

  @override
  String get sliderCornerQ3 => 'Q3 모서리';

  @override
  String get sliderCornerQ4 => 'Q4 모서리';

  @override
  String get labelBoundaryType => 'Outline Type';

  @override
  String get sliderSuperellipseN => 'Shape N';

  @override
  String get sliderStarVertices => 'Star Points';

  @override
  String get sliderStarInnerRadius => 'Star Depth';

  @override
  String get sliderPadding => 'Padding';

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
  String get sliderSpeed => 'Speed';

  @override
  String get sliderAmplitude => 'Amplitude';

  @override
  String get sliderFrequency => 'Frequency';

  @override
  String get optionLogoTypeLogo => 'Logo';

  @override
  String get optionLogoTypeImage => 'Image';

  @override
  String get optionLogoTypeText => 'Text';

  @override
  String get labelLogoTabPosition => 'Position';

  @override
  String get labelLogoTabBackground => 'Background';

  @override
  String get labelLogoCategory => 'Category';

  @override
  String get labelLogoGallery => 'Choose from gallery';

  @override
  String get labelLogoRecrop => 'Re-crop';

  @override
  String get labelLogoTextContent => 'Text';

  @override
  String get hintLogoTextContent => 'Text for logo';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryCoin => 'Coin';

  @override
  String get categoryBrand => 'Brand';

  @override
  String get categoryEmoji => 'Emoji';

  @override
  String get msgLogoLoadFailed => 'Failed to load icon';

  @override
  String get msgLogoCropFailed => 'Failed to process image';

  @override
  String get labelLogoBackgroundColor => 'Color';

  @override
  String get actionLogoBackgroundReset => 'Default';

  @override
  String get optionRectangle => 'Square';

  @override
  String get optionRoundedRectangle => 'Circle';

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
}
