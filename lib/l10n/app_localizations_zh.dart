// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'QR和NFC生成器';

  @override
  String get screenSplashSubtitle => '创建并装饰您自己的QR码';

  @override
  String get tileAppAndroid => '启动应用';

  @override
  String get tileAppIos => '快捷指令';

  @override
  String get tileClipboard => '剪贴板';

  @override
  String get tileWebsite => '网站';

  @override
  String get tileContact => '联系人';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => '位置';

  @override
  String get tileEvent => '事件/日程';

  @override
  String get tileEmail => '邮件';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'QR和NFC生成器';

  @override
  String get screenHomeEditModeTitle => '编辑模式';

  @override
  String get actionDone => '完成';

  @override
  String get actionCancel => '取消';

  @override
  String get actionDelete => '删除';

  @override
  String get actionEdit => '编辑';

  @override
  String actionDeleteCount(int count) {
    return '删除$count个';
  }

  @override
  String get actionSave => '保存';

  @override
  String get actionShare => '分享';

  @override
  String get actionRetry => '重试';

  @override
  String get actionClose => '关闭';

  @override
  String get actionConfirm => '确认';

  @override
  String get tooltipHelp => '使用指南';

  @override
  String get tooltipHistory => '生成记录';

  @override
  String get tooltipDeleteAll => '全部删除';

  @override
  String get actionCollapseHidden => '收起隐藏菜单';

  @override
  String actionShowHidden(int count) {
    return '查看隐藏菜单 ($count)';
  }

  @override
  String get screenHelpTitle => '使用指南';

  @override
  String get screenHistoryTitle => '生成记录';

  @override
  String get screenHistoryEmpty => '暂无记录。';

  @override
  String get labelQrCode => 'QR码';

  @override
  String get labelNfcTag => 'NFC标签';

  @override
  String get dialogClearAllTitle => '全部删除';

  @override
  String get dialogClearAllContent => '确定要删除所有记录吗？';

  @override
  String get dialogDeleteHistoryTitle => '删除记录';

  @override
  String dialogDeleteHistoryContent(String name) {
    return '确定要删除「$name」的记录吗？';
  }

  @override
  String get screenWebsiteTitle => '网站标签';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => '请输入URL。';

  @override
  String get msgUrlInvalid => '请输入有效的URL格式。';

  @override
  String get screenWifiTitle => 'WiFi标签';

  @override
  String get labelWifiSsid => '网络名称 (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => '请输入SSID。';

  @override
  String get labelWifiSecurity => '安全方式';

  @override
  String get optionWpa2 => 'WPA2（推荐）';

  @override
  String get optionNoSecurity => '无';

  @override
  String get labelWifiPassword => '密码';

  @override
  String get hintWifiPassword => '密码';

  @override
  String get screenSmsTitle => 'SMS标签';

  @override
  String get labelPhoneRequired => '电话号码 *';

  @override
  String get hintPhone => '138-0000-0000';

  @override
  String get msgPhoneRequired => '请输入电话号码。';

  @override
  String get labelMessageOptional => '消息（可选）';

  @override
  String get hintSmsMessage => '短信内容';

  @override
  String get screenEmailTitle => '邮件标签';

  @override
  String get labelEmailRequired => '邮箱地址 *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => '请输入邮箱地址。';

  @override
  String get msgEmailInvalid => '请输入有效的邮箱格式。';

  @override
  String get labelEmailSubjectOptional => '主题（可选）';

  @override
  String get hintEmailSubject => '邮件主题';

  @override
  String get labelEmailBodyOptional => '正文（可选）';

  @override
  String get hintEmailBody => '邮件正文';

  @override
  String get screenContactTitle => '联系人标签';

  @override
  String get actionManualInput => '手动输入';

  @override
  String get screenContactManualSubtitle => '手动输入姓名、电话号码和邮箱';

  @override
  String get hintSearchByName => '按姓名搜索';

  @override
  String get labelNoPhone => '无电话号码';

  @override
  String get msgContactPermissionRequired => '需要通讯录访问权限';

  @override
  String get msgContactPermissionHint => '请使用手动输入或在设置中允许权限。';

  @override
  String get actionOpenSettings => '打开设置';

  @override
  String get msgSearchNoResults => '无搜索结果。';

  @override
  String get msgNoContacts => '没有已保存的联系人。';

  @override
  String get screenContactManualTitle => '手动输入';

  @override
  String get labelNameRequired => '姓名 *';

  @override
  String get hintName => '张三';

  @override
  String get msgNameRequired => '请输入姓名。';

  @override
  String get labelPhone => '电话';

  @override
  String get labelEmail => '邮箱';

  @override
  String get screenLocationTitle => '位置标签';

  @override
  String get screenLocationTapHint => '点击地图选择位置。';

  @override
  String get msgSearchingAddress => '正在搜索地址...';

  @override
  String get msgAddressUnavailable => '无法获取地址。';

  @override
  String get labelPlaceNameOptional => '地点名称（可选）';

  @override
  String get hintPlaceName => '留空将自动使用建筑名称。';

  @override
  String get msgSelectLocation => '请在地图上选择位置。';

  @override
  String get screenEventTitle => '事件/日程标签';

  @override
  String get labelEventTitleRequired => '事件标题 *';

  @override
  String get hintEventTitle => '事件标题';

  @override
  String get msgEventTitleRequired => '请输入标题。';

  @override
  String get labelEventStart => '开始';

  @override
  String get labelEventEnd => '结束';

  @override
  String get labelEventLocationOptional => '地点/地址（可选）';

  @override
  String get hintEventLocation => '北京市朝阳区...';

  @override
  String get labelEventDescOptional => '描述（可选）';

  @override
  String get hintEventDesc => '事件描述';

  @override
  String get msgEventEndBeforeStart => '结束时间必须在开始时间之后。';

  @override
  String get screenClipboardTitle => '剪贴板标签';

  @override
  String get msgClipboardEmpty => '剪贴板为空。请手动输入。';

  @override
  String get labelContent => '内容';

  @override
  String get hintClipboardText => '要保存到标签的文本';

  @override
  String get msgContentRequired => '请输入内容。';

  @override
  String get screenIosInputTitle => 'iOS 应用启动设置';

  @override
  String get labelShortcutName => '要启动的应用快捷指令名称';

  @override
  String get hintShortcutName => '例：我的应用';

  @override
  String get msgAppNameRequired => '请输入应用名称。';

  @override
  String get screenIosInputGuideTitle => '快捷指令设置指南';

  @override
  String get screenIosInputGuideSteps =>
      '1. 打开iPhone上的快捷指令(Shortcuts)应用\n2. 创建一个打开目标应用的快捷指令\n3. 用上面输入的名称保存快捷指令\n4. 点击下方按钮生成QR/NFC';

  @override
  String get actionAppleShortcutsGuide => 'Apple 快捷指令官方指南';

  @override
  String get screenAppPickerTitle => '选择应用';

  @override
  String get hintAppSearch => '搜索应用...';

  @override
  String get msgAppListError => '无法加载应用列表。';

  @override
  String get msgSelectApp => '请选择一个应用。';

  @override
  String get screenNfcWriterTitle => 'NFC写入';

  @override
  String get msgNfcWaiting => '请将NFC标签靠近\n手机背面';

  @override
  String get msgNfcSuccess => '写入完成！\n正在返回首页...';

  @override
  String get msgNfcError => 'NFC写入失败。';

  @override
  String get labelNfcIncludeIos => '同时写入iOS快捷指令';

  @override
  String get labelIosShortcutName => 'iOS 快捷指令名称';

  @override
  String get hintIosShortcutName => '例：微信';

  @override
  String get screenOutputSelectorTitle => '选择输出方式';

  @override
  String get screenOutputQrDesc => '用相机扫描启动应用';

  @override
  String get screenOutputNfcDesc => '触碰标签启动应用';

  @override
  String get msgNfcCheckFailed => 'NFC检查失败';

  @override
  String get msgNfcSimulator => '模拟器中无法测试NFC';

  @override
  String get msgNfcNotSupported => '此设备不支持NFC';

  @override
  String get msgNfcWriteIosMin => 'NFC写入需要iPhone XS或更新机型';

  @override
  String get msgNfcUnsupportedDevice => 'NFC不支持的设备';

  @override
  String get actionNfcWrite => '写入NFC标签';

  @override
  String get screenQrResultTitle => 'QR码';

  @override
  String get tabTemplate => '模板';

  @override
  String get tabShape => '形状';

  @override
  String get tabColor => '颜色';

  @override
  String get tabLogo => 'Logo';

  @override
  String get tabText => '文字';

  @override
  String get actionSaveGallery => '保存到相册';

  @override
  String get actionSaveTemplate => '保存模板';

  @override
  String get dialogLowReadabilityTitle => '识别率较低';

  @override
  String dialogLowReadabilityScore(int score) {
    return '当前识别率：$score%';
  }

  @override
  String get dialogLowReadabilityWarning => 'QR码可能无法被\n某些扫描器识别。';

  @override
  String dialogLowReadabilityCause(String issue) {
    return '主要原因：$issue';
  }

  @override
  String get actionSaveAnyway => '仍然保存';

  @override
  String get dialogSaveTemplateTitle => '保存模板';

  @override
  String get labelTemplateName => '模板名称';

  @override
  String get hintTemplateName => '例：蓝色背景QR';

  @override
  String msgTemplateSaved(String name) {
    return '模板「$name」已保存。';
  }

  @override
  String get msgSaveFailed => '图片保存失败。';

  @override
  String get msgPrintFailed => '打印失败。请检查打印机连接。';

  @override
  String get labelReadability => '识别率';

  @override
  String get screenTemplateMyTemplates => '我的模板';

  @override
  String get actionNoStyle => '无样式';

  @override
  String get dialogDeleteTemplateTitle => '删除模板';

  @override
  String dialogDeleteTemplateContent(String name) {
    return '确定要删除「$name」吗？';
  }

  @override
  String get msgNoSavedTemplates => '没有已保存的模板。';

  @override
  String get msgNoSavedTemplatesHint => '使用下方的「保存模板」按钮保存当前样式。';

  @override
  String get tabColorSolid => '纯色';

  @override
  String get tabColorGradient => '渐变';

  @override
  String get actionPickColor => '自选颜色';

  @override
  String get labelRecommendedColors => '推荐颜色';

  @override
  String get labelGradientPresets => '渐变预设';

  @override
  String get dialogColorPickerTitle => '选择颜色';

  @override
  String get labelDotShape => '点形状';

  @override
  String get labelEyeOuter => '眼形 — 外圈';

  @override
  String get labelEyeInner => '眼形 — 内圈';

  @override
  String get shapeSquare => '方形';

  @override
  String get shapeRounded => '圆角';

  @override
  String get shapeCircle => '圆形';

  @override
  String get shapeCircleRound => '圆形甜甜圈';

  @override
  String get shapeSmooth => '平滑';

  @override
  String get shapeDiamond => '菱形';

  @override
  String get shapeStar => '星形';

  @override
  String get actionClear => '清除';

  @override
  String get labelShowIcon => '显示图标';

  @override
  String get msgIconUnavailable => '仅在设置了应用图标或表情符号时显示。';

  @override
  String get labelLogoPosition => 'Logo位置';

  @override
  String get optionCenter => '居中';

  @override
  String get optionBottomRight => '右下角';

  @override
  String get labelLogoBackground => 'Logo背景';

  @override
  String get optionNone => '无';

  @override
  String get optionSquare => '方形';

  @override
  String get optionCircle => '圆形';

  @override
  String get labelTopText => '顶部文字';

  @override
  String get labelBottomText => '底部文字';

  @override
  String get hintEnterText => '请输入文字';

  @override
  String get screenSettingsTitle => '设置';

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
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String msgCopiedToClipboard(String text) {
    return '「$text」已复制到剪贴板';
  }

  @override
  String get settingsReadabilityAlert => '识别率提醒';

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';

  @override
  String get labelCustomGradient => '自定义渐变';

  @override
  String get labelGradientType => '类型';

  @override
  String get optionLinear => '线性';

  @override
  String get optionRadial => '径向';

  @override
  String get labelAngle => '角度';

  @override
  String get labelCenter => '中心';

  @override
  String get optionCenterCenter => '居中';

  @override
  String get optionCenterTopLeft => '左上';

  @override
  String get optionCenterTopRight => '右上';

  @override
  String get optionCenterBottomLeft => '左下';

  @override
  String get optionCenterBottomRight => '右下';

  @override
  String get labelColorStops => '色标';

  @override
  String get actionAddStop => '添加';

  @override
  String get actionDeleteStop => '删除';

  @override
  String get loginTitle => '登录';

  @override
  String get signupTitle => '注册';

  @override
  String get continueWithGoogle => '使用Google继续';

  @override
  String get continueWithApple => '使用Apple继续';

  @override
  String get loginWithEmail => '使用邮箱登录';

  @override
  String get useWithoutLogin => '不登录直接使用';

  @override
  String get orDivider => '或';

  @override
  String get noAccountYet => '还没有账号？';

  @override
  String get signUp => '注册';

  @override
  String get nickname => '昵称';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get passwordConfirm => '确认密码';

  @override
  String get passwordMinLength => '密码至少需要8个字符';

  @override
  String get passwordMismatch => '密码不匹配';

  @override
  String get invalidEmail => '请输入有效的邮箱地址';

  @override
  String get nicknameRequired => '请输入昵称';

  @override
  String get profileTitle => '我的资料';

  @override
  String get changePhoto => '更换头像';

  @override
  String get loginMethod => '登录方式';

  @override
  String get joinDate => '注册日期';

  @override
  String get syncStatus => '同步状态';

  @override
  String get synced => '已同步';

  @override
  String get syncing => '同步中...';

  @override
  String get syncError => '同步失败';

  @override
  String get lastSynced => '上次同步';

  @override
  String get justNow => '刚刚';

  @override
  String get manualSync => '手动同步';

  @override
  String get logout => '退出登录';

  @override
  String get deleteAccount => '删除账号';

  @override
  String get deleteAccountConfirm => '确定要删除账号吗？所有云端数据将被永久删除。';

  @override
  String get logoutConfirm => '确定要退出登录吗？本地数据将会保留。';

  @override
  String get accountSection => '账号';

  @override
  String get syncSection => '同步';

  @override
  String get loginPrompt => '登录';

  @override
  String get cloudSync => '云同步';

  @override
  String get cancel => '取消';

  @override
  String get labelSavePreset => '保存预设';

  @override
  String get hintPresetName => '预设名称';

  @override
  String get labelBoundaryShape => 'QR外框形状';

  @override
  String get labelAnimation => '动画';

  @override
  String get labelCustomDot => '自定义点阵';

  @override
  String get labelCustomEye => '自定义眼框';

  @override
  String get labelCustomBoundary => '自定义外框';

  @override
  String get labelCustomAnimation => '自定义动画';

  @override
  String get actionApply => '应用';

  @override
  String get sliderVertices => '顶点数';

  @override
  String get sliderInnerRadius => '内半径';

  @override
  String get sliderRoundness => '圆角';

  @override
  String get sliderRotation => '旋转';

  @override
  String get sliderDotScale => '大小';

  @override
  String get labelSymmetric => '对称';

  @override
  String get labelAsymmetric => '非对称';

  @override
  String get sliderSfM => '对称阶数 (m)';

  @override
  String get sliderSfN1 => '曲率 1';

  @override
  String get sliderSfN2 => '曲率 2';

  @override
  String get sliderSfN3 => '曲率 3';

  @override
  String get sliderSfA => 'X 缩放';

  @override
  String get sliderSfB => 'Y 缩放';

  @override
  String get sliderOuterN => '外框形状';

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
  String get labelBoundaryType => '外框类型';

  @override
  String get sliderSuperellipseN => '形状N值';

  @override
  String get sliderStarVertices => '星形顶点';

  @override
  String get sliderStarInnerRadius => '星形深度';

  @override
  String get sliderPadding => '内边距';

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
  String get sliderFrequency => '频率';

  @override
  String get optionLogoTypeLogo => '徽标';

  @override
  String get optionLogoTypeImage => '图片';

  @override
  String get optionLogoTypeText => '文本';

  @override
  String get labelLogoTabPosition => '位置';

  @override
  String get labelLogoTabBackground => '背景';

  @override
  String get labelLogoCategory => '类别';

  @override
  String get labelLogoGallery => '从相册选择';

  @override
  String get labelLogoRecrop => '重新裁剪';

  @override
  String get labelLogoTextContent => '文字';

  @override
  String get hintLogoTextContent => '徽标文字';

  @override
  String get categorySocial => '社交';

  @override
  String get categoryCoin => '币种';

  @override
  String get categoryBrand => '品牌';

  @override
  String get categoryEmoji => '表情';

  @override
  String get msgLogoLoadFailed => '无法加载图标';

  @override
  String get msgLogoCropFailed => '图像处理失败';

  @override
  String get labelLogoBackgroundColor => '颜色';

  @override
  String get actionLogoBackgroundReset => '默认';

  @override
  String get optionRectangle => '方形';

  @override
  String get optionRoundedRectangle => '圆形';

  @override
  String get labelLogoType => '类型';

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
