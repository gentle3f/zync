class ZyncLanguage {
  const ZyncLanguage._();

  static String canonical(String raw) {
    final normalized = raw.trim().replaceAll('_', '-').toLowerCase();
    if (normalized.startsWith('zh')) {
      if (normalized.contains('hans') || normalized.contains('-cn') || normalized.contains('-sg')) {
        return 'zh-Hans';
      }
      return 'zh-Hant';
    }
    if (normalized.startsWith('ja')) return 'ja';
    if (normalized.startsWith('ko')) return 'ko';
    if (normalized.startsWith('es')) return 'es';
    if (normalized.startsWith('fr')) return 'fr';
    if (normalized.startsWith('pt')) return 'pt';
    return 'en';
  }

  static bool needsSecondary(String primary, String peer) => canonical(primary) != canonical(peer);

  static String nativeName(String raw) => switch (canonical(raw)) {
        'zh-Hant' => '繁體中文',
        'zh-Hans' => '简体中文',
        'ja' => '日本語',
        'ko' => '한국어',
        'es' => 'Español',
        'fr' => 'Français',
        'pt' => 'Português',
        _ => 'English',
      };
}
