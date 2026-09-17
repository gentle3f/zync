class LocalizedDomainText {
  const LocalizedDomainText._();

  static const Map<String, Map<String, String>> _categories = {
    'sports': {
      'en': 'Sports', 'zh-Hant': '運動', 'zh-Hans': '运动', 'ja': 'スポーツ', 'ko': '스포츠',
      'es': 'Deportes', 'fr': 'Sports', 'pt': 'Esportes',
    },
    'wellness': {
      'en': 'Fitness & Wellness', 'zh-Hant': '健身與身心', 'zh-Hans': '健身与身心', 'ja': 'フィットネス', 'ko': '피트니스·웰니스',
      'es': 'Fitness y bienestar', 'fr': 'Fitness et bien-être', 'pt': 'Fitness e bem-estar',
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
      'en': 'Food & Drink', 'zh-Hant': '飲食', 'zh-Hans': '饮食', 'ja': 'グルメ', 'ko': '음식',
      'es': 'Comida', 'fr': 'Cuisine', 'pt': 'Comida',
    },
    'technology': {
      'en': 'Technology', 'zh-Hant': '科技', 'zh-Hans': '科技', 'ja': 'テクノロジー', 'ko': '기술',
      'es': 'Tecnología', 'fr': 'Technologie', 'pt': 'Tecnologia',
    },
    'science': {
      'en': 'Science', 'zh-Hant': '科學', 'zh-Hans': '科学', 'ja': '科学', 'ko': '과학',
      'es': 'Ciencia', 'fr': 'Sciences', 'pt': 'Ciência',
    },
    'arts': {
      'en': 'Arts & Photography', 'zh-Hant': '藝術與攝影', 'zh-Hans': '艺术与摄影', 'ja': 'アート・写真', 'ko': '예술·사진',
      'es': 'Arte y fotografía', 'fr': 'Arts et photo', 'pt': 'Arte e fotografia',
    },
    'crafts': {
      'en': 'Crafts & DIY', 'zh-Hant': '手作與 DIY', 'zh-Hans': '手作与 DIY', 'ja': 'クラフト・DIY', 'ko': '공예·DIY',
      'es': 'Manualidades y DIY', 'fr': 'Loisirs créatifs', 'pt': 'Artesanato e DIY',
    },
    'learning': {
      'en': 'Books & Learning', 'zh-Hant': '閱讀與學習', 'zh-Hans': '阅读与学习', 'ja': '読書・学び', 'ko': '독서·학습',
      'es': 'Lectura y aprendizaje', 'fr': 'Lecture et apprentissage', 'pt': 'Leitura e aprendizado',
    },
    'transport': {
      'en': 'Cars & Transport', 'zh-Hant': '汽車與交通', 'zh-Hans': '汽车与交通', 'ja': '車・交通', 'ko': '자동차·교통',
      'es': 'Coches y transporte', 'fr': 'Auto et transport', 'pt': 'Carros e transporte',
    },
    'outdoors': {
      'en': 'Outdoors & Adventure', 'zh-Hant': '戶外與冒險', 'zh-Hans': '户外与冒险', 'ja': 'アウトドア', 'ko': '아웃도어',
      'es': 'Aire libre', 'fr': 'Plein air', 'pt': 'Ar livre',
    },
    'collecting': {
      'en': 'Collecting', 'zh-Hant': '收藏', 'zh-Hans': '收藏', 'ja': 'コレクション', 'ko': '수집',
      'es': 'Coleccionismo', 'fr': 'Collection', 'pt': 'Colecionismo',
    },
    'fashion': {
      'en': 'Fashion & Beauty', 'zh-Hant': '時尚與美容', 'zh-Hans': '时尚与美容', 'ja': 'ファッション', 'ko': '패션·뷰티',
      'es': 'Moda y belleza', 'fr': 'Mode et beauté', 'pt': 'Moda e beleza',
    },
    'lifestyle': {
      'en': 'Lifestyle & Social', 'zh-Hant': '生活與社交', 'zh-Hans': '生活与社交', 'ja': 'ライフスタイル', 'ko': '라이프스타일',
      'es': 'Estilo de vida', 'fr': 'Style de vie', 'pt': 'Estilo de vida',
    },
    'pets': {
      'en': 'Pets & Animals', 'zh-Hant': '寵物與動物', 'zh-Hans': '宠物与动物', 'ja': 'ペット・動物', 'ko': '반려동물',
      'es': 'Mascotas y animales', 'fr': 'Animaux', 'pt': 'Pets e animais',
    },
    'business': {
      'en': 'Business & Money', 'zh-Hant': '商業與理財', 'zh-Hans': '商业与理财', 'ja': 'ビジネス', 'ko': '비즈니스',
      'es': 'Negocios y dinero', 'fr': 'Business et finance', 'pt': 'Negócios e finanças',
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

  static String allInterests(String locale) => _pick(locale, {
        'en': 'Popular', 'zh-Hant': '熱門', 'zh-Hans': '热门', 'ja': '人気', 'ko': '인기',
        'es': 'Popular', 'fr': 'Populaires', 'pt': 'Populares',
      });

  static String suggestedForYou(String locale) => _pick(locale, {
        'en': 'Suggested for you', 'zh-Hant': '你可能都鍾意', 'zh-Hans': '你可能也喜欢', 'ja': 'おすすめ', 'ko': '추천 관심사',
        'es': 'Sugerencias para ti', 'fr': 'Suggestions pour vous', 'pt': 'Sugestões para você',
      });

  static String popularInterests(String locale) => _pick(locale, {
        'en': 'Popular interests', 'zh-Hant': '熱門興趣', 'zh-Hans': '热门兴趣', 'ja': '人気の興味', 'ko': '인기 관심사',
        'es': 'Intereses populares', 'fr': 'Centres d’intérêt populaires', 'pt': 'Interesses populares',
      });

  static String addExactly(String value, String locale) => _pick(locale, {
        'en': 'Add “$value” instantly', 'zh-Hant': '直接加入「$value」', 'zh-Hans': '直接添加“$value”', 'ja': '「$value」をそのまま追加', 'ko': '“$value” 바로 추가',
        'es': 'Añadir “$value” al instante', 'fr': 'Ajouter « $value » immédiatement', 'pt': 'Adicionar “$value” agora',
      });

  static String noAiNeeded(String locale) => _pick(locale, {
        'en': 'No AI check needed', 'zh-Hant': '毋須 AI 驗證', 'zh-Hans': '无需 AI 验证', 'ja': 'AI確認は不要', 'ko': 'AI 확인 불필요',
        'es': 'No necesita verificación con IA', 'fr': 'Aucune vérification IA', 'pt': 'Sem verificação por IA',
      });

  static String catalogCount(int count, String locale) => _pick(locale, {
        'en': '$count interests available offline', 'zh-Hant': '內置 $count 個興趣，可離線即時搜尋', 'zh-Hans': '内置 $count 个兴趣，可离线即时搜索',
        'ja': '$count件をオフライン検索', 'ko': '$count개 관심사를 오프라인 검색',
        'es': '$count intereses disponibles sin conexión', 'fr': '$count intérêts disponibles hors ligne', 'pt': '$count interesses disponíveis offline',
      });

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

  static String _pick(String locale, Map<String, String> values) {
    final code = _localeCode(locale);
    return values[code] ?? values[code.split('-').first] ?? values['en']!;
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
