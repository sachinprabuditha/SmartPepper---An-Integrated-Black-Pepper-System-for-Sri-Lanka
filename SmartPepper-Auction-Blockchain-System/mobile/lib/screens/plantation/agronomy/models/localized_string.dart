class LocalizedString {
  final String en;
  final String si;

  LocalizedString({
    required this.en,
    required this.si,
  });

  factory LocalizedString.fromJson(dynamic json) {
    if (json == null) {
      return LocalizedString(en: '', si: '');
    }
    if (json is String) {
      return LocalizedString(en: json, si: json);
    }
    if (json is Map<String, dynamic>) {
      return LocalizedString(
        en: json['en']?.toString() ?? '',
        si: json['si']?.toString() ?? '',
      );
    }
    return LocalizedString(en: '', si: '');
  }

  Map<String, dynamic> toJson() {
    return {'en': en, 'si': si};
  }

  String get(String languageCode) {
    switch (languageCode) {
      case 'si':
        return si.isNotEmpty ? si : en;
      case 'en':
      default:
        return en.isNotEmpty ? en : si;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizedString &&
          runtimeType == other.runtimeType &&
          en == other.en &&
          si == other.si;

  @override
  int get hashCode => en.hashCode ^ si.hashCode;
}
