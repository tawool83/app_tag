// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'QR, NFC 생성기';

  @override
  String get screenSplashSubtitle => '자신만의 QR 을 만들고 꾸미세요';

  @override
  String get tileAppAndroid => '앱 실행';

  @override
  String get tileAppIos => '단축어';

  @override
  String get tileClipboard => '클립보드';

  @override
  String get tileWebsite => '웹 사이트';

  @override
  String get tileContact => '연락처';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => '위치';

  @override
  String get tileEvent => '이벤트/일정';

  @override
  String get tileEmail => '이메일';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'QR, NFC 생성기';

  @override
  String get screenHomeEditModeTitle => '편집 모드';

  @override
  String get actionDone => '완료';

  @override
  String get actionCancel => '취소';

  @override
  String get actionDelete => '삭제';

  @override
  String get actionEdit => '편집';

  @override
  String actionDeleteCount(int count) {
    return '$count개 삭제';
  }

  @override
  String get actionSave => '저장';

  @override
  String get actionShare => '공유';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get actionClose => '닫기';

  @override
  String get actionConfirm => '확인';

  @override
  String get tooltipHelp => '사용 안내';

  @override
  String get tooltipHistory => '생성 이력';

  @override
  String get tooltipDeleteAll => '전체 삭제';

  @override
  String get actionCollapseHidden => '숨긴 메뉴 접기';

  @override
  String actionShowHidden(int count) {
    return '숨긴 메뉴 보기 ($count)';
  }

  @override
  String get screenHelpTitle => '사용 안내';

  @override
  String get screenHistoryTitle => '생성 이력';

  @override
  String get screenHistoryEmpty => '이력이 없습니다.';

  @override
  String get labelQrCode => 'QR 코드';

  @override
  String get labelNfcTag => 'NFC 태그';

  @override
  String get dialogClearAllTitle => '전체 삭제';

  @override
  String get dialogClearAllContent => '모든 이력을 삭제하시겠습니까?';

  @override
  String get dialogDeleteHistoryTitle => '이력 삭제';

  @override
  String dialogDeleteHistoryContent(String name) {
    return '\"$name\" 이력을 삭제하시겠습니까?';
  }

  @override
  String get screenWebsiteTitle => '웹 사이트 태그';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'URL을 입력해주세요.';

  @override
  String get msgUrlInvalid => '올바른 URL 형식으로 입력해주세요.';

  @override
  String get screenWifiTitle => 'WiFi 태그';

  @override
  String get labelWifiSsid => '네트워크 이름 (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'SSID를 입력해주세요.';

  @override
  String get labelWifiSecurity => '보안 방식';

  @override
  String get optionWpa2 => 'WPA2 (권장)';

  @override
  String get optionNoSecurity => '없음';

  @override
  String get labelWifiPassword => '비밀번호';

  @override
  String get hintWifiPassword => '비밀번호';

  @override
  String get screenSmsTitle => 'SMS 태그';

  @override
  String get labelPhoneRequired => '전화번호 *';

  @override
  String get hintPhone => '010-0000-0000';

  @override
  String get msgPhoneRequired => '전화번호를 입력해주세요.';

  @override
  String get labelMessageOptional => '메시지 (선택)';

  @override
  String get hintSmsMessage => '문자 내용';

  @override
  String get screenEmailTitle => '이메일 태그';

  @override
  String get labelEmailRequired => '이메일 주소 *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => '이메일 주소를 입력해주세요.';

  @override
  String get msgEmailInvalid => '올바른 이메일 형식으로 입력해주세요.';

  @override
  String get labelEmailSubjectOptional => '제목 (선택)';

  @override
  String get hintEmailSubject => '이메일 제목';

  @override
  String get labelEmailBodyOptional => '내용 (선택)';

  @override
  String get hintEmailBody => '이메일 본문';

  @override
  String get screenContactTitle => '연락처 태그';

  @override
  String get actionManualInput => '직접 입력';

  @override
  String get screenContactManualSubtitle => '이름, 전화번호, 이메일을 직접 입력합니다';

  @override
  String get hintSearchByName => '이름으로 검색';

  @override
  String get labelNoPhone => '전화번호 없음';

  @override
  String get msgContactPermissionRequired => '연락처 접근 권한이 필요합니다';

  @override
  String get msgContactPermissionHint => '직접 입력을 사용하거나 설정에서 권한을 허용해주세요.';

  @override
  String get actionOpenSettings => '설정 열기';

  @override
  String get msgSearchNoResults => '검색 결과가 없습니다.';

  @override
  String get msgNoContacts => '저장된 연락처가 없습니다.';

  @override
  String get screenContactManualTitle => '직접 입력';

  @override
  String get labelNameRequired => '이름 *';

  @override
  String get hintName => '홍길동';

  @override
  String get msgNameRequired => '이름을 입력해주세요.';

  @override
  String get labelPhone => '전화번호';

  @override
  String get labelEmail => '이메일';

  @override
  String get screenLocationTitle => '위치 태그';

  @override
  String get screenLocationTapHint => '지도를 탭하여 위치를 선택하세요.';

  @override
  String get msgSearchingAddress => '주소 검색 중...';

  @override
  String get msgAddressUnavailable => '주소를 가져올 수 없습니다.';

  @override
  String get labelPlaceNameOptional => '장소명 (선택)';

  @override
  String get hintPlaceName => '비우면 건물명이 자동으로 사용됩니다.';

  @override
  String get msgSelectLocation => '지도에서 위치를 선택해주세요.';

  @override
  String get screenEventTitle => '이벤트/일정 태그';

  @override
  String get labelEventTitleRequired => '이벤트 제목 *';

  @override
  String get hintEventTitle => '이벤트 제목';

  @override
  String get msgEventTitleRequired => '제목을 입력해주세요.';

  @override
  String get labelEventStart => '시작';

  @override
  String get labelEventEnd => '종료';

  @override
  String get labelEventLocationOptional => '장소/주소 (선택)';

  @override
  String get hintEventLocation => '서울특별시 중구 ...';

  @override
  String get labelEventDescOptional => '설명 (선택)';

  @override
  String get hintEventDesc => '이벤트 설명';

  @override
  String get msgEventEndBeforeStart => '종료 일시는 시작 일시 이후여야 합니다.';

  @override
  String get screenClipboardTitle => '클립보드 태그';

  @override
  String get msgClipboardEmpty => '클립보드가 비어 있습니다. 직접 입력하세요.';

  @override
  String get labelContent => '내용';

  @override
  String get hintClipboardText => '태그에 저장할 텍스트';

  @override
  String get msgContentRequired => '내용을 입력해주세요.';

  @override
  String get screenIosInputTitle => 'iOS 앱 실행 설정';

  @override
  String get labelShortcutName => '실행할 앱의 단축어 이름';

  @override
  String get hintShortcutName => '예: 내냉장고';

  @override
  String get msgAppNameRequired => '앱 이름을 입력해주세요.';

  @override
  String get screenIosInputGuideTitle => '단축어 설정 안내';

  @override
  String get screenIosInputGuideSteps =>
      '1. iPhone의 단축어(Shortcuts) 앱을 열기\n2. 실행하려는 앱을 여는 단축어 만들기\n3. 단축어 이름을 위에 입력한 이름으로 저장\n4. 아래 버튼을 눌러 QR/NFC 생성';

  @override
  String get actionAppleShortcutsGuide => 'Apple 단축어 공식 사용 설명서';

  @override
  String get screenAppPickerTitle => '앱 선택';

  @override
  String get hintAppSearch => '앱 검색...';

  @override
  String get msgAppListError => '앱 목록을 불러올 수 없습니다.';

  @override
  String get msgSelectApp => '앱을 선택해주세요.';

  @override
  String get screenNfcWriterTitle => 'NFC 기록';

  @override
  String get msgNfcWaiting => 'NFC 태그를 스마트폰 뒷면에\n가져다 대세요';

  @override
  String get msgNfcSuccess => '기록 완료!\n홈으로 이동합니다...';

  @override
  String get msgNfcError => 'NFC 기록에 실패했습니다.';

  @override
  String get labelNfcIncludeIos => 'iOS 단축어도 함께 기록';

  @override
  String get labelIosShortcutName => 'iOS 단축어 이름';

  @override
  String get hintIosShortcutName => '예: 카카오톡';

  @override
  String get screenOutputSelectorTitle => '출력 방식 선택';

  @override
  String get screenOutputQrDesc => '카메라로 스캔하여 앱 실행';

  @override
  String get screenOutputNfcDesc => '태그에 가져다 대어 앱 실행';

  @override
  String get msgNfcCheckFailed => 'NFC 확인 실패';

  @override
  String get msgNfcSimulator => '시뮬레이터에서는 NFC를 테스트할 수 없습니다';

  @override
  String get msgNfcNotSupported => '이 기기는 NFC를 지원하지 않습니다';

  @override
  String get msgNfcWriteIosMin => 'NFC 쓰기는 iPhone XS 이상에서 지원됩니다';

  @override
  String get msgNfcUnsupportedDevice => 'NFC 미지원 기기';

  @override
  String get actionNfcWrite => 'NFC 태그 쓰기';

  @override
  String get screenQrResultTitle => 'QR 코드';

  @override
  String get tabTemplate => '템플릿';

  @override
  String get tabShape => '모양';

  @override
  String get tabColor => '색상';

  @override
  String get tabLogo => '로고';

  @override
  String get tabText => '텍스트';

  @override
  String get actionSaveGallery => '갤러리 저장';

  @override
  String get actionSaveTemplate => '템플릿 저장';

  @override
  String get dialogLowReadabilityTitle => '인식률이 낮습니다';

  @override
  String dialogLowReadabilityScore(int score) {
    return '현재 인식률: $score%';
  }

  @override
  String get dialogLowReadabilityWarning => 'QR 코드가 일부 스캐너에서\n인식되지 않을 수 있습니다.';

  @override
  String dialogLowReadabilityCause(String issue) {
    return '주요 원인: $issue';
  }

  @override
  String get actionSaveAnyway => '그래도 저장';

  @override
  String get dialogSaveTemplateTitle => '템플릿 저장';

  @override
  String get labelTemplateName => '템플릿 이름';

  @override
  String get hintTemplateName => '예: 파란 배경 QR';

  @override
  String msgTemplateSaved(String name) {
    return '「$name」 템플릿이 저장되었습니다.';
  }

  @override
  String get msgSaveFailed => '이미지 저장에 실패했습니다.';

  @override
  String get msgPrintFailed => '인쇄에 실패했습니다. 프린터 연결을 확인해주세요.';

  @override
  String get labelReadability => '인식률';

  @override
  String get screenTemplateMyTemplates => '나의 템플릿';

  @override
  String get actionNoStyle => '스타일 없음';

  @override
  String msgTemplateApplied(String name) {
    return '「$name」 템플릿이 적용되었습니다.';
  }

  @override
  String get dialogDeleteTemplateTitle => '템플릿 삭제';

  @override
  String dialogDeleteTemplateContent(String name) {
    return '「$name」을(를) 삭제하시겠습니까?';
  }

  @override
  String get msgNoSavedTemplates => '저장된 템플릿이 없습니다.';

  @override
  String get msgNoSavedTemplatesHint => '하단 [템플릿 저장] 버튼으로 현재 스타일을 저장하세요.';

  @override
  String get tabColorSolid => '단색';

  @override
  String get tabColorGradient => '그라디언트';

  @override
  String get actionPickColor => '직접 선택';

  @override
  String get labelRecommendedColors => '추천 색상';

  @override
  String get labelGradientPresets => '그라디언트 프리셋';

  @override
  String get dialogColorPickerTitle => '색상 선택';

  @override
  String get labelDotShape => '도트 모양';

  @override
  String get labelEyeOuter => '눈 모양 — 외곽';

  @override
  String get labelEyeInner => '눈 모양 — 내부';

  @override
  String get shapeSquare => '사각';

  @override
  String get shapeRounded => '둥글기';

  @override
  String get shapeCircle => '원형';

  @override
  String get shapeCircleRound => '원형도넛';

  @override
  String get shapeSmooth => '부드럽게';

  @override
  String get shapeDiamond => '다이아';

  @override
  String get shapeStar => '별';

  @override
  String get actionClear => '해제';

  @override
  String get labelShowIcon => '아이콘 표시';

  @override
  String get msgIconUnavailable => '앱 아이콘 또는 이모지가 설정된 경우에만 표시됩니다.';

  @override
  String get labelLogoPosition => '로고 위치';

  @override
  String get optionCenter => '중앙';

  @override
  String get optionBottomRight => '우하단';

  @override
  String get labelLogoBackground => '로고 배경';

  @override
  String get optionNone => '없음';

  @override
  String get optionSquare => '사각';

  @override
  String get optionCircle => '원형';

  @override
  String get labelTopText => '상단 텍스트';

  @override
  String get labelBottomText => '하단 텍스트';

  @override
  String get hintEnterText => '텍스트를 입력하세요';

  @override
  String get screenSettingsTitle => '설정';

  @override
  String get drawerAppInfo => '프로그램 정보';

  @override
  String get appInfoBuild => '빌드';

  @override
  String get appInfoTemplateEngine => '템플릿 엔진';

  @override
  String get appInfoTemplateSchema => '템플릿 스키마';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSystem => '시스템 기본';

  @override
  String msgCopiedToClipboard(String text) {
    return '\"$text\" 클립보드에 복사됨';
  }

  @override
  String get settingsReadabilityAlert => '인식률 알림 사용';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';

  @override
  String get labelCustomGradient => '맞춤 그라디언트';

  @override
  String get labelGradientType => '유형';

  @override
  String get optionLinear => '선형';

  @override
  String get optionRadial => '방사형';

  @override
  String get labelAngle => '각도';

  @override
  String get labelCenter => '가운데';

  @override
  String get optionCenterCenter => '중앙';

  @override
  String get optionCenterTopLeft => '왼쪽 상단';

  @override
  String get optionCenterTopRight => '오른쪽 상단';

  @override
  String get optionCenterBottomLeft => '왼쪽 하단';

  @override
  String get optionCenterBottomRight => '오른쪽 하단';

  @override
  String get labelColorStops => '색 지점';

  @override
  String get actionAddStop => '추가';

  @override
  String get actionDeleteStop => '삭제';

  @override
  String get loginTitle => '로그인';

  @override
  String get signupTitle => '회원가입';

  @override
  String get continueWithGoogle => 'Google로 계속하기';

  @override
  String get continueWithApple => 'Apple로 계속하기';

  @override
  String get loginWithEmail => '이메일로 로그인';

  @override
  String get useWithoutLogin => '로그인 없이 사용하기';

  @override
  String get orDivider => '또는';

  @override
  String get noAccountYet => '계정이 없으신가요?';

  @override
  String get signUp => '가입';

  @override
  String get nickname => '닉네임';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get passwordConfirm => '비밀번호 확인';

  @override
  String get passwordMinLength => '비밀번호는 8자 이상이어야 합니다';

  @override
  String get passwordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get invalidEmail => '올바른 이메일을 입력해주세요';

  @override
  String get nicknameRequired => '닉네임을 입력해주세요';

  @override
  String get profileTitle => '내 프로필';

  @override
  String get changePhoto => '사진 변경';

  @override
  String get loginMethod => '로그인 방법';

  @override
  String get joinDate => '가입일';

  @override
  String get syncStatus => '동기화 상태';

  @override
  String get synced => '동기화됨';

  @override
  String get syncing => '동기화 중...';

  @override
  String get syncError => '동기화 실패';

  @override
  String get lastSynced => '마지막 동기화';

  @override
  String get justNow => '방금 전';

  @override
  String get manualSync => '수동 동기화';

  @override
  String get logout => '로그아웃';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountConfirm => '정말 계정을 삭제하시겠습니까? 클라우드 데이터가 모두 삭제됩니다.';

  @override
  String get logoutConfirm => '로그아웃하시겠습니까? 로컬 데이터는 유지됩니다.';

  @override
  String get accountSection => '계정';

  @override
  String get syncSection => '동기화';

  @override
  String get loginPrompt => '로그인하기';

  @override
  String get cloudSync => '클라우드 동기화';

  @override
  String get cancel => '취소';

  @override
  String get labelSavePreset => '프리셋 저장';

  @override
  String get hintPresetName => '프리셋 이름';

  @override
  String get labelBoundaryShape => 'QR 전체 외곽';

  @override
  String get labelAnimation => '애니메이션';

  @override
  String get labelCustomDot => '맞춤 도트';

  @override
  String get labelCustomEye => '맞춤 눈';

  @override
  String get labelCustomBoundary => '맞춤 외곽';

  @override
  String get labelCustomAnimation => '맞춤 애니메이션';

  @override
  String get actionApply => '적용';

  @override
  String get sliderVertices => '꼭짓점';

  @override
  String get sliderInnerRadius => '내부 반경';

  @override
  String get sliderRoundness => '둥글기';

  @override
  String get sliderRotation => '회전';

  @override
  String get sliderDotScale => '크기';

  @override
  String get labelSymmetric => '대칭';

  @override
  String get labelAsymmetric => '비대칭';

  @override
  String get sliderSfM => '대칭 차수 (m)';

  @override
  String get sliderSfN1 => '곡률 1';

  @override
  String get sliderSfN2 => '곡률 2';

  @override
  String get sliderSfN3 => '곡률 3';

  @override
  String get sliderSfA => 'X 비율';

  @override
  String get sliderSfB => 'Y 비율';

  @override
  String get sliderOuterN => '외곽 형태';

  @override
  String get sliderInnerN => '내부 형태';

  @override
  String get sliderCornerQ1 => 'Q1 모서리';

  @override
  String get sliderCornerQ2 => 'Q2 모서리';

  @override
  String get sliderCornerQ3 => 'Q3 모서리';

  @override
  String get sliderCornerQ4 => 'Q4 모서리';

  @override
  String get labelBoundaryType => '외곽 종류';

  @override
  String get sliderSuperellipseN => '형태 N값';

  @override
  String get sliderStarVertices => '별 꼭짓점';

  @override
  String get sliderStarInnerRadius => '별 깊이';

  @override
  String get sliderPadding => '패딩';

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
  String get sliderSpeed => '속도';

  @override
  String get sliderAmplitude => '강도';

  @override
  String get sliderFrequency => '빈도';

  @override
  String get optionLogoTypeLogo => '로고';

  @override
  String get optionLogoTypeImage => '이미지';

  @override
  String get optionLogoTypeText => '텍스트';

  @override
  String get labelLogoTabPosition => '위치';

  @override
  String get labelLogoTabBackground => '배경';

  @override
  String get labelLogoCategory => '카테고리';

  @override
  String get labelLogoGallery => '갤러리에서 선택';

  @override
  String get labelLogoRecrop => '다시 자르기';

  @override
  String get labelLogoTextContent => '문구';

  @override
  String get hintLogoTextContent => '로고에 넣을 글자';

  @override
  String get categorySocial => '소셜';

  @override
  String get categoryCoin => '코인';

  @override
  String get categoryBrand => '브랜드';

  @override
  String get categoryEmoji => '이모지';

  @override
  String get msgLogoLoadFailed => '아이콘을 불러올 수 없습니다';

  @override
  String get msgLogoCropFailed => '이미지 처리에 실패했습니다';

  @override
  String get labelLogoBackgroundColor => '색상';

  @override
  String get actionLogoBackgroundReset => '기본값';

  @override
  String get optionRectangle => '사각';

  @override
  String get optionRoundedRectangle => '원형';

  @override
  String get labelLogoType => '유형';

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
