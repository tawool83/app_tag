class TagPayloadEncoder {
  TagPayloadEncoder._();

  static String clipboard(String text) => text;

  static String website(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  static String contact({
    required String name,
    String? phone,
    String? email,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:$name');
    if (phone != null && phone.isNotEmpty) buffer.writeln('TEL:$phone');
    if (email != null && email.isNotEmpty) buffer.writeln('EMAIL:$email');
    buffer.write('END:VCARD');
    return buffer.toString();
  }

  static String wifi({
    required String ssid,
    required String securityType,
    String? password,
  }) {
    final pw = (password != null && password.isNotEmpty) ? password : '';
    return 'WIFI:T:$securityType;S:$ssid;P:$pw;;';
  }

  static String location({
    required double lat,
    required double lng,
    String? label,
  }) {
    if (label != null && label.isNotEmpty) {
      return 'https://maps.google.com/?q=${Uri.encodeComponent(label)}&ll=$lat,$lng';
    }
    return 'geo:$lat,$lng';
  }

  static String event({
    required String title,
    required DateTime start,
    required DateTime end,
    String? location,
    String? description,
  }) {
    String fmt(DateTime dt) =>
        '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}00';
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('SUMMARY:$title');
    buffer.writeln('DTSTART:${fmt(start)}');
    buffer.writeln('DTEND:${fmt(end)}');
    if (location != null && location.isNotEmpty) {
      buffer.writeln('LOCATION:$location');
    }
    if (description != null && description.isNotEmpty) {
      buffer.writeln('DESCRIPTION:$description');
    }
    buffer.writeln('END:VEVENT');
    buffer.write('END:VCALENDAR');
    return buffer.toString();
  }

  static String email({
    required String address,
    String? subject,
    String? body,
  }) {
    final params = <String>[];
    if (subject != null && subject.isNotEmpty) {
      params.add('subject=${Uri.encodeComponent(subject)}');
    }
    if (body != null && body.isNotEmpty) {
      params.add('body=${Uri.encodeComponent(body)}');
    }
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return 'mailto:$address$query';
  }

  static String sms({required String phone, String? message}) {
    if (message != null && message.isNotEmpty) return 'smsto:$phone:$message';
    return 'sms:$phone';
  }
}
