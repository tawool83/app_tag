import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'QR, NFC 생성기'**
  String get appTitle;

  /// No description provided for @screenSplashSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'자신만의 QR 을 만들고 꾸미세요'**
  String get screenSplashSubtitle;

  /// No description provided for @tileAppAndroid.
  ///
  /// In ko, this message translates to:
  /// **'앱 실행'**
  String get tileAppAndroid;

  /// No description provided for @tileAppIos.
  ///
  /// In ko, this message translates to:
  /// **'단축어'**
  String get tileAppIos;

  /// No description provided for @tileClipboard.
  ///
  /// In ko, this message translates to:
  /// **'클립보드'**
  String get tileClipboard;

  /// No description provided for @tileWebsite.
  ///
  /// In ko, this message translates to:
  /// **'웹 사이트'**
  String get tileWebsite;

  /// No description provided for @tileContact.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get tileContact;

  /// No description provided for @tileWifi.
  ///
  /// In ko, this message translates to:
  /// **'WiFi'**
  String get tileWifi;

  /// No description provided for @tileLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get tileLocation;

  /// No description provided for @tileEvent.
  ///
  /// In ko, this message translates to:
  /// **'이벤트/일정'**
  String get tileEvent;

  /// No description provided for @tileEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get tileEmail;

  /// No description provided for @tileSms.
  ///
  /// In ko, this message translates to:
  /// **'SMS'**
  String get tileSms;

  /// No description provided for @screenHomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'QR, NFC 생성기'**
  String get screenHomeTitle;

  /// No description provided for @screenHomeEditModeTitle.
  ///
  /// In ko, this message translates to:
  /// **'편집 모드'**
  String get screenHomeEditModeTitle;

  /// No description provided for @actionDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get actionDone;

  /// No description provided for @actionCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get actionEdit;

  /// No description provided for @actionDeleteCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 삭제'**
  String actionDeleteCount(int count);

  /// No description provided for @actionSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get actionSave;

  /// No description provided for @actionShare.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get actionShare;

  /// No description provided for @actionRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get actionRetry;

  /// No description provided for @actionClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get actionConfirm;

  /// No description provided for @tooltipHelp.
  ///
  /// In ko, this message translates to:
  /// **'사용 안내'**
  String get tooltipHelp;

  /// No description provided for @tooltipHistory.
  ///
  /// In ko, this message translates to:
  /// **'생성 이력'**
  String get tooltipHistory;

  /// No description provided for @tooltipDeleteAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get tooltipDeleteAll;

  /// No description provided for @actionCollapseHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 메뉴 접기'**
  String get actionCollapseHidden;

  /// No description provided for @actionShowHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 메뉴 보기 ({count})'**
  String actionShowHidden(int count);

  /// No description provided for @screenHelpTitle.
  ///
  /// In ko, this message translates to:
  /// **'사용 안내'**
  String get screenHelpTitle;

  /// No description provided for @screenHistoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'생성 이력'**
  String get screenHistoryTitle;

  /// No description provided for @screenHistoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이력이 없습니다.'**
  String get screenHistoryEmpty;

  /// No description provided for @labelQrCode.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드'**
  String get labelQrCode;

  /// No description provided for @labelNfcTag.
  ///
  /// In ko, this message translates to:
  /// **'NFC 태그'**
  String get labelNfcTag;

  /// No description provided for @dialogClearAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get dialogClearAllTitle;

  /// No description provided for @dialogClearAllContent.
  ///
  /// In ko, this message translates to:
  /// **'모든 이력을 삭제하시겠습니까?'**
  String get dialogClearAllContent;

  /// No description provided for @dialogDeleteHistoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'이력 삭제'**
  String get dialogDeleteHistoryTitle;

  /// No description provided for @dialogDeleteHistoryContent.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 이력을 삭제하시겠습니까?'**
  String dialogDeleteHistoryContent(String name);

  /// No description provided for @screenWebsiteTitle.
  ///
  /// In ko, this message translates to:
  /// **'웹 사이트 태그'**
  String get screenWebsiteTitle;

  /// No description provided for @labelUrl.
  ///
  /// In ko, this message translates to:
  /// **'URL'**
  String get labelUrl;

  /// No description provided for @hintUrl.
  ///
  /// In ko, this message translates to:
  /// **'https://example.com'**
  String get hintUrl;

  /// No description provided for @msgUrlRequired.
  ///
  /// In ko, this message translates to:
  /// **'URL을 입력해주세요.'**
  String get msgUrlRequired;

  /// No description provided for @msgUrlInvalid.
  ///
  /// In ko, this message translates to:
  /// **'올바른 URL 형식으로 입력해주세요.'**
  String get msgUrlInvalid;

  /// No description provided for @screenWifiTitle.
  ///
  /// In ko, this message translates to:
  /// **'WiFi 태그'**
  String get screenWifiTitle;

  /// No description provided for @labelWifiSsid.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 이름 (SSID) *'**
  String get labelWifiSsid;

  /// No description provided for @hintWifiSsid.
  ///
  /// In ko, this message translates to:
  /// **'MyWiFi'**
  String get hintWifiSsid;

  /// No description provided for @msgSsidRequired.
  ///
  /// In ko, this message translates to:
  /// **'SSID를 입력해주세요.'**
  String get msgSsidRequired;

  /// No description provided for @labelWifiSecurity.
  ///
  /// In ko, this message translates to:
  /// **'보안 방식'**
  String get labelWifiSecurity;

  /// No description provided for @optionWpa2.
  ///
  /// In ko, this message translates to:
  /// **'WPA2 (권장)'**
  String get optionWpa2;

  /// No description provided for @optionNoSecurity.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get optionNoSecurity;

  /// No description provided for @labelWifiPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get labelWifiPassword;

  /// No description provided for @hintWifiPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get hintWifiPassword;

  /// No description provided for @screenSmsTitle.
  ///
  /// In ko, this message translates to:
  /// **'SMS 태그'**
  String get screenSmsTitle;

  /// No description provided for @labelPhoneRequired.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 *'**
  String get labelPhoneRequired;

  /// No description provided for @hintPhone.
  ///
  /// In ko, this message translates to:
  /// **'010-0000-0000'**
  String get hintPhone;

  /// No description provided for @msgPhoneRequired.
  ///
  /// In ko, this message translates to:
  /// **'전화번호를 입력해주세요.'**
  String get msgPhoneRequired;

  /// No description provided for @labelMessageOptional.
  ///
  /// In ko, this message translates to:
  /// **'메시지 (선택)'**
  String get labelMessageOptional;

  /// No description provided for @hintSmsMessage.
  ///
  /// In ko, this message translates to:
  /// **'문자 내용'**
  String get hintSmsMessage;

  /// No description provided for @screenEmailTitle.
  ///
  /// In ko, this message translates to:
  /// **'이메일 태그'**
  String get screenEmailTitle;

  /// No description provided for @labelEmailRequired.
  ///
  /// In ko, this message translates to:
  /// **'이메일 주소 *'**
  String get labelEmailRequired;

  /// No description provided for @hintEmail.
  ///
  /// In ko, this message translates to:
  /// **'example@email.com'**
  String get hintEmail;

  /// No description provided for @msgEmailRequired.
  ///
  /// In ko, this message translates to:
  /// **'이메일 주소를 입력해주세요.'**
  String get msgEmailRequired;

  /// No description provided for @msgEmailInvalid.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 형식으로 입력해주세요.'**
  String get msgEmailInvalid;

  /// No description provided for @labelEmailSubjectOptional.
  ///
  /// In ko, this message translates to:
  /// **'제목 (선택)'**
  String get labelEmailSubjectOptional;

  /// No description provided for @hintEmailSubject.
  ///
  /// In ko, this message translates to:
  /// **'이메일 제목'**
  String get hintEmailSubject;

  /// No description provided for @labelEmailBodyOptional.
  ///
  /// In ko, this message translates to:
  /// **'내용 (선택)'**
  String get labelEmailBodyOptional;

  /// No description provided for @hintEmailBody.
  ///
  /// In ko, this message translates to:
  /// **'이메일 본문'**
  String get hintEmailBody;

  /// No description provided for @screenContactTitle.
  ///
  /// In ko, this message translates to:
  /// **'연락처 태그'**
  String get screenContactTitle;

  /// No description provided for @actionManualInput.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get actionManualInput;

  /// No description provided for @screenContactManualSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이름, 전화번호, 이메일을 직접 입력합니다'**
  String get screenContactManualSubtitle;

  /// No description provided for @hintSearchByName.
  ///
  /// In ko, this message translates to:
  /// **'이름으로 검색'**
  String get hintSearchByName;

  /// No description provided for @labelNoPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 없음'**
  String get labelNoPhone;

  /// No description provided for @msgContactPermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'연락처 접근 권한이 필요합니다'**
  String get msgContactPermissionRequired;

  /// No description provided for @msgContactPermissionHint.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력을 사용하거나 설정에서 권한을 허용해주세요.'**
  String get msgContactPermissionHint;

  /// No description provided for @actionOpenSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get actionOpenSettings;

  /// No description provided for @msgSearchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다.'**
  String get msgSearchNoResults;

  /// No description provided for @msgNoContacts.
  ///
  /// In ko, this message translates to:
  /// **'저장된 연락처가 없습니다.'**
  String get msgNoContacts;

  /// No description provided for @screenContactManualTitle.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get screenContactManualTitle;

  /// No description provided for @labelNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름 *'**
  String get labelNameRequired;

  /// No description provided for @hintName.
  ///
  /// In ko, this message translates to:
  /// **'홍길동'**
  String get hintName;

  /// No description provided for @msgNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요.'**
  String get msgNameRequired;

  /// No description provided for @labelPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화번호'**
  String get labelPhone;

  /// No description provided for @labelEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get labelEmail;

  /// No description provided for @screenLocationTitle.
  ///
  /// In ko, this message translates to:
  /// **'위치 태그'**
  String get screenLocationTitle;

  /// No description provided for @screenLocationTapHint.
  ///
  /// In ko, this message translates to:
  /// **'지도를 탭하여 위치를 선택하세요.'**
  String get screenLocationTapHint;

  /// No description provided for @msgSearchingAddress.
  ///
  /// In ko, this message translates to:
  /// **'주소 검색 중...'**
  String get msgSearchingAddress;

  /// No description provided for @msgAddressUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'주소를 가져올 수 없습니다.'**
  String get msgAddressUnavailable;

  /// No description provided for @labelPlaceNameOptional.
  ///
  /// In ko, this message translates to:
  /// **'장소명 (선택)'**
  String get labelPlaceNameOptional;

  /// No description provided for @hintPlaceName.
  ///
  /// In ko, this message translates to:
  /// **'비우면 건물명이 자동으로 사용됩니다.'**
  String get hintPlaceName;

  /// No description provided for @msgSelectLocation.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 위치를 선택해주세요.'**
  String get msgSelectLocation;

  /// No description provided for @screenEventTitle.
  ///
  /// In ko, this message translates to:
  /// **'이벤트/일정 태그'**
  String get screenEventTitle;

  /// No description provided for @labelEventTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'이벤트 제목 *'**
  String get labelEventTitleRequired;

  /// No description provided for @hintEventTitle.
  ///
  /// In ko, this message translates to:
  /// **'이벤트 제목'**
  String get hintEventTitle;

  /// No description provided for @msgEventTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요.'**
  String get msgEventTitleRequired;

  /// No description provided for @labelEventStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get labelEventStart;

  /// No description provided for @labelEventEnd.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get labelEventEnd;

  /// No description provided for @labelEventLocationOptional.
  ///
  /// In ko, this message translates to:
  /// **'장소/주소 (선택)'**
  String get labelEventLocationOptional;

  /// No description provided for @hintEventLocation.
  ///
  /// In ko, this message translates to:
  /// **'서울특별시 중구 ...'**
  String get hintEventLocation;

  /// No description provided for @labelEventDescOptional.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get labelEventDescOptional;

  /// No description provided for @hintEventDesc.
  ///
  /// In ko, this message translates to:
  /// **'이벤트 설명'**
  String get hintEventDesc;

  /// No description provided for @msgEventEndBeforeStart.
  ///
  /// In ko, this message translates to:
  /// **'종료 일시는 시작 일시 이후여야 합니다.'**
  String get msgEventEndBeforeStart;

  /// No description provided for @screenClipboardTitle.
  ///
  /// In ko, this message translates to:
  /// **'클립보드 태그'**
  String get screenClipboardTitle;

  /// No description provided for @msgClipboardEmpty.
  ///
  /// In ko, this message translates to:
  /// **'클립보드가 비어 있습니다. 직접 입력하세요.'**
  String get msgClipboardEmpty;

  /// No description provided for @labelContent.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get labelContent;

  /// No description provided for @hintClipboardText.
  ///
  /// In ko, this message translates to:
  /// **'태그에 저장할 텍스트'**
  String get hintClipboardText;

  /// No description provided for @msgContentRequired.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력해주세요.'**
  String get msgContentRequired;

  /// No description provided for @screenIosInputTitle.
  ///
  /// In ko, this message translates to:
  /// **'iOS 앱 실행 설정'**
  String get screenIosInputTitle;

  /// No description provided for @labelShortcutName.
  ///
  /// In ko, this message translates to:
  /// **'실행할 앱의 단축어 이름'**
  String get labelShortcutName;

  /// No description provided for @hintShortcutName.
  ///
  /// In ko, this message translates to:
  /// **'예: 내냉장고'**
  String get hintShortcutName;

  /// No description provided for @msgAppNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'앱 이름을 입력해주세요.'**
  String get msgAppNameRequired;

  /// No description provided for @screenIosInputGuideTitle.
  ///
  /// In ko, this message translates to:
  /// **'단축어 설정 안내'**
  String get screenIosInputGuideTitle;

  /// No description provided for @screenIosInputGuideSteps.
  ///
  /// In ko, this message translates to:
  /// **'1. iPhone의 단축어(Shortcuts) 앱을 열기\n2. 실행하려는 앱을 여는 단축어 만들기\n3. 단축어 이름을 위에 입력한 이름으로 저장\n4. 아래 버튼을 눌러 QR/NFC 생성'**
  String get screenIosInputGuideSteps;

  /// No description provided for @actionAppleShortcutsGuide.
  ///
  /// In ko, this message translates to:
  /// **'Apple 단축어 공식 사용 설명서'**
  String get actionAppleShortcutsGuide;

  /// No description provided for @screenAppPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 선택'**
  String get screenAppPickerTitle;

  /// No description provided for @hintAppSearch.
  ///
  /// In ko, this message translates to:
  /// **'앱 검색...'**
  String get hintAppSearch;

  /// No description provided for @msgAppListError.
  ///
  /// In ko, this message translates to:
  /// **'앱 목록을 불러올 수 없습니다.'**
  String get msgAppListError;

  /// No description provided for @msgSelectApp.
  ///
  /// In ko, this message translates to:
  /// **'앱을 선택해주세요.'**
  String get msgSelectApp;

  /// No description provided for @screenNfcWriterTitle.
  ///
  /// In ko, this message translates to:
  /// **'NFC 기록'**
  String get screenNfcWriterTitle;

  /// No description provided for @msgNfcWaiting.
  ///
  /// In ko, this message translates to:
  /// **'NFC 태그를 스마트폰 뒷면에\n가져다 대세요'**
  String get msgNfcWaiting;

  /// No description provided for @msgNfcSuccess.
  ///
  /// In ko, this message translates to:
  /// **'기록 완료!\n홈으로 이동합니다...'**
  String get msgNfcSuccess;

  /// No description provided for @msgNfcError.
  ///
  /// In ko, this message translates to:
  /// **'NFC 기록에 실패했습니다.'**
  String get msgNfcError;

  /// No description provided for @labelNfcIncludeIos.
  ///
  /// In ko, this message translates to:
  /// **'iOS 단축어도 함께 기록'**
  String get labelNfcIncludeIos;

  /// No description provided for @labelIosShortcutName.
  ///
  /// In ko, this message translates to:
  /// **'iOS 단축어 이름'**
  String get labelIosShortcutName;

  /// No description provided for @hintIosShortcutName.
  ///
  /// In ko, this message translates to:
  /// **'예: 카카오톡'**
  String get hintIosShortcutName;

  /// No description provided for @screenOutputSelectorTitle.
  ///
  /// In ko, this message translates to:
  /// **'출력 방식 선택'**
  String get screenOutputSelectorTitle;

  /// No description provided for @screenOutputQrDesc.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 스캔하여 앱 실행'**
  String get screenOutputQrDesc;

  /// No description provided for @screenOutputNfcDesc.
  ///
  /// In ko, this message translates to:
  /// **'태그에 가져다 대어 앱 실행'**
  String get screenOutputNfcDesc;

  /// No description provided for @msgNfcCheckFailed.
  ///
  /// In ko, this message translates to:
  /// **'NFC 확인 실패'**
  String get msgNfcCheckFailed;

  /// No description provided for @msgNfcSimulator.
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이터에서는 NFC를 테스트할 수 없습니다'**
  String get msgNfcSimulator;

  /// No description provided for @msgNfcNotSupported.
  ///
  /// In ko, this message translates to:
  /// **'이 기기는 NFC를 지원하지 않습니다'**
  String get msgNfcNotSupported;

  /// No description provided for @msgNfcWriteIosMin.
  ///
  /// In ko, this message translates to:
  /// **'NFC 쓰기는 iPhone XS 이상에서 지원됩니다'**
  String get msgNfcWriteIosMin;

  /// No description provided for @msgNfcUnsupportedDevice.
  ///
  /// In ko, this message translates to:
  /// **'NFC 미지원 기기'**
  String get msgNfcUnsupportedDevice;

  /// No description provided for @actionNfcWrite.
  ///
  /// In ko, this message translates to:
  /// **'NFC 태그 쓰기'**
  String get actionNfcWrite;

  /// No description provided for @screenQrResultTitle.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드'**
  String get screenQrResultTitle;

  /// No description provided for @tabTemplate.
  ///
  /// In ko, this message translates to:
  /// **'템플릿'**
  String get tabTemplate;

  /// No description provided for @tabShape.
  ///
  /// In ko, this message translates to:
  /// **'모양'**
  String get tabShape;

  /// No description provided for @tabColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get tabColor;

  /// No description provided for @tabLogo.
  ///
  /// In ko, this message translates to:
  /// **'로고'**
  String get tabLogo;

  /// No description provided for @tabText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트'**
  String get tabText;

  /// No description provided for @actionSaveGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리 저장'**
  String get actionSaveGallery;

  /// No description provided for @actionSaveTemplate.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 저장'**
  String get actionSaveTemplate;

  /// No description provided for @dialogLowReadabilityTitle.
  ///
  /// In ko, this message translates to:
  /// **'인식률이 낮습니다'**
  String get dialogLowReadabilityTitle;

  /// No description provided for @dialogLowReadabilityScore.
  ///
  /// In ko, this message translates to:
  /// **'현재 인식률: {score}%'**
  String dialogLowReadabilityScore(int score);

  /// No description provided for @dialogLowReadabilityWarning.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드가 일부 스캐너에서\n인식되지 않을 수 있습니다.'**
  String get dialogLowReadabilityWarning;

  /// No description provided for @dialogLowReadabilityCause.
  ///
  /// In ko, this message translates to:
  /// **'주요 원인: {issue}'**
  String dialogLowReadabilityCause(String issue);

  /// No description provided for @actionSaveAnyway.
  ///
  /// In ko, this message translates to:
  /// **'그래도 저장'**
  String get actionSaveAnyway;

  /// No description provided for @dialogSaveTemplateTitle.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 저장'**
  String get dialogSaveTemplateTitle;

  /// No description provided for @labelTemplateName.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 이름'**
  String get labelTemplateName;

  /// No description provided for @hintTemplateName.
  ///
  /// In ko, this message translates to:
  /// **'예: 파란 배경 QR'**
  String get hintTemplateName;

  /// No description provided for @msgTemplateSaved.
  ///
  /// In ko, this message translates to:
  /// **'「{name}」 템플릿이 저장되었습니다.'**
  String msgTemplateSaved(String name);

  /// No description provided for @msgSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 저장에 실패했습니다.'**
  String get msgSaveFailed;

  /// No description provided for @msgPrintFailed.
  ///
  /// In ko, this message translates to:
  /// **'인쇄에 실패했습니다. 프린터 연결을 확인해주세요.'**
  String get msgPrintFailed;

  /// No description provided for @labelReadability.
  ///
  /// In ko, this message translates to:
  /// **'인식률'**
  String get labelReadability;

  /// No description provided for @screenTemplateMyTemplates.
  ///
  /// In ko, this message translates to:
  /// **'나의 템플릿'**
  String get screenTemplateMyTemplates;

  /// No description provided for @actionNoStyle.
  ///
  /// In ko, this message translates to:
  /// **'스타일 없음'**
  String get actionNoStyle;

  /// No description provided for @msgTemplateApplied.
  ///
  /// In ko, this message translates to:
  /// **'「{name}」 템플릿이 적용되었습니다.'**
  String msgTemplateApplied(String name);

  /// No description provided for @dialogDeleteTemplateTitle.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 삭제'**
  String get dialogDeleteTemplateTitle;

  /// No description provided for @dialogDeleteTemplateContent.
  ///
  /// In ko, this message translates to:
  /// **'「{name}」을(를) 삭제하시겠습니까?'**
  String dialogDeleteTemplateContent(String name);

  /// No description provided for @msgNoSavedTemplates.
  ///
  /// In ko, this message translates to:
  /// **'저장된 템플릿이 없습니다.'**
  String get msgNoSavedTemplates;

  /// No description provided for @msgNoSavedTemplatesHint.
  ///
  /// In ko, this message translates to:
  /// **'하단 [템플릿 저장] 버튼으로 현재 스타일을 저장하세요.'**
  String get msgNoSavedTemplatesHint;

  /// No description provided for @tabColorSolid.
  ///
  /// In ko, this message translates to:
  /// **'단색'**
  String get tabColorSolid;

  /// No description provided for @tabColorGradient.
  ///
  /// In ko, this message translates to:
  /// **'그라디언트'**
  String get tabColorGradient;

  /// No description provided for @actionPickColor.
  ///
  /// In ko, this message translates to:
  /// **'직접 선택'**
  String get actionPickColor;

  /// No description provided for @labelRecommendedColors.
  ///
  /// In ko, this message translates to:
  /// **'추천 색상'**
  String get labelRecommendedColors;

  /// No description provided for @labelGradientPresets.
  ///
  /// In ko, this message translates to:
  /// **'그라디언트 프리셋'**
  String get labelGradientPresets;

  /// No description provided for @dialogColorPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'색상 선택'**
  String get dialogColorPickerTitle;

  /// No description provided for @labelDotShape.
  ///
  /// In ko, this message translates to:
  /// **'도트 모양'**
  String get labelDotShape;

  /// No description provided for @labelEyeOuter.
  ///
  /// In ko, this message translates to:
  /// **'눈 모양 — 외곽'**
  String get labelEyeOuter;

  /// No description provided for @labelEyeInner.
  ///
  /// In ko, this message translates to:
  /// **'눈 모양 — 내부'**
  String get labelEyeInner;

  /// No description provided for @shapeSquare.
  ///
  /// In ko, this message translates to:
  /// **'사각'**
  String get shapeSquare;

  /// No description provided for @shapeRounded.
  ///
  /// In ko, this message translates to:
  /// **'둥글기'**
  String get shapeRounded;

  /// No description provided for @shapeCircle.
  ///
  /// In ko, this message translates to:
  /// **'원형'**
  String get shapeCircle;

  /// No description provided for @shapeCircleRound.
  ///
  /// In ko, this message translates to:
  /// **'원형도넛'**
  String get shapeCircleRound;

  /// No description provided for @shapeSmooth.
  ///
  /// In ko, this message translates to:
  /// **'부드럽게'**
  String get shapeSmooth;

  /// No description provided for @shapeDiamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아'**
  String get shapeDiamond;

  /// No description provided for @shapeStar.
  ///
  /// In ko, this message translates to:
  /// **'별'**
  String get shapeStar;

  /// No description provided for @actionRandomRegenerate.
  ///
  /// In ko, this message translates to:
  /// **'랜덤 재생성'**
  String get actionRandomRegenerate;

  /// No description provided for @actionRandomEye.
  ///
  /// In ko, this message translates to:
  /// **'랜덤 눈 모양'**
  String get actionRandomEye;

  /// No description provided for @actionClear.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get actionClear;

  /// No description provided for @labelShowIcon.
  ///
  /// In ko, this message translates to:
  /// **'아이콘 표시'**
  String get labelShowIcon;

  /// No description provided for @msgIconUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'앱 아이콘 또는 이모지가 설정된 경우에만 표시됩니다.'**
  String get msgIconUnavailable;

  /// No description provided for @labelLogoPosition.
  ///
  /// In ko, this message translates to:
  /// **'로고 위치'**
  String get labelLogoPosition;

  /// No description provided for @optionCenter.
  ///
  /// In ko, this message translates to:
  /// **'중앙'**
  String get optionCenter;

  /// No description provided for @optionBottomRight.
  ///
  /// In ko, this message translates to:
  /// **'우하단'**
  String get optionBottomRight;

  /// No description provided for @labelLogoBackground.
  ///
  /// In ko, this message translates to:
  /// **'로고 배경'**
  String get labelLogoBackground;

  /// No description provided for @optionNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get optionNone;

  /// No description provided for @optionSquare.
  ///
  /// In ko, this message translates to:
  /// **'사각'**
  String get optionSquare;

  /// No description provided for @optionCircle.
  ///
  /// In ko, this message translates to:
  /// **'원형'**
  String get optionCircle;

  /// No description provided for @labelTopText.
  ///
  /// In ko, this message translates to:
  /// **'상단 텍스트'**
  String get labelTopText;

  /// No description provided for @labelBottomText.
  ///
  /// In ko, this message translates to:
  /// **'하단 텍스트'**
  String get labelBottomText;

  /// No description provided for @hintEnterText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트를 입력하세요'**
  String get hintEnterText;

  /// No description provided for @screenSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get screenSettingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 기본'**
  String get settingsLanguageSystem;

  /// No description provided for @msgCopiedToClipboard.
  ///
  /// In ko, this message translates to:
  /// **'\"{text}\" 클립보드에 복사됨'**
  String msgCopiedToClipboard(String text);

  /// No description provided for @settingsReadabilityAlert.
  ///
  /// In ko, this message translates to:
  /// **'인식률 알림 사용'**
  String get settingsReadabilityAlert;

  /// No description provided for @platformAndroid.
  ///
  /// In ko, this message translates to:
  /// **'Android'**
  String get platformAndroid;

  /// No description provided for @platformIos.
  ///
  /// In ko, this message translates to:
  /// **'iOS'**
  String get platformIos;

  /// No description provided for @labelCustomGradient.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 그라디언트'**
  String get labelCustomGradient;

  /// No description provided for @labelGradientType.
  ///
  /// In ko, this message translates to:
  /// **'유형'**
  String get labelGradientType;

  /// No description provided for @optionLinear.
  ///
  /// In ko, this message translates to:
  /// **'선형'**
  String get optionLinear;

  /// No description provided for @optionRadial.
  ///
  /// In ko, this message translates to:
  /// **'방사형'**
  String get optionRadial;

  /// No description provided for @labelAngle.
  ///
  /// In ko, this message translates to:
  /// **'각도'**
  String get labelAngle;

  /// No description provided for @labelCenter.
  ///
  /// In ko, this message translates to:
  /// **'가운데'**
  String get labelCenter;

  /// No description provided for @optionCenterCenter.
  ///
  /// In ko, this message translates to:
  /// **'중앙'**
  String get optionCenterCenter;

  /// No description provided for @optionCenterTopLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 상단'**
  String get optionCenterTopLeft;

  /// No description provided for @optionCenterTopRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 상단'**
  String get optionCenterTopRight;

  /// No description provided for @optionCenterBottomLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 하단'**
  String get optionCenterBottomLeft;

  /// No description provided for @optionCenterBottomRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 하단'**
  String get optionCenterBottomRight;

  /// No description provided for @labelColorStops.
  ///
  /// In ko, this message translates to:
  /// **'색 지점'**
  String get labelColorStops;

  /// No description provided for @actionAddStop.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get actionAddStop;

  /// No description provided for @actionDeleteStop.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get actionDeleteStop;

  /// No description provided for @loginTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginTitle;

  /// No description provided for @signupTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signupTitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get continueWithApple;

  /// No description provided for @loginWithEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일로 로그인'**
  String get loginWithEmail;

  /// No description provided for @useWithoutLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인 없이 사용하기'**
  String get useWithoutLogin;

  /// No description provided for @orDivider.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get orDivider;

  /// No description provided for @noAccountYet.
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요?'**
  String get noAccountYet;

  /// No description provided for @signUp.
  ///
  /// In ko, this message translates to:
  /// **'가입'**
  String get signUp;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get password;

  /// No description provided for @passwordConfirm.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get passwordConfirm;

  /// No description provided for @passwordMinLength.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 8자 이상이어야 합니다'**
  String get passwordMinLength;

  /// No description provided for @passwordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다'**
  String get passwordMismatch;

  /// No description provided for @invalidEmail.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일을 입력해주세요'**
  String get invalidEmail;

  /// No description provided for @nicknameRequired.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get nicknameRequired;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 프로필'**
  String get profileTitle;

  /// No description provided for @changePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 변경'**
  String get changePhoto;

  /// No description provided for @loginMethod.
  ///
  /// In ko, this message translates to:
  /// **'로그인 방법'**
  String get loginMethod;

  /// No description provided for @joinDate.
  ///
  /// In ko, this message translates to:
  /// **'가입일'**
  String get joinDate;

  /// No description provided for @syncStatus.
  ///
  /// In ko, this message translates to:
  /// **'동기화 상태'**
  String get syncStatus;

  /// No description provided for @synced.
  ///
  /// In ko, this message translates to:
  /// **'동기화됨'**
  String get synced;

  /// No description provided for @syncing.
  ///
  /// In ko, this message translates to:
  /// **'동기화 중...'**
  String get syncing;

  /// No description provided for @syncError.
  ///
  /// In ko, this message translates to:
  /// **'동기화 실패'**
  String get syncError;

  /// No description provided for @lastSynced.
  ///
  /// In ko, this message translates to:
  /// **'마지막 동기화'**
  String get lastSynced;

  /// No description provided for @justNow.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get justNow;

  /// No description provided for @manualSync.
  ///
  /// In ko, this message translates to:
  /// **'수동 동기화'**
  String get manualSync;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 계정을 삭제하시겠습니까? 클라우드 데이터가 모두 삭제됩니다.'**
  String get deleteAccountConfirm;

  /// No description provided for @logoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃하시겠습니까? 로컬 데이터는 유지됩니다.'**
  String get logoutConfirm;

  /// No description provided for @accountSection.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get accountSection;

  /// No description provided for @syncSection.
  ///
  /// In ko, this message translates to:
  /// **'동기화'**
  String get syncSection;

  /// No description provided for @loginPrompt.
  ///
  /// In ko, this message translates to:
  /// **'로그인하기'**
  String get loginPrompt;

  /// No description provided for @cloudSync.
  ///
  /// In ko, this message translates to:
  /// **'클라우드 동기화'**
  String get cloudSync;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @labelSavePreset.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 저장'**
  String get labelSavePreset;

  /// No description provided for @hintPresetName.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름'**
  String get hintPresetName;

  /// No description provided for @labelBoundaryShape.
  ///
  /// In ko, this message translates to:
  /// **'QR 전체 외곽'**
  String get labelBoundaryShape;

  /// No description provided for @labelAnimation.
  ///
  /// In ko, this message translates to:
  /// **'애니메이션'**
  String get labelAnimation;

  /// No description provided for @labelCustomDot.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 도트'**
  String get labelCustomDot;

  /// No description provided for @labelCustomEye.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 눈'**
  String get labelCustomEye;

  /// No description provided for @labelCustomBoundary.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 외곽'**
  String get labelCustomBoundary;

  /// No description provided for @labelCustomAnimation.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 애니메이션'**
  String get labelCustomAnimation;

  /// No description provided for @actionApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get actionApply;

  /// No description provided for @sliderVertices.
  ///
  /// In ko, this message translates to:
  /// **'꼭짓점'**
  String get sliderVertices;

  /// No description provided for @sliderInnerRadius.
  ///
  /// In ko, this message translates to:
  /// **'내부 반경'**
  String get sliderInnerRadius;

  /// No description provided for @sliderRoundness.
  ///
  /// In ko, this message translates to:
  /// **'둥글기'**
  String get sliderRoundness;

  /// No description provided for @sliderRotation.
  ///
  /// In ko, this message translates to:
  /// **'회전'**
  String get sliderRotation;

  /// No description provided for @sliderDotScale.
  ///
  /// In ko, this message translates to:
  /// **'크기'**
  String get sliderDotScale;

  /// No description provided for @labelSymmetric.
  ///
  /// In ko, this message translates to:
  /// **'대칭'**
  String get labelSymmetric;

  /// No description provided for @labelAsymmetric.
  ///
  /// In ko, this message translates to:
  /// **'비대칭'**
  String get labelAsymmetric;

  /// No description provided for @sliderSfM.
  ///
  /// In ko, this message translates to:
  /// **'대칭 차수 (m)'**
  String get sliderSfM;

  /// No description provided for @sliderSfN1.
  ///
  /// In ko, this message translates to:
  /// **'곡률 1'**
  String get sliderSfN1;

  /// No description provided for @sliderSfN2.
  ///
  /// In ko, this message translates to:
  /// **'곡률 2'**
  String get sliderSfN2;

  /// No description provided for @sliderSfN3.
  ///
  /// In ko, this message translates to:
  /// **'곡률 3'**
  String get sliderSfN3;

  /// No description provided for @sliderSfA.
  ///
  /// In ko, this message translates to:
  /// **'X 비율'**
  String get sliderSfA;

  /// No description provided for @sliderSfB.
  ///
  /// In ko, this message translates to:
  /// **'Y 비율'**
  String get sliderSfB;

  /// No description provided for @sliderOuterN.
  ///
  /// In ko, this message translates to:
  /// **'외곽 형태'**
  String get sliderOuterN;

  /// No description provided for @sliderInnerN.
  ///
  /// In ko, this message translates to:
  /// **'내부 형태'**
  String get sliderInnerN;

  /// No description provided for @labelBoundaryType.
  ///
  /// In ko, this message translates to:
  /// **'외곽 종류'**
  String get labelBoundaryType;

  /// No description provided for @sliderSuperellipseN.
  ///
  /// In ko, this message translates to:
  /// **'형태 N값'**
  String get sliderSuperellipseN;

  /// No description provided for @sliderStarVertices.
  ///
  /// In ko, this message translates to:
  /// **'별 꼭짓점'**
  String get sliderStarVertices;

  /// No description provided for @sliderStarInnerRadius.
  ///
  /// In ko, this message translates to:
  /// **'별 깊이'**
  String get sliderStarInnerRadius;

  /// No description provided for @sliderPadding.
  ///
  /// In ko, this message translates to:
  /// **'패딩'**
  String get sliderPadding;

  /// No description provided for @sliderSpeed.
  ///
  /// In ko, this message translates to:
  /// **'속도'**
  String get sliderSpeed;

  /// No description provided for @sliderAmplitude.
  ///
  /// In ko, this message translates to:
  /// **'강도'**
  String get sliderAmplitude;

  /// No description provided for @sliderFrequency.
  ///
  /// In ko, this message translates to:
  /// **'빈도'**
  String get sliderFrequency;

  /// No description provided for @optionLogoTypeLogo.
  ///
  /// In ko, this message translates to:
  /// **'로고'**
  String get optionLogoTypeLogo;

  /// No description provided for @optionLogoTypeImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지'**
  String get optionLogoTypeImage;

  /// No description provided for @optionLogoTypeText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트'**
  String get optionLogoTypeText;

  /// No description provided for @labelLogoTabPosition.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get labelLogoTabPosition;

  /// No description provided for @labelLogoTabBackground.
  ///
  /// In ko, this message translates to:
  /// **'배경'**
  String get labelLogoTabBackground;

  /// No description provided for @labelLogoCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get labelLogoCategory;

  /// No description provided for @labelLogoGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get labelLogoGallery;

  /// No description provided for @labelLogoRecrop.
  ///
  /// In ko, this message translates to:
  /// **'다시 자르기'**
  String get labelLogoRecrop;

  /// No description provided for @labelLogoTextContent.
  ///
  /// In ko, this message translates to:
  /// **'문구'**
  String get labelLogoTextContent;

  /// No description provided for @hintLogoTextContent.
  ///
  /// In ko, this message translates to:
  /// **'로고에 넣을 글자'**
  String get hintLogoTextContent;

  /// No description provided for @categorySocial.
  ///
  /// In ko, this message translates to:
  /// **'소셜'**
  String get categorySocial;

  /// No description provided for @categoryCoin.
  ///
  /// In ko, this message translates to:
  /// **'코인'**
  String get categoryCoin;

  /// No description provided for @categoryBrand.
  ///
  /// In ko, this message translates to:
  /// **'브랜드'**
  String get categoryBrand;

  /// No description provided for @categoryEmoji.
  ///
  /// In ko, this message translates to:
  /// **'이모지'**
  String get categoryEmoji;

  /// No description provided for @msgLogoLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'아이콘을 불러올 수 없습니다'**
  String get msgLogoLoadFailed;

  /// No description provided for @msgLogoCropFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 처리에 실패했습니다'**
  String get msgLogoCropFailed;

  /// No description provided for @labelLogoBackgroundColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get labelLogoBackgroundColor;

  /// No description provided for @actionLogoBackgroundReset.
  ///
  /// In ko, this message translates to:
  /// **'기본값'**
  String get actionLogoBackgroundReset;

  /// No description provided for @optionRectangle.
  ///
  /// In ko, this message translates to:
  /// **'사각'**
  String get optionRectangle;

  /// No description provided for @optionRoundedRectangle.
  ///
  /// In ko, this message translates to:
  /// **'원형'**
  String get optionRoundedRectangle;

  /// No description provided for @labelLogoType.
  ///
  /// In ko, this message translates to:
  /// **'유형'**
  String get labelLogoType;

  /// No description provided for @tileScanner.
  ///
  /// In ko, this message translates to:
  /// **'QR 스캐너'**
  String get tileScanner;

  /// No description provided for @scannerPermissionTitle.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한 필요'**
  String get scannerPermissionTitle;

  /// No description provided for @scannerPermissionDesc.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드를 스캔하려면 카메라 접근 권한이 필요합니다.'**
  String get scannerPermissionDesc;

  /// No description provided for @scannerPermissionOpenSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정으로 이동'**
  String get scannerPermissionOpenSettings;

  /// No description provided for @scannerPermissionGalleryFallback.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get scannerPermissionGalleryFallback;

  /// No description provided for @scannerFlashOn.
  ///
  /// In ko, this message translates to:
  /// **'플래시 켜기'**
  String get scannerFlashOn;

  /// No description provided for @scannerFlashOff.
  ///
  /// In ko, this message translates to:
  /// **'플래시 끄기'**
  String get scannerFlashOff;

  /// No description provided for @scannerGalleryImport.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 QR 코드 불러오기'**
  String get scannerGalleryImport;

  /// No description provided for @scannerGalleryFail.
  ///
  /// In ko, this message translates to:
  /// **'이미지에서 QR 코드를 인식할 수 없습니다.'**
  String get scannerGalleryFail;

  /// No description provided for @scanResultTitle.
  ///
  /// In ko, this message translates to:
  /// **'스캔 결과'**
  String get scanResultTitle;

  /// No description provided for @scanActionOpenBrowser.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get scanActionOpenBrowser;

  /// No description provided for @scanActionCopyLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 복사'**
  String get scanActionCopyLink;

  /// No description provided for @scanActionCopySsid.
  ///
  /// In ko, this message translates to:
  /// **'SSID 복사'**
  String get scanActionCopySsid;

  /// No description provided for @scanActionCopyPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 복사'**
  String get scanActionCopyPassword;

  /// No description provided for @scanActionCopyAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 복사'**
  String get scanActionCopyAll;

  /// No description provided for @scanActionShare.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get scanActionShare;

  /// No description provided for @scanActionOpenApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 열기'**
  String get scanActionOpenApp;

  /// No description provided for @scanActionCustomize.
  ///
  /// In ko, this message translates to:
  /// **'꾸미기'**
  String get scanActionCustomize;

  /// No description provided for @historyTabCreated.
  ///
  /// In ko, this message translates to:
  /// **'생성이력'**
  String get historyTabCreated;

  /// No description provided for @historyTabScanned.
  ///
  /// In ko, this message translates to:
  /// **'스캔이력'**
  String get historyTabScanned;

  /// No description provided for @historySearchHint.
  ///
  /// In ko, this message translates to:
  /// **'검색...'**
  String get historySearchHint;

  /// No description provided for @historyFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get historyFilterAll;

  /// No description provided for @historyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이력이 없습니다.'**
  String get historyEmpty;

  /// No description provided for @actionFavorite.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get actionFavorite;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'pt',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
