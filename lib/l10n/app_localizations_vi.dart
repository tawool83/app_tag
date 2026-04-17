// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Tạo mã QR & NFC';

  @override
  String get screenSplashSubtitle => 'Tạo và tùy chỉnh mã QR của riêng bạn';

  @override
  String get tileAppAndroid => 'Mở ứng dụng';

  @override
  String get tileAppIos => 'Phím tắt';

  @override
  String get tileClipboard => 'Bộ nhớ tạm';

  @override
  String get tileWebsite => 'Trang web';

  @override
  String get tileContact => 'Danh bạ';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => 'Vị trí';

  @override
  String get tileEvent => 'Sự kiện';

  @override
  String get tileEmail => 'Email';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'Tạo mã QR & NFC';

  @override
  String get screenHomeEditModeTitle => 'Chế độ chỉnh sửa';

  @override
  String get actionDone => 'Xong';

  @override
  String get actionCancel => 'Hủy';

  @override
  String get actionDelete => 'Xóa';

  @override
  String get actionSave => 'Lưu';

  @override
  String get actionShare => 'Chia sẻ';

  @override
  String get actionRetry => 'Thử lại';

  @override
  String get actionClose => 'Đóng';

  @override
  String get actionConfirm => 'OK';

  @override
  String get tooltipHelp => 'Hướng dẫn';

  @override
  String get tooltipHistory => 'Lịch sử';

  @override
  String get tooltipDeleteAll => 'Xóa tất cả';

  @override
  String get actionCollapseHidden => 'Thu gọn menu ẩn';

  @override
  String actionShowHidden(int count) {
    return 'Xem menu ẩn ($count)';
  }

  @override
  String get screenHelpTitle => 'Hướng dẫn';

  @override
  String get screenHistoryTitle => 'Lịch sử';

  @override
  String get screenHistoryEmpty => 'Chưa có lịch sử.';

  @override
  String get labelQrCode => 'Mã QR';

  @override
  String get labelNfcTag => 'Thẻ NFC';

  @override
  String get dialogClearAllTitle => 'Xóa tất cả';

  @override
  String get dialogClearAllContent => 'Bạn có muốn xóa tất cả lịch sử không?';

  @override
  String get dialogDeleteHistoryTitle => 'Xóa lịch sử';

  @override
  String dialogDeleteHistoryContent(String name) {
    return 'Bạn có muốn xóa lịch sử của \"$name\" không?';
  }

  @override
  String get screenWebsiteTitle => 'Thẻ trang web';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'Vui lòng nhập URL.';

  @override
  String get msgUrlInvalid => 'Vui lòng nhập URL hợp lệ.';

  @override
  String get screenWifiTitle => 'Thẻ WiFi';

  @override
  String get labelWifiSsid => 'Tên mạng (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'Vui lòng nhập SSID.';

  @override
  String get labelWifiSecurity => 'Bảo mật';

  @override
  String get optionWpa2 => 'WPA2 (Khuyến nghị)';

  @override
  String get optionNoSecurity => 'Không';

  @override
  String get labelWifiPassword => 'Mật khẩu';

  @override
  String get hintWifiPassword => 'Mật khẩu';

  @override
  String get screenSmsTitle => 'Thẻ SMS';

  @override
  String get labelPhoneRequired => 'Số điện thoại *';

  @override
  String get hintPhone => '090-000-0000';

  @override
  String get msgPhoneRequired => 'Vui lòng nhập số điện thoại.';

  @override
  String get labelMessageOptional => 'Tin nhắn (Tùy chọn)';

  @override
  String get hintSmsMessage => 'Nội dung tin nhắn';

  @override
  String get screenEmailTitle => 'Thẻ Email';

  @override
  String get labelEmailRequired => 'Địa chỉ email *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => 'Vui lòng nhập địa chỉ email.';

  @override
  String get msgEmailInvalid => 'Vui lòng nhập địa chỉ email hợp lệ.';

  @override
  String get labelEmailSubjectOptional => 'Tiêu đề (Tùy chọn)';

  @override
  String get hintEmailSubject => 'Tiêu đề email';

  @override
  String get labelEmailBodyOptional => 'Nội dung (Tùy chọn)';

  @override
  String get hintEmailBody => 'Nội dung email';

  @override
  String get screenContactTitle => 'Thẻ danh bạ';

  @override
  String get actionManualInput => 'Nhập thủ công';

  @override
  String get screenContactManualSubtitle =>
      'Nhập tên, số điện thoại và email thủ công';

  @override
  String get hintSearchByName => 'Tìm theo tên';

  @override
  String get labelNoPhone => 'Không có số điện thoại';

  @override
  String get msgContactPermissionRequired => 'Cần quyền truy cập danh bạ';

  @override
  String get msgContactPermissionHint =>
      'Sử dụng nhập thủ công hoặc cho phép quyền truy cập trong cài đặt.';

  @override
  String get actionOpenSettings => 'Mở Cài đặt';

  @override
  String get msgSearchNoResults => 'Không có kết quả tìm kiếm.';

  @override
  String get msgNoContacts => 'Không có danh bạ đã lưu.';

  @override
  String get screenContactManualTitle => 'Nhập thủ công';

  @override
  String get labelNameRequired => 'Tên *';

  @override
  String get hintName => 'Nguyễn Văn A';

  @override
  String get msgNameRequired => 'Vui lòng nhập tên.';

  @override
  String get labelPhone => 'Điện thoại';

  @override
  String get labelEmail => 'Email';

  @override
  String get screenLocationTitle => 'Thẻ vị trí';

  @override
  String get screenLocationTapHint => 'Chạm vào bản đồ để chọn vị trí.';

  @override
  String get msgSearchingAddress => 'Đang tìm địa chỉ...';

  @override
  String get msgAddressUnavailable => 'Không thể lấy địa chỉ.';

  @override
  String get labelPlaceNameOptional => 'Tên địa điểm (Tùy chọn)';

  @override
  String get hintPlaceName => 'Để trống sẽ tự động sử dụng tên tòa nhà.';

  @override
  String get msgSelectLocation => 'Vui lòng chọn vị trí trên bản đồ.';

  @override
  String get screenEventTitle => 'Thẻ sự kiện';

  @override
  String get labelEventTitleRequired => 'Tiêu đề sự kiện *';

  @override
  String get hintEventTitle => 'Tiêu đề sự kiện';

  @override
  String get msgEventTitleRequired => 'Vui lòng nhập tiêu đề.';

  @override
  String get labelEventStart => 'Bắt đầu';

  @override
  String get labelEventEnd => 'Kết thúc';

  @override
  String get labelEventLocationOptional => 'Địa điểm/Địa chỉ (Tùy chọn)';

  @override
  String get hintEventLocation => '123 Nguyễn Huệ, Q.1...';

  @override
  String get labelEventDescOptional => 'Mô tả (Tùy chọn)';

  @override
  String get hintEventDesc => 'Mô tả sự kiện';

  @override
  String get msgEventEndBeforeStart =>
      'Thời gian kết thúc phải sau thời gian bắt đầu.';

  @override
  String get screenClipboardTitle => 'Thẻ bộ nhớ tạm';

  @override
  String get msgClipboardEmpty => 'Bộ nhớ tạm trống. Vui lòng nhập văn bản.';

  @override
  String get labelContent => 'Nội dung';

  @override
  String get hintClipboardText => 'Văn bản để lưu vào thẻ';

  @override
  String get msgContentRequired => 'Vui lòng nhập nội dung.';

  @override
  String get screenIosInputTitle => 'Cài đặt khởi chạy App iOS';

  @override
  String get labelShortcutName => 'Tên phím tắt của ứng dụng cần khởi chạy';

  @override
  String get hintShortcutName => 'VD: Ứng dụng của tôi';

  @override
  String get msgAppNameRequired => 'Vui lòng nhập tên ứng dụng.';

  @override
  String get screenIosInputGuideTitle => 'Hướng dẫn cài đặt phím tắt';

  @override
  String get screenIosInputGuideSteps =>
      '1. Mở ứng dụng Phím tắt (Shortcuts) trên iPhone\n2. Tạo phím tắt mở ứng dụng mong muốn\n3. Lưu phím tắt với tên đã nhập ở trên\n4. Nhấn nút bên dưới để tạo QR/NFC';

  @override
  String get actionAppleShortcutsGuide =>
      'Hướng dẫn chính thức về Phím tắt Apple';

  @override
  String get screenAppPickerTitle => 'Chọn ứng dụng';

  @override
  String get hintAppSearch => 'Tìm ứng dụng...';

  @override
  String get msgAppListError => 'Không thể tải danh sách ứng dụng.';

  @override
  String get msgSelectApp => 'Vui lòng chọn một ứng dụng.';

  @override
  String get screenNfcWriterTitle => 'Ghi NFC';

  @override
  String get msgNfcWaiting => 'Đặt thẻ NFC gần\nmặt sau điện thoại';

  @override
  String get msgNfcSuccess => 'Ghi thành công!\nĐang quay về trang chủ...';

  @override
  String get msgNfcError => 'Ghi NFC thất bại.';

  @override
  String get labelNfcIncludeIos => 'Ghi kèm phím tắt iOS';

  @override
  String get labelIosShortcutName => 'Tên phím tắt iOS';

  @override
  String get hintIosShortcutName => 'VD: Zalo';

  @override
  String get screenOutputSelectorTitle => 'Chọn phương thức xuất';

  @override
  String get screenOutputQrDesc => 'Quét bằng camera để mở ứng dụng';

  @override
  String get screenOutputNfcDesc => 'Chạm thẻ để mở ứng dụng';

  @override
  String get msgNfcCheckFailed => 'Kiểm tra NFC thất bại';

  @override
  String get msgNfcSimulator => 'Không thể kiểm tra NFC trên trình giả lập';

  @override
  String get msgNfcNotSupported => 'Thiết bị này không hỗ trợ NFC';

  @override
  String get msgNfcWriteIosMin => 'Ghi NFC yêu cầu iPhone XS trở lên';

  @override
  String get msgNfcUnsupportedDevice => 'Thiết bị không hỗ trợ NFC';

  @override
  String get actionNfcWrite => 'Ghi thẻ NFC';

  @override
  String get screenQrResultTitle => 'Mã QR';

  @override
  String get tabTemplate => 'Mẫu';

  @override
  String get tabShape => 'Hình dạng';

  @override
  String get tabColor => 'Màu sắc';

  @override
  String get tabLogo => 'Logo';

  @override
  String get tabText => 'Văn bản';

  @override
  String get actionSaveGallery => 'Lưu vào Thư viện';

  @override
  String get actionSaveTemplate => 'Lưu mẫu';

  @override
  String get dialogLowReadabilityTitle => 'Khả năng đọc thấp';

  @override
  String dialogLowReadabilityScore(int score) {
    return 'Khả năng đọc hiện tại: $score%';
  }

  @override
  String get dialogLowReadabilityWarning =>
      'Mã QR có thể không được nhận dạng\nbởi một số máy quét.';

  @override
  String dialogLowReadabilityCause(String issue) {
    return 'Nguyên nhân chính: $issue';
  }

  @override
  String get actionSaveAnyway => 'Vẫn lưu';

  @override
  String get dialogSaveTemplateTitle => 'Lưu mẫu';

  @override
  String get labelTemplateName => 'Tên mẫu';

  @override
  String get hintTemplateName => 'VD: QR nền xanh';

  @override
  String msgTemplateSaved(String name) {
    return 'Mẫu \"$name\" đã được lưu.';
  }

  @override
  String get msgSaveFailed => 'Lưu ảnh thất bại.';

  @override
  String get msgPrintFailed => 'In thất bại. Vui lòng kiểm tra kết nối máy in.';

  @override
  String get labelReadability => 'Khả năng đọc';

  @override
  String get screenTemplateMyTemplates => 'Mẫu của tôi';

  @override
  String get actionNoStyle => 'Không có kiểu';

  @override
  String msgTemplateApplied(String name) {
    return 'Mẫu \"$name\" đã được áp dụng.';
  }

  @override
  String get dialogDeleteTemplateTitle => 'Xóa mẫu';

  @override
  String dialogDeleteTemplateContent(String name) {
    return 'Bạn có muốn xóa \"$name\" không?';
  }

  @override
  String get msgNoSavedTemplates => 'Chưa có mẫu đã lưu.';

  @override
  String get msgNoSavedTemplatesHint =>
      'Lưu kiểu hiện tại bằng nút [Lưu mẫu] bên dưới.';

  @override
  String get tabColorSolid => 'Đơn sắc';

  @override
  String get tabColorGradient => 'Chuyển màu';

  @override
  String get actionPickColor => 'Chọn màu';

  @override
  String get labelRecommendedColors => 'Màu gợi ý';

  @override
  String get labelGradientPresets => 'Mẫu chuyển màu';

  @override
  String get dialogColorPickerTitle => 'Chọn màu';

  @override
  String get labelDotShape => 'Hình dạng chấm';

  @override
  String get labelEyeOuter => 'Hình dạng mắt — Ngoài';

  @override
  String get labelEyeInner => 'Hình dạng mắt — Trong';

  @override
  String get shapeSquare => 'Vuông';

  @override
  String get shapeRounded => 'Bo tròn';

  @override
  String get shapeCircle => 'Tròn';

  @override
  String get shapeCircleRound => 'Tròn donut';

  @override
  String get shapeSmooth => 'Mượt';

  @override
  String get shapeDiamond => 'Kim cương';

  @override
  String get shapeStar => 'Ngôi sao';

  @override
  String get actionRandomRegenerate => 'Tạo ngẫu nhiên';

  @override
  String get actionRandomEye => 'Mắt ngẫu nhiên';

  @override
  String get actionClear => 'Xóa';

  @override
  String get labelShowIcon => 'Hiển thị biểu tượng';

  @override
  String get msgIconUnavailable =>
      'Chỉ hiển thị khi đã đặt biểu tượng ứng dụng hoặc emoji.';

  @override
  String get labelLogoPosition => 'Vị trí logo';

  @override
  String get optionCenter => 'Giữa';

  @override
  String get optionBottomRight => 'Dưới phải';

  @override
  String get labelLogoBackground => 'Nền logo';

  @override
  String get optionNone => 'Không';

  @override
  String get optionSquare => 'Vuông';

  @override
  String get optionCircle => 'Tròn';

  @override
  String get labelTopText => 'Văn bản trên';

  @override
  String get labelBottomText => 'Văn bản dưới';

  @override
  String get hintEnterText => 'Nhập văn bản';

  @override
  String get screenSettingsTitle => 'Cài đặt';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageSystem => 'Mặc định hệ thống';

  @override
  String msgCopiedToClipboard(String text) {
    return '\"$text\" đã sao chép vào bộ nhớ tạm';
  }

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';
}
