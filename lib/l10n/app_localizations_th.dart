// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'เครื่องสร้าง QR และ NFC';

  @override
  String get screenSplashSubtitle => 'สร้างและตกแต่ง QR โค้ดของคุณเอง';

  @override
  String get tileAppAndroid => 'เปิดแอป';

  @override
  String get tileAppIos => 'คำสั่งลัด';

  @override
  String get tileClipboard => 'คลิปบอร์ด';

  @override
  String get tileWebsite => 'เว็บไซต์';

  @override
  String get tileContact => 'ผู้ติดต่อ';

  @override
  String get tileWifi => 'WiFi';

  @override
  String get tileLocation => 'ตำแหน่ง';

  @override
  String get tileEvent => 'กิจกรรม';

  @override
  String get tileEmail => 'อีเมล';

  @override
  String get tileSms => 'SMS';

  @override
  String get screenHomeTitle => 'เครื่องสร้าง QR และ NFC';

  @override
  String get screenHomeEditModeTitle => 'โหมดแก้ไข';

  @override
  String get actionDone => 'เสร็จ';

  @override
  String get actionCancel => 'ยกเลิก';

  @override
  String get actionDelete => 'ลบ';

  @override
  String get actionSave => 'บันทึก';

  @override
  String get actionShare => 'แชร์';

  @override
  String get actionRetry => 'ลองอีกครั้ง';

  @override
  String get actionClose => 'ปิด';

  @override
  String get actionConfirm => 'ตกลง';

  @override
  String get tooltipHelp => 'คู่มือการใช้งาน';

  @override
  String get tooltipHistory => 'ประวัติ';

  @override
  String get tooltipDeleteAll => 'ลบทั้งหมด';

  @override
  String get actionCollapseHidden => 'ยุบเมนูที่ซ่อน';

  @override
  String actionShowHidden(int count) {
    return 'ดูเมนูที่ซ่อน ($count)';
  }

  @override
  String get screenHelpTitle => 'คู่มือการใช้งาน';

  @override
  String get screenHistoryTitle => 'ประวัติ';

  @override
  String get screenHistoryEmpty => 'ไม่มีประวัติ';

  @override
  String get labelQrCode => 'QR โค้ด';

  @override
  String get labelNfcTag => 'แท็ก NFC';

  @override
  String get dialogClearAllTitle => 'ลบทั้งหมด';

  @override
  String get dialogClearAllContent => 'คุณต้องการลบประวัติทั้งหมดหรือไม่?';

  @override
  String get dialogDeleteHistoryTitle => 'ลบประวัติ';

  @override
  String dialogDeleteHistoryContent(String name) {
    return 'คุณต้องการลบประวัติของ \"$name\" หรือไม่?';
  }

  @override
  String get screenWebsiteTitle => 'แท็กเว็บไซต์';

  @override
  String get labelUrl => 'URL';

  @override
  String get hintUrl => 'https://example.com';

  @override
  String get msgUrlRequired => 'กรุณาป้อน URL';

  @override
  String get msgUrlInvalid => 'กรุณาป้อน URL ที่ถูกต้อง';

  @override
  String get screenWifiTitle => 'แท็ก WiFi';

  @override
  String get labelWifiSsid => 'ชื่อเครือข่าย (SSID) *';

  @override
  String get hintWifiSsid => 'MyWiFi';

  @override
  String get msgSsidRequired => 'กรุณาป้อน SSID';

  @override
  String get labelWifiSecurity => 'ความปลอดภัย';

  @override
  String get optionWpa2 => 'WPA2 (แนะนำ)';

  @override
  String get optionNoSecurity => 'ไม่มี';

  @override
  String get labelWifiPassword => 'รหัสผ่าน';

  @override
  String get hintWifiPassword => 'รหัสผ่าน';

  @override
  String get screenSmsTitle => 'แท็ก SMS';

  @override
  String get labelPhoneRequired => 'หมายเลขโทรศัพท์ *';

  @override
  String get hintPhone => '080-000-0000';

  @override
  String get msgPhoneRequired => 'กรุณาป้อนหมายเลขโทรศัพท์';

  @override
  String get labelMessageOptional => 'ข้อความ (ไม่บังคับ)';

  @override
  String get hintSmsMessage => 'เนื้อหาข้อความ';

  @override
  String get screenEmailTitle => 'แท็กอีเมล';

  @override
  String get labelEmailRequired => 'ที่อยู่อีเมล *';

  @override
  String get hintEmail => 'example@email.com';

  @override
  String get msgEmailRequired => 'กรุณาป้อนที่อยู่อีเมล';

  @override
  String get msgEmailInvalid => 'กรุณาป้อนอีเมลที่ถูกต้อง';

  @override
  String get labelEmailSubjectOptional => 'หัวเรื่อง (ไม่บังคับ)';

  @override
  String get hintEmailSubject => 'หัวเรื่องอีเมล';

  @override
  String get labelEmailBodyOptional => 'เนื้อหา (ไม่บังคับ)';

  @override
  String get hintEmailBody => 'เนื้อหาอีเมล';

  @override
  String get screenContactTitle => 'แท็กผู้ติดต่อ';

  @override
  String get actionManualInput => 'ป้อนด้วยตนเอง';

  @override
  String get screenContactManualSubtitle =>
      'ป้อนชื่อ หมายเลขโทรศัพท์ และอีเมลด้วยตนเอง';

  @override
  String get hintSearchByName => 'ค้นหาตามชื่อ';

  @override
  String get labelNoPhone => 'ไม่มีหมายเลขโทรศัพท์';

  @override
  String get msgContactPermissionRequired => 'ต้องการสิทธิ์การเข้าถึงผู้ติดต่อ';

  @override
  String get msgContactPermissionHint =>
      'ใช้การป้อนด้วยตนเองหรืออนุญาตสิทธิ์ในการตั้งค่า';

  @override
  String get actionOpenSettings => 'เปิดการตั้งค่า';

  @override
  String get msgSearchNoResults => 'ไม่พบผลการค้นหา';

  @override
  String get msgNoContacts => 'ไม่มีผู้ติดต่อที่บันทึกไว้';

  @override
  String get screenContactManualTitle => 'ป้อนด้วยตนเอง';

  @override
  String get labelNameRequired => 'ชื่อ *';

  @override
  String get hintName => 'สมชาย ใจดี';

  @override
  String get msgNameRequired => 'กรุณาป้อนชื่อ';

  @override
  String get labelPhone => 'โทรศัพท์';

  @override
  String get labelEmail => 'อีเมล';

  @override
  String get screenLocationTitle => 'แท็กตำแหน่ง';

  @override
  String get screenLocationTapHint => 'แตะบนแผนที่เพื่อเลือกตำแหน่ง';

  @override
  String get msgSearchingAddress => 'กำลังค้นหาที่อยู่...';

  @override
  String get msgAddressUnavailable => 'ไม่สามารถดึงที่อยู่ได้';

  @override
  String get labelPlaceNameOptional => 'ชื่อสถานที่ (ไม่บังคับ)';

  @override
  String get hintPlaceName => 'เว้นว่างเพื่อใช้ชื่ออาคารโดยอัตโนมัติ';

  @override
  String get msgSelectLocation => 'กรุณาเลือกตำแหน่งบนแผนที่';

  @override
  String get screenEventTitle => 'แท็กกิจกรรม';

  @override
  String get labelEventTitleRequired => 'ชื่อกิจกรรม *';

  @override
  String get hintEventTitle => 'ชื่อกิจกรรม';

  @override
  String get msgEventTitleRequired => 'กรุณาป้อนชื่อ';

  @override
  String get labelEventStart => 'เริ่มต้น';

  @override
  String get labelEventEnd => 'สิ้นสุด';

  @override
  String get labelEventLocationOptional => 'สถานที่/ที่อยู่ (ไม่บังคับ)';

  @override
  String get hintEventLocation => 'ถนนสุขุมวิท กรุงเทพฯ...';

  @override
  String get labelEventDescOptional => 'คำอธิบาย (ไม่บังคับ)';

  @override
  String get hintEventDesc => 'คำอธิบายกิจกรรม';

  @override
  String get msgEventEndBeforeStart => 'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่มต้น';

  @override
  String get screenClipboardTitle => 'แท็กคลิปบอร์ด';

  @override
  String get msgClipboardEmpty => 'คลิปบอร์ดว่างเปล่า กรุณาป้อนข้อความ';

  @override
  String get labelContent => 'เนื้อหา';

  @override
  String get hintClipboardText => 'ข้อความที่จะบันทึกลงแท็ก';

  @override
  String get msgContentRequired => 'กรุณาป้อนเนื้อหา';

  @override
  String get screenIosInputTitle => 'ตั้งค่าเปิดแอป iOS';

  @override
  String get labelShortcutName => 'ชื่อคำสั่งลัดของแอปที่จะเปิด';

  @override
  String get hintShortcutName => 'เช่น: แอปของฉัน';

  @override
  String get msgAppNameRequired => 'กรุณาป้อนชื่อแอป';

  @override
  String get screenIosInputGuideTitle => 'คู่มือตั้งค่าคำสั่งลัด';

  @override
  String get screenIosInputGuideSteps =>
      '1. เปิดแอปคำสั่งลัด (Shortcuts) บน iPhone\n2. สร้างคำสั่งลัดที่เปิดแอปที่ต้องการ\n3. บันทึกคำสั่งลัดด้วยชื่อที่ป้อนด้านบน\n4. กดปุ่มด้านล่างเพื่อสร้าง QR/NFC';

  @override
  String get actionAppleShortcutsGuide =>
      'คู่มือคำสั่งลัด Apple อย่างเป็นทางการ';

  @override
  String get screenAppPickerTitle => 'เลือกแอป';

  @override
  String get hintAppSearch => 'ค้นหาแอป...';

  @override
  String get msgAppListError => 'ไม่สามารถโหลดรายการแอปได้';

  @override
  String get msgSelectApp => 'กรุณาเลือกแอป';

  @override
  String get screenNfcWriterTitle => 'เขียน NFC';

  @override
  String get msgNfcWaiting => 'วางแท็ก NFC ใกล้กับ\nด้านหลังโทรศัพท์';

  @override
  String get msgNfcSuccess => 'เขียนสำเร็จ!\nกำลังกลับหน้าหลัก...';

  @override
  String get msgNfcError => 'การเขียน NFC ล้มเหลว';

  @override
  String get labelNfcIncludeIos => 'เขียนคำสั่งลัด iOS ด้วย';

  @override
  String get labelIosShortcutName => 'ชื่อคำสั่งลัด iOS';

  @override
  String get hintIosShortcutName => 'เช่น: LINE';

  @override
  String get screenOutputSelectorTitle => 'เลือกวิธีส่งออก';

  @override
  String get screenOutputQrDesc => 'สแกนด้วยกล้องเพื่อเปิดแอป';

  @override
  String get screenOutputNfcDesc => 'แตะแท็กเพื่อเปิดแอป';

  @override
  String get msgNfcCheckFailed => 'การตรวจสอบ NFC ล้มเหลว';

  @override
  String get msgNfcSimulator => 'ไม่สามารถทดสอบ NFC บนตัวจำลองได้';

  @override
  String get msgNfcNotSupported => 'อุปกรณ์นี้ไม่รองรับ NFC';

  @override
  String get msgNfcWriteIosMin => 'การเขียน NFC ต้องใช้ iPhone XS ขึ้นไป';

  @override
  String get msgNfcUnsupportedDevice => 'อุปกรณ์ไม่รองรับ NFC';

  @override
  String get actionNfcWrite => 'เขียนแท็ก NFC';

  @override
  String get screenQrResultTitle => 'QR โค้ด';

  @override
  String get tabTemplate => 'เทมเพลต';

  @override
  String get tabShape => 'รูปทรง';

  @override
  String get tabColor => 'สี';

  @override
  String get tabLogo => 'โลโก้';

  @override
  String get tabText => 'ข้อความ';

  @override
  String get actionSaveGallery => 'บันทึกลงแกลเลอรี';

  @override
  String get actionSaveTemplate => 'บันทึกเทมเพลต';

  @override
  String get dialogLowReadabilityTitle => 'อัตราการอ่านต่ำ';

  @override
  String dialogLowReadabilityScore(int score) {
    return 'อัตราการอ่านปัจจุบัน: $score%';
  }

  @override
  String get dialogLowReadabilityWarning =>
      'QR โค้ดอาจไม่สามารถอ่านได้\nโดยเครื่องสแกนบางตัว';

  @override
  String dialogLowReadabilityCause(String issue) {
    return 'สาเหตุหลัก: $issue';
  }

  @override
  String get actionSaveAnyway => 'บันทึกอยู่ดี';

  @override
  String get dialogSaveTemplateTitle => 'บันทึกเทมเพลต';

  @override
  String get labelTemplateName => 'ชื่อเทมเพลต';

  @override
  String get hintTemplateName => 'เช่น: QR พื้นหลังสีฟ้า';

  @override
  String msgTemplateSaved(String name) {
    return 'เทมเพลต \"$name\" ถูกบันทึกแล้ว';
  }

  @override
  String get msgSaveFailed => 'บันทึกรูปภาพล้มเหลว';

  @override
  String get msgPrintFailed =>
      'พิมพ์ล้มเหลว กรุณาตรวจสอบการเชื่อมต่อเครื่องพิมพ์';

  @override
  String get labelReadability => 'อัตราการอ่าน';

  @override
  String get screenTemplateMyTemplates => 'เทมเพลตของฉัน';

  @override
  String get actionNoStyle => 'ไม่มีสไตล์';

  @override
  String msgTemplateApplied(String name) {
    return 'เทมเพลต \"$name\" ถูกนำไปใช้แล้ว';
  }

  @override
  String get dialogDeleteTemplateTitle => 'ลบเทมเพลต';

  @override
  String dialogDeleteTemplateContent(String name) {
    return 'คุณต้องการลบ \"$name\" หรือไม่?';
  }

  @override
  String get msgNoSavedTemplates => 'ไม่มีเทมเพลตที่บันทึกไว้';

  @override
  String get msgNoSavedTemplatesHint =>
      'บันทึกสไตล์ปัจจุบันด้วยปุ่ม [บันทึกเทมเพลต] ด้านล่าง';

  @override
  String get tabColorSolid => 'สีเดียว';

  @override
  String get tabColorGradient => 'ไล่สี';

  @override
  String get actionPickColor => 'เลือกสี';

  @override
  String get labelRecommendedColors => 'สีแนะนำ';

  @override
  String get labelGradientPresets => 'พรีเซ็ตไล่สี';

  @override
  String get dialogColorPickerTitle => 'เลือกสี';

  @override
  String get labelDotShape => 'รูปทรงจุด';

  @override
  String get labelEyeOuter => 'รูปทรงตา — ด้านนอก';

  @override
  String get labelEyeInner => 'รูปทรงตา — ด้านใน';

  @override
  String get shapeSquare => 'สี่เหลี่ยม';

  @override
  String get shapeRounded => 'มุมมน';

  @override
  String get shapeCircle => 'วงกลม';

  @override
  String get shapeCircleRound => 'วงกลมโดนัท';

  @override
  String get shapeSmooth => 'เรียบ';

  @override
  String get shapeDiamond => 'เพชร';

  @override
  String get shapeStar => 'ดาว';

  @override
  String get actionRandomRegenerate => 'สร้างใหม่แบบสุ่ม';

  @override
  String get actionRandomEye => 'รูปทรงตาแบบสุ่ม';

  @override
  String get actionClear => 'ล้าง';

  @override
  String get labelShowIcon => 'แสดงไอคอน';

  @override
  String get msgIconUnavailable =>
      'แสดงเฉพาะเมื่อตั้งค่าไอคอนแอปหรืออีโมจิแล้ว';

  @override
  String get labelLogoPosition => 'ตำแหน่งโลโก้';

  @override
  String get optionCenter => 'ตรงกลาง';

  @override
  String get optionBottomRight => 'ล่างขวา';

  @override
  String get labelLogoBackground => 'พื้นหลังโลโก้';

  @override
  String get optionNone => 'ไม่มี';

  @override
  String get optionSquare => 'สี่เหลี่ยม';

  @override
  String get optionCircle => 'วงกลม';

  @override
  String get labelTopText => 'ข้อความด้านบน';

  @override
  String get labelBottomText => 'ข้อความด้านล่าง';

  @override
  String get hintEnterText => 'ป้อนข้อความ';

  @override
  String get screenSettingsTitle => 'การตั้งค่า';

  @override
  String get settingsLanguage => 'ภาษา';

  @override
  String get settingsLanguageSystem => 'ค่าเริ่มต้นของระบบ';

  @override
  String msgCopiedToClipboard(String text) {
    return '\"$text\" คัดลอกไปยังคลิปบอร์ดแล้ว';
  }

  @override
  String get platformAndroid => 'Android';

  @override
  String get platformIos => 'iOS';
}
