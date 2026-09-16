class LocalizedDomainText {
  const LocalizedDomainText._();

  static const Map<String, Map<String, String>> _categories = {
    'sports': {
      'en': 'Sports', 'zh-Hant': '運動', 'zh-Hans': '运动', 'ja': 'スポーツ', 'ko': '스포츠',
      'es': 'Deportes', 'fr': 'Sports', 'pt': 'Esportes',
    },
    'motorsport': {
      'en': 'Motorsport', 'zh-Hant': '賽車運動', 'zh-Hans': '赛车运动', 'ja': 'モータースポーツ', 'ko': '모터스포츠',
      'es': 'Automovilismo', 'fr': 'Sports mécaniques', 'pt': 'Automobilismo',
    },
    'entertainment': {
      'en': 'Entertainment', 'zh-Hant': '娛樂', 'zh-Hans': '娱乐', 'ja': 'エンタメ', 'ko': '엔터테인먼트',
      'es': 'Entretenimiento', 'fr': 'Divertissement', 'pt': 'Entretenimento',
    },
    'gaming': {
      'en': 'Gaming', 'zh-Hant': '遊戲', 'zh-Hans': '游戏', 'ja': 'ゲーム', 'ko': '게임',
      'es': 'Juegos', 'fr': 'Jeux', 'pt': 'Jogos',
    },
    'music': {
      'en': 'Music', 'zh-Hant': '音樂', 'zh-Hans': '音乐', 'ja': '音楽', 'ko': '음악',
      'es': 'Música', 'fr': 'Musique', 'pt': 'Música',
    },
    'travel': {
      'en': 'Travel', 'zh-Hant': '旅行', 'zh-Hans': '旅行', 'ja': '旅行', 'ko': '여행',
      'es': 'Viajes', 'fr': 'Voyage', 'pt': 'Viagens',
    },
    'food': {
      'en': 'Food', 'zh-Hant': '飲食', 'zh-Hans': '饮食', 'ja': 'グルメ', 'ko': '음식',
      'es': 'Comida', 'fr': 'Cuisine', 'pt': 'Comida',
    },
    'technology': {
      'en': 'Technology', 'zh-Hant': '科技', 'zh-Hans': '科技', 'ja': 'テクノロジー', 'ko': '기술',
      'es': 'Tecnología', 'fr': 'Technologie', 'pt': 'Tecnologia',
    },
    'arts': {
      'en': 'Arts', 'zh-Hant': '藝術', 'zh-Hans': '艺术', 'ja': 'アート', 'ko': '예술',
      'es': 'Arte', 'fr': 'Arts', 'pt': 'Artes',
    },
    'learning': {
      'en': 'Learning', 'zh-Hant': '學習', 'zh-Hans': '学习', 'ja': '学び', 'ko': '학습',
      'es': 'Aprendizaje', 'fr': 'Apprentissage', 'pt': 'Aprendizado',
    },
    'transport': {
      'en': 'Transport', 'zh-Hant': '交通', 'zh-Hans': '交通', 'ja': '交通', 'ko': '교통',
      'es': 'Transporte', 'fr': 'Transport', 'pt': 'Transporte',
    },
    'outdoors': {
      'en': 'Outdoors', 'zh-Hant': '戶外', 'zh-Hans': '户外', 'ja': 'アウトドア', 'ko': '아웃도어',
      'es': 'Aire libre', 'fr': 'Plein air', 'pt': 'Ar livre',
    },
    'collecting': {
      'en': 'Collecting', 'zh-Hant': '收藏', 'zh-Hans': '收藏', 'ja': 'コレクション', 'ko': '수집',
      'es': 'Coleccionismo', 'fr': 'Collection', 'pt': 'Colecionismo',
    },
    'other': {
      'en': 'Other', 'zh-Hant': '其他', 'zh-Hans': '其他', 'ja': 'その他', 'ko': '기타',
      'es': 'Otros', 'fr': 'Autres', 'pt': 'Outros',
    },
  };

  static String category(String raw, String locale) {
    final key = raw.trim().toLowerCase();
    final labels = _categories[key];
    if (labels == null) return _titleize(raw);
    final code = _localeCode(locale);
    return labels[code] ?? labels[code.split('-').first] ?? labels['en']!;
  }

  static String historyMeta({
    required int matches,
    required int sessions,
    required String locale,
  }) {
    return switch (_localeCode(locale)) {
      'zh-Hant' => '$matches 個共同興趣 · $sessions 次 Zync',
      'zh-Hans' => '$matches 个共同兴趣 · $sessions 次 Zync',
      'ja' => '$matches件の共通点 · $sessions回のZync',
      'ko' => '공통 관심사 $matches개 · Zync $sessions회',
      'es' => '$matches coincidencias · $sessions Zync',
      'fr' => '$matches points communs · $sessions Zync',
      'pt' => '$matches conexões · $sessions Zync',
      _ => '$matches matches · $sessions Zyncs',
    };
  }

  static String _localeCode(String locale) {
    final normalized = locale.replaceAll('_', '-');
    final lower = normalized.toLowerCase();
    if (lower.startsWith('zh')) {
      if (lower.contains('hant') || lower.contains('-hk') || lower.contains('-tw') || lower.contains('-mo')) {
        return 'zh-Hant';
      }
      return 'zh-Hans';
    }
    return normalized.split('-').first;
  }

  static String _titleize(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[-_]+'), ' ');
    if (cleaned.isEmpty) return 'Other';
    return cleaned
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
