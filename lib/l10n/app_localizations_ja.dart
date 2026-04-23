// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'QR・NFC ジェネレーター';

  @override
  String get screenSplashSubtitle => '自分だけのQRコードを作ってカスタマイズしよう';

  @override
  String get tileAppAndroid => 'アプリ起動';

  @override
  String get tileAppIos => 'ショートカット';

  @override
  String get tileClipboard => 'クリップボード';

  @override
  String get tileWebsite => 'ウェブサイト';

  @override
  String get tileContact => '連絡先';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => '位置情報';

  @override
  String get tileEvent => 'イベント/予定';

  @override
  String get tileEmail => 'メール';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'QR・NFC ジェネレーター';

  @override
  String get screenHomeEditModeTitle => '編集モード';

  @override
  String get actionDone => '完了';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionDelete => '削除';

  @override
  String get actionEdit => '編集';

  @override
  String actionDeleteCount(int count) {
    return '$count件削除';
  }

  @override
  String get actionSave => '保存';

  @override
  String get actionShare => '共有';

  @override
  String get actionRetry => '再試行';

  @override
  String get actionClose => '閉じる';

  @override
  String get actionConfirm => 'OK';

  @override
  String get tooltipHelp => '使い方ガイド';

  @override
  String get tooltipFavorite => '즐겨찾기';

  @override
  String get tooltipUnfavorite => '즐겨찾기 해제';

  @override
  String get tooltipHistory => '作成履歴';

  @override
  String get tooltipDeleteAll => 'すべて削除';

  @override
  String get actionCollapseHidden => '非表示メニューを閉じる';

  @override
  String actionShowHidden(int count) {
    return '非表示メニューを見る ($count)';
  }

  @override
  String get screenHelpTitle => '使い方ガイド';

  @override
  String get screenHistoryTitle => '作成履歴';

  @override
  String get screenHistoryEmpty => '履歴がありません。';

  @override
  String get labelQrCode => 'QRコード';

  @override
  String get labelNfcTag => 'NFCタグ';

  @override
  String get dialogClearAllTitle => 'すべて削除';

  @override
  String get dialogClearAllContent => 'すべての履歴を削除しますか？';

  @override
  String get dialogDeleteHistoryTitle => '履歴を削除';

  @override
  String dialogDeleteHistoryContent(String name) {
    return '「$name」の履歴を削除しますか？';
  }

  @override
  String get screenWebsiteTitle => 'ウェブサイトタグ';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'URLを入力してください。';

  @override
  String get msgUrlInvalid => '正しいURL形式で入力してください。';

  @override
  String get screenWifiTitle => 'WiFiタグ';

  @override
  String get labelWifiSsid => 'ネットワーク名 (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'SSIDを入力してください。';

  @override
  String get labelWifiSecurity => 'セキュリティ方式';

  @override
  String get optionWpa2 => 'WPA2（推奨）';

  @override
  String get optionNoSecurity => 'なし';

  @override
  String get labelWifiPassword => 'パスワード';

  @override
  String get hintWifiPassword => 'パスワード';

  @override
  String get screenSmsTitle => 'SMSタグ';

  @override
  String get labelPhoneRequired => '電話番号 *';

  @override
  String get hintPhone => '090-0000-0000';

  @override
  String get msgPhoneRequired => '電話番号を入力してください。';

  @override
  String get labelMessageOptional => 'メッセージ（任意）';

  @override
  String get hintSmsMessage => 'メッセージ内容';

  @override
  String get screenEmailTitle => 'メールタグ';

  @override
  String get labelEmailRequired => 'メールアドレス *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => 'メールアドレスを入力してください。';

  @override
  String get msgEmailInvalid => '正しいメール形式で入力してください。';

  @override
  String get labelEmailSubjectOptional => '件名（任意）';

  @override
  String get hintEmailSubject => 'メールの件名';

  @override
  String get labelEmailBodyOptional => '本文（任意）';

  @override
  String get hintEmailBody => 'メール本文';

  @override
  String get screenContactTitle => '連絡先タグ';

  @override
  String get actionManualInput => '手動入力';

  @override
  String get screenContactManualSubtitle => '名前、電話番号、メールを手動で入力します';

  @override
  String get hintSearchByName => '名前で検索';

  @override
  String get labelNoPhone => '電話番号なし';

  @override
  String get msgContactPermissionRequired => '連絡先へのアクセス許可が必要です';

  @override
  String get msgContactPermissionHint => '手動入力を使用するか、設定で許可を有効にしてください。';

  @override
  String get actionOpenSettings => '設定を開く';

  @override
  String get msgSearchNoResults => '検索結果がありません。';

  @override
  String get msgNoContacts => '保存された連絡先がありません。';

  @override
  String get screenContactManualTitle => '手動入力';

  @override
  String get labelNameRequired => '名前 *';

  @override
  String get hintName => '山田太郎';

  @override
  String get msgNameRequired => '名前を入力してください。';

  @override
  String get labelPhone => '電話番号';

  @override
  String get labelEmail => 'メール';

  @override
  String get screenLocationTitle => '位置情報タグ';

  @override
  String get screenLocationTapHint => '地図をタップして位置を選択してください。';

  @override
  String get msgSearchingAddress => '住所を検索中...';

  @override
  String get msgAddressUnavailable => '住所を取得できませんでした。';

  @override
  String get labelPlaceNameOptional => '場所名（任意）';

  @override
  String get hintPlaceName => '空にすると建物名が自動的に使用されます。';

  @override
  String get msgSelectLocation => '地図上で位置を選択してください。';

  @override
  String get screenEventTitle => 'イベント/予定タグ';

  @override
  String get labelEventTitleRequired => 'イベントタイトル *';

  @override
  String get hintEventTitle => 'イベントタイトル';

  @override
  String get msgEventTitleRequired => 'タイトルを入力してください。';

  @override
  String get labelEventStart => '開始';

  @override
  String get labelEventEnd => '終了';

  @override
  String get labelEventLocationOptional => '場所/住所（任意）';

  @override
  String get hintEventLocation => '東京都中央区...';

  @override
  String get labelEventDescOptional => '説明（任意）';

  @override
  String get hintEventDesc => 'イベントの説明';

  @override
  String get msgEventEndBeforeStart => '終了日時は開始日時より後にしてください。';

  @override
  String get screenClipboardTitle => 'クリップボードタグ';

  @override
  String get msgClipboardEmpty => 'クリップボードが空です。テキストを入力してください。';

  @override
  String get labelContent => '内容';

  @override
  String get hintClipboardText => 'タグに保存するテキスト';

  @override
  String get msgContentRequired => '内容を入力してください。';

  @override
  String get screenIosInputTitle => 'iOS アプリ起動設定';

  @override
  String get labelShortcutName => '起動するアプリのショートカット名';

  @override
  String get hintShortcutName => '例: マイアプリ';

  @override
  String get msgAppNameRequired => 'アプリ名を入力してください。';

  @override
  String get screenIosInputGuideTitle => 'ショートカット設定ガイド';

  @override
  String get screenIosInputGuideSteps =>
      '1. iPhoneのショートカット(Shortcuts)アプリを開く\n2. 起動したいアプリを開くショートカットを作成\n3. 上で入力した名前でショートカットを保存\n4. 下のボタンを押してQR/NFCを生成';

  @override
  String get actionAppleShortcutsGuide => 'Apple ショートカット公式ガイド';

  @override
  String get screenAppPickerTitle => 'アプリを選択';

  @override
  String get hintAppSearch => 'アプリを検索...';

  @override
  String get msgAppListError => 'アプリ一覧を読み込めませんでした。';

  @override
  String get msgSelectApp => 'アプリを選択してください。';

  @override
  String get screenNfcWriterTitle => 'NFC書き込み';

  @override
  String get msgNfcWaiting => 'NFCタグをスマートフォンの\n背面に近づけてください';

  @override
  String get msgNfcSuccess => '書き込み完了！\nホームに戻ります...';

  @override
  String get msgNfcError => 'NFC書き込みに失敗しました。';

  @override
  String get labelNfcIncludeIos => 'iOSショートカットも一緒に書き込む';

  @override
  String get labelIosShortcutName => 'iOS ショートカット名';

  @override
  String get hintIosShortcutName => '例: LINE';

  @override
  String get screenOutputSelectorTitle => '出力方式を選択';

  @override
  String get screenOutputQrDesc => 'カメラでスキャンしてアプリを起動';

  @override
  String get screenOutputNfcDesc => 'タグにかざしてアプリを起動';

  @override
  String get msgNfcCheckFailed => 'NFC確認に失敗';

  @override
  String get msgNfcSimulator => 'シミュレーターではNFCをテストできません';

  @override
  String get msgNfcNotSupported => 'この端末はNFCに対応していません';

  @override
  String get msgNfcWriteIosMin => 'NFC書き込みはiPhone XS以降で対応しています';

  @override
  String get msgNfcUnsupportedDevice => 'NFC非対応端末';

  @override
  String get actionNfcWrite => 'NFCタグに書き込む';

  @override
  String get screenQrResultTitle => 'QRコード';

  @override
  String get tabTemplate => 'テンプレート';

  @override
  String get tabShape => '形状';

  @override
  String get tabColor => '色';

  @override
  String get tabLogo => 'ロゴ';

  @override
  String get tabText => 'テキスト';

  @override
  String get actionSaveGallery => 'ギャラリーに保存';

  @override
  String get actionSaveSvg => 'SVG 저장';

  @override
  String get actionSaveTemplate => 'テンプレート保存';

  @override
  String get dialogLowReadabilityTitle => '認識率が低い状態です';

  @override
  String dialogLowReadabilityScore(int score) {
    return '現在の認識率: $score%';
  }

  @override
  String get dialogLowReadabilityWarning => 'QRコードが一部のスキャナーで\n認識されない場合があります。';

  @override
  String dialogLowReadabilityCause(String issue) {
    return '主な原因: $issue';
  }

  @override
  String get actionSaveAnyway => 'それでも保存';

  @override
  String get dialogSaveTemplateTitle => 'テンプレート保存';

  @override
  String get labelTemplateName => 'テンプレート名';

  @override
  String get hintTemplateName => '例: 青い背景のQR';

  @override
  String msgTemplateSaved(String name) {
    return '「$name」テンプレートが保存されました。';
  }

  @override
  String get msgSaveFailed => '画像の保存に失敗しました。';

  @override
  String get msgPrintFailed => '印刷に失敗しました。プリンター接続を確認してください。';

  @override
  String get labelReadability => '認識率';

  @override
  String get screenTemplateMyTemplates => 'マイテンプレート';

  @override
  String get actionNoStyle => 'スタイルなし';

  @override
  String get dialogDeleteTemplateTitle => 'テンプレート削除';

  @override
  String dialogDeleteTemplateContent(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get msgNoSavedTemplates => '保存されたテンプレートがありません。';

  @override
  String get msgNoSavedTemplatesHint => '下の「テンプレート保存」ボタンで現在のスタイルを保存してください。';

  @override
  String get tabColorSolid => '単色';

  @override
  String get tabColorGradient => 'グラデーション';

  @override
  String get actionPickColor => '色を選ぶ';

  @override
  String get labelRecommendedColors => 'おすすめの色';

  @override
  String get labelGradientPresets => 'グラデーションプリセット';

  @override
  String get dialogColorPickerTitle => '色を選択';

  @override
  String get labelDotShape => 'ドットの形';

  @override
  String get labelEyeOuter => '目の形 — 外側';

  @override
  String get labelEyeInner => '目の形 — 内側';

  @override
  String get shapeSquare => '四角';

  @override
  String get shapeRounded => '角丸';

  @override
  String get shapeCircle => '円形';

  @override
  String get shapeCircleRound => '円形ドーナツ';

  @override
  String get shapeSmooth => 'スムーズ';

  @override
  String get shapeDiamond => 'ダイヤモンド';

  @override
  String get shapeStar => '星';

  @override
  String get actionClear => '解除';

  @override
  String get labelShowIcon => 'アイコン表示';

  @override
  String get msgIconUnavailable => 'アプリアイコンまたは絵文字が設定されている場合のみ表示されます。';

  @override
  String get labelLogoPosition => 'ロゴの位置';

  @override
  String get optionCenter => '中央';

  @override
  String get optionBottomRight => '右下';

  @override
  String get labelLogoBackground => 'ロゴの背景';

  @override
  String get optionNone => 'なし';

  @override
  String get optionSquare => '四角';

  @override
  String get optionCircle => '円形';

  @override
  String get labelTopText => '上部テキスト';

  @override
  String get labelBottomText => '下部テキスト';

  @override
  String get hintEnterText => 'テキストを入力してください';

  @override
  String get screenSettingsTitle => '設定';

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
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSystem => 'システムデフォルト';

  @override
  String msgCopiedToClipboard(String text) {
    return '「$text」をクリップボードにコピーしました';
  }

  @override
  String get settingsReadabilityAlert => '認識率アラート';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';

  @override
  String get labelCustomGradient => 'カスタムグラデーション';

  @override
  String get labelGradientType => 'タイプ';

  @override
  String get optionLinear => '線形';

  @override
  String get optionRadial => '放射状';

  @override
  String get labelAngle => '角度';

  @override
  String get labelCenter => '中心';

  @override
  String get optionCenterCenter => '中央';

  @override
  String get optionCenterTopLeft => '左上';

  @override
  String get optionCenterTopRight => '右上';

  @override
  String get optionCenterBottomLeft => '左下';

  @override
  String get optionCenterBottomRight => '右下';

  @override
  String get labelColorStops => 'カラーストップ';

  @override
  String get actionAddStop => '追加';

  @override
  String get actionDeleteStop => '削除';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get signupTitle => '新規登録';

  @override
  String get continueWithGoogle => 'Googleで続ける';

  @override
  String get continueWithApple => 'Appleで続ける';

  @override
  String get loginWithEmail => 'メールでログイン';

  @override
  String get useWithoutLogin => 'ログインせずに使用';

  @override
  String get orDivider => 'または';

  @override
  String get noAccountYet => 'アカウントをお持ちでないですか？';

  @override
  String get signUp => '登録';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get passwordConfirm => 'パスワード確認';

  @override
  String get passwordMinLength => 'パスワードは8文字以上必要です';

  @override
  String get passwordMismatch => 'パスワードが一致しません';

  @override
  String get invalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get nicknameRequired => 'ニックネームを入力してください';

  @override
  String get profileTitle => 'マイプロフィール';

  @override
  String get changePhoto => '写真を変更';

  @override
  String get loginMethod => 'ログイン方法';

  @override
  String get joinDate => '登録日';

  @override
  String get syncStatus => '同期状態';

  @override
  String get synced => '同期済み';

  @override
  String get syncing => '同期中...';

  @override
  String get syncError => '同期失敗';

  @override
  String get lastSynced => '最終同期';

  @override
  String get justNow => 'たった今';

  @override
  String get manualSync => '手動同期';

  @override
  String get logout => 'ログアウト';

  @override
  String get deleteAccount => 'アカウント削除';

  @override
  String get deleteAccountConfirm => '本当にアカウントを削除しますか？クラウドデータがすべて削除されます。';

  @override
  String get logoutConfirm => 'ログアウトしますか？ローカルデータは保持されます。';

  @override
  String get accountSection => 'アカウント';

  @override
  String get syncSection => '同期';

  @override
  String get loginPrompt => 'ログイン';

  @override
  String get cloudSync => 'クラウド同期';

  @override
  String get cancel => 'キャンセル';

  @override
  String get labelSavePreset => 'プリセット保存';

  @override
  String get hintPresetName => 'プリセット名';

  @override
  String get labelBoundaryShape => 'QR外枠';

  @override
  String get labelAnimation => 'アニメーション';

  @override
  String get labelCustomDot => 'カスタムドット';

  @override
  String get labelCustomEye => 'カスタムアイ';

  @override
  String get labelCustomBoundary => 'カスタム外枠';

  @override
  String get labelCustomAnimation => 'カスタムアニメーション';

  @override
  String get actionApply => '適用';

  @override
  String get sliderVertices => '頂点数';

  @override
  String get sliderInnerRadius => '内半径';

  @override
  String get sliderRoundness => '丸み';

  @override
  String get sliderRotation => '回転';

  @override
  String get sliderDotScale => 'サイズ';

  @override
  String get labelSymmetric => '対称';

  @override
  String get labelAsymmetric => '非対称';

  @override
  String get sliderSfM => '対称次数 (m)';

  @override
  String get sliderSfN1 => '曲率 1';

  @override
  String get sliderSfN2 => '曲率 2';

  @override
  String get sliderSfN3 => '曲率 3';

  @override
  String get sliderSfA => 'X スケール';

  @override
  String get sliderSfB => 'Y スケール';

  @override
  String get sliderOuterN => '外枠形状';

  @override
  String get sliderInnerN => '内部形状';

  @override
  String get sliderCornerQ1 => 'Q1 모서리';

  @override
  String get sliderCornerQ2 => 'Q2 모서리';

  @override
  String get sliderCornerQ3 => 'Q3 모서리';

  @override
  String get sliderCornerQ4 => 'Q4 모서리';

  @override
  String get labelBoundaryType => '外枠タイプ';

  @override
  String get sliderSuperellipseN => '形状N値';

  @override
  String get sliderStarVertices => '星の頂点';

  @override
  String get sliderStarInnerRadius => '星の深さ';

  @override
  String get sliderPadding => 'パディング';

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
  String get sliderSpeed => '速度';

  @override
  String get sliderAmplitude => '振幅';

  @override
  String get sliderFrequency => '周波数';

  @override
  String get optionLogoTypeLogo => 'ロゴ';

  @override
  String get optionLogoTypeImage => '画像';

  @override
  String get optionLogoTypeText => 'テキスト';

  @override
  String get labelLogoTabPosition => '位置';

  @override
  String get labelLogoTabBackground => '背景';

  @override
  String get labelLogoCategory => 'カテゴリ';

  @override
  String get labelLogoGallery => 'ギャラリーから選択';

  @override
  String get labelLogoRecrop => '再切り抜き';

  @override
  String get labelLogoTextContent => '文字';

  @override
  String get hintLogoTextContent => 'ロゴの文字';

  @override
  String get categorySocial => 'ソーシャル';

  @override
  String get categoryCoin => 'コイン';

  @override
  String get categoryBrand => 'ブランド';

  @override
  String get categoryEmoji => '絵文字';

  @override
  String get msgLogoLoadFailed => 'アイコンを読み込めません';

  @override
  String get msgLogoCropFailed => '画像処理に失敗しました';

  @override
  String get labelLogoBackgroundColor => '色';

  @override
  String get actionLogoBackgroundReset => 'デフォルト';

  @override
  String get optionRectangle => '四角';

  @override
  String get optionRoundedRectangle => '丸';

  @override
  String get labelLogoType => '種類';

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
