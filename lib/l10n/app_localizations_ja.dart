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
  String msgTemplateApplied(String name) {
    return '「$name」テンプレートが適用されました。';
  }

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
  String get actionRandomRegenerate => 'ランダム再生成';

  @override
  String get actionRandomEye => 'ランダム目の形';

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
}
