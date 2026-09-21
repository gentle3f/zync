class LocalizedDomainText {
  const LocalizedDomainText._();

  static const Map<String, Map<String, String>> _categories = {
    'sports': {'en':'Sports','zh-Hant':'運動','zh-Hans':'运动','ja':'スポーツ','ko':'스포츠','es':'Deportes','fr':'Sports','pt':'Esportes'},
    'wellness': {'en':'Fitness & Wellness','zh-Hant':'健身與身心','zh-Hans':'健身与身心','ja':'フィットネス','ko':'피트니스·웰니스','es':'Fitness y bienestar','fr':'Fitness et bien-être','pt':'Fitness e bem-estar'},
    'motorsport': {'en':'Motorsport','zh-Hant':'賽車運動','zh-Hans':'赛车运动','ja':'モータースポーツ','ko':'모터스포츠','es':'Automovilismo','fr':'Sports mécaniques','pt':'Automobilismo'},
    'entertainment': {'en':'Entertainment','zh-Hant':'娛樂','zh-Hans':'娱乐','ja':'エンタメ','ko':'엔터테인먼트','es':'Entretenimiento','fr':'Divertissement','pt':'Entretenimento'},
    'gaming': {'en':'Gaming','zh-Hant':'遊戲','zh-Hans':'游戏','ja':'ゲーム','ko':'게임','es':'Juegos','fr':'Jeux','pt':'Jogos'},
    'music': {'en':'Music','zh-Hant':'音樂','zh-Hans':'音乐','ja':'音楽','ko':'음악','es':'Música','fr':'Musique','pt':'Música'},
    'travel': {'en':'Travel','zh-Hant':'旅行','zh-Hans':'旅行','ja':'旅行','ko':'여행','es':'Viajes','fr':'Voyage','pt':'Viagens'},
    'food': {'en':'Food & Drink','zh-Hant':'飲食','zh-Hans':'饮食','ja':'グルメ','ko':'음식','es':'Comida','fr':'Cuisine','pt':'Comida'},
    'technology': {'en':'Technology','zh-Hant':'科技','zh-Hans':'科技','ja':'テクノロジー','ko':'기술','es':'Tecnología','fr':'Technologie','pt':'Tecnologia'},
    'science': {'en':'Science','zh-Hant':'科學','zh-Hans':'科学','ja':'科学','ko':'과학','es':'Ciencia','fr':'Sciences','pt':'Ciência'},
    'arts': {'en':'Arts & Photography','zh-Hant':'藝術與攝影','zh-Hans':'艺术与摄影','ja':'アート・写真','ko':'예술·사진','es':'Arte y fotografía','fr':'Arts et photo','pt':'Arte e fotografia'},
    'crafts': {'en':'Crafts & DIY','zh-Hant':'手作與 DIY','zh-Hans':'手作与 DIY','ja':'クラフト・DIY','ko':'공예·DIY','es':'Manualidades y DIY','fr':'Loisirs créatifs','pt':'Artesanato e DIY'},
    'learning': {'en':'Books & Learning','zh-Hant':'閱讀與學習','zh-Hans':'阅读与学习','ja':'読書・学び','ko':'독서·학습','es':'Lectura y aprendizaje','fr':'Lecture et apprentissage','pt':'Leitura e aprendizado'},
    'transport': {'en':'Cars & Transport','zh-Hant':'汽車與交通','zh-Hans':'汽车与交通','ja':'車・交通','ko':'자동차·교통','es':'Coches y transporte','fr':'Auto et transport','pt':'Carros e transporte'},
    'outdoors': {'en':'Outdoors & Adventure','zh-Hant':'戶外與冒險','zh-Hans':'户外与冒险','ja':'アウトドア','ko':'아웃도어','es':'Aire libre','fr':'Plein air','pt':'Ar livre'},
    'collecting': {'en':'Collecting','zh-Hant':'收藏','zh-Hans':'收藏','ja':'コレクション','ko':'수집','es':'Coleccionismo','fr':'Collection','pt':'Colecionismo'},
    'fashion': {'en':'Fashion & Beauty','zh-Hant':'時尚與美容','zh-Hans':'时尚与美容','ja':'ファッション','ko':'패션·뷰티','es':'Moda y belleza','fr':'Mode et beauté','pt':'Moda e beleza'},
    'lifestyle': {'en':'Lifestyle & Social','zh-Hant':'生活與社交','zh-Hans':'生活与社交','ja':'ライフスタイル','ko':'라이프스타일','es':'Estilo de vida','fr':'Style de vie','pt':'Estilo de vida'},
    'pets': {'en':'Pets & Animals','zh-Hant':'寵物與動物','zh-Hans':'宠物与动物','ja':'ペット・動物','ko':'반려동물','es':'Mascotas y animales','fr':'Animaux','pt':'Pets e animais'},
    'business': {'en':'Business & Money','zh-Hant':'商業與理財','zh-Hans':'商业与理财','ja':'ビジネス','ko':'비즈니스','es':'Negocios y dinero','fr':'Business et finance','pt':'Negócios e finanças'},
    'other': {'en':'Other','zh-Hant':'其他','zh-Hans':'其他','ja':'その他','ko':'기타','es':'Otros','fr':'Autres','pt':'Outros'},
  };

  static const Map<String, Map<String, String>> _taxonomy = {
    'ai': {'en':'AI','zh-Hant':'人工智能','zh-Hans':'人工智能'},
    'building_toys': {'en':'Building Toys','zh-Hant':'積木與拼砌玩具','zh-Hans':'积木与拼搭玩具'},
    'business': {'en':'Business','zh-Hant':'商業','zh-Hans':'商业'},
    'camping': {'en':'Camping','zh-Hant':'露營','zh-Hans':'露营'},
    'cars': {'en':'Cars','zh-Hant':'汽車','zh-Hans':'汽车'},
    'collecting': {'en':'Collecting','zh-Hant':'收藏','zh-Hans':'收藏'},
    'combat': {'en':'Combat Sports','zh-Hant':'格鬥運動','zh-Hans':'格斗运动'},
    'crafts': {'en':'Crafts & DIY','zh-Hant':'手作與 DIY','zh-Hans':'手作与 DIY'},
    'cycling': {'en':'Cycling','zh-Hant':'單車','zh-Hans':'骑行'},
    'fashion': {'en':'Fashion','zh-Hant':'時尚','zh-Hans':'时尚'},
    'fitness': {'en':'Fitness','zh-Hant':'健身','zh-Hans':'健身'},
    'gadgets': {'en':'Gadgets','zh-Hant':'電子裝置','zh-Hans':'电子设备'},
    'hiking': {'en':'Hiking','zh-Hant':'行山與遠足','zh-Hans':'徒步与远足'},
    'history': {'en':'History','zh-Hant':'歷史','zh-Hans':'历史'},
    'home': {'en':'Home & Living','zh-Hant':'家居生活','zh-Hans':'家居生活'},
    'knowledge': {'en':'Knowledge & Ideas','zh-Hant':'知識與思辨','zh-Hans':'知识与思辨'},
    'languages': {'en':'Languages','zh-Hant':'語言','zh-Hans':'语言'},
    'mind_body': {'en':'Mind & Body','zh-Hant':'身心運動','zh-Hans':'身心运动'},
    'mind_sports': {'en':'Mind Sports','zh-Hant':'智力運動','zh-Hans':'智力运动'},
    'motorsport': {'en':'Motorsport','zh-Hant':'賽車運動','zh-Hans':'赛车运动'},
    'pets': {'en':'Pets & Animals','zh-Hant':'寵物與動物','zh-Hans':'宠物与动物'},
    'photography': {'en':'Photography','zh-Hant':'攝影','zh-Hans':'摄影'},
    'precision': {'en':'Precision Sports','zh-Hant':'精準運動','zh-Hans':'精准运动'},
    'racket': {'en':'Racket Sports','zh-Hant':'球拍運動','zh-Hans':'球拍运动'},
    'railways': {'en':'Railways','zh-Hant':'鐵路','zh-Hans':'铁路'},
    'running': {'en':'Running','zh-Hant':'跑步','zh-Hans':'跑步'},
    'science': {'en':'Science','zh-Hant':'科學','zh-Hans':'科学'},
    'skating': {'en':'Skating','zh-Hant':'滑冰與輪滑','zh-Hans':'滑冰与轮滑'},
    'social': {'en':'Social & Activities','zh-Hant':'社交活動','zh-Hans':'社交活动'},
    'software': {'en':'Software & Coding','zh-Hant':'軟件與編程','zh-Hans':'软件与编程'},
    'team_ball': {'en':'Team Ball Sports','zh-Hant':'團隊球類','zh-Hans':'团队球类'},
    'title': {'en':'Titles','zh-Hant':'作品','zh-Hans':'作品'},
    'visual_art': {'en':'Visual Art','zh-Hant':'視覺藝術','zh-Hans':'视觉艺术'},
    'watches': {'en':'Watches','zh-Hant':'手錶','zh-Hans':'手表'},
    'water': {'en':'Water Sports','zh-Hant':'水上運動','zh-Hans':'水上运动'},
    'winter': {'en':'Winter Sports','zh-Hant':'冬季運動','zh-Hans':'冬季运动'},
    'movies': {'en':'Movies','zh-Hant':'電影','zh-Hans':'电影','ja':'映画','ko':'영화','es':'Películas','fr':'Films','pt':'Filmes'},
    'tv_drama': {'en':'TV & Drama','zh-Hant':'電視與劇集','zh-Hans':'电视与剧集','ja':'TV・ドラマ','ko':'TV·드라마','es':'TV y series','fr':'TV et séries','pt':'TV e séries'},
    'anime_manga': {'en':'Anime & Manga','zh-Hant':'動漫與漫畫','zh-Hans':'动漫与漫画','ja':'アニメ・漫画','ko':'애니·만화','es':'Anime y manga','fr':'Anime et manga','pt':'Anime e mangá'},
    'franchises': {'en':'Franchises','zh-Hant':'系列與世界觀','zh-Hans':'系列与世界观','ja':'シリーズ','ko':'프랜차이즈','es':'Franquicias','fr':'Franchises','pt':'Franquias'},
    'video_games': {'en':'Video Games','zh-Hant':'電子遊戲','zh-Hans':'电子游戏','ja':'ビデオゲーム','ko':'비디오 게임','es':'Videojuegos','fr':'Jeux vidéo','pt':'Videogames'},
    'tabletop': {'en':'Tabletop','zh-Hant':'桌遊與TRPG','zh-Hans':'桌游与TRPG','ja':'ボードゲーム・TRPG','ko':'보드게임·TRPG','es':'Juegos de mesa','fr':'Jeux de table','pt':'Jogos de mesa'},
    'genres_styles': {'en':'Genres & Styles','zh-Hant':'曲風與類型','zh-Hans':'曲风与类型','ja':'ジャンル・スタイル','ko':'장르·스타일','es':'Géneros y estilos','fr':'Genres et styles','pt':'Gêneros e estilos'},
    'artists': {'en':'Artists','zh-Hant':'歌手與樂隊','zh-Hans':'歌手与乐队','ja':'アーティスト','ko':'아티스트','es':'Artistas','fr':'Artistes','pt':'Artistas'},
    'making': {'en':'Making & Playing','zh-Hant':'演奏與創作','zh-Hans':'演奏与创作','ja':'演奏・制作','ko':'연주·제작','es':'Interpretación y creación','fr':'Pratique et création','pt':'Tocar e criar'},
    'books': {'en':'Books','zh-Hant':'書籍','zh-Hans':'书籍','ja':'本','ko':'책','es':'Libros','fr':'Livres','pt':'Livros'},
    'cuisines': {'en':'Cuisines','zh-Hant':'菜系','zh-Hans':'菜系','ja':'料理ジャンル','ko':'요리 종류','es':'Cocinas','fr':'Cuisines','pt':'Culinárias'},
    'dishes': {'en':'Dishes','zh-Hant':'料理與菜式','zh-Hans':'料理与菜式','ja':'料理','ko':'음식','es':'Platos','fr':'Plats','pt':'Pratos'},
    'drinks': {'en':'Drinks','zh-Hant':'飲品','zh-Hans':'饮品','ja':'ドリンク','ko':'음료','es':'Bebidas','fr':'Boissons','pt':'Bebidas'},
    'cooking': {'en':'Cooking','zh-Hant':'烹飪','zh-Hans':'烹饪','ja':'料理・調理','ko':'요리','es':'Cocina','fr':'Cuisine','pt':'Culinária'},
    'destinations': {'en':'Destinations','zh-Hant':'目的地','zh-Hans':'目的地','ja':'旅行先','ko':'여행지','es':'Destinos','fr':'Destinations','pt':'Destinos'},
    'styles': {'en':'Travel Styles','zh-Hant':'旅行方式','zh-Hans':'旅行方式','ja':'旅のスタイル','ko':'여행 스타일','es':'Estilos de viaje','fr':'Styles de voyage','pt':'Estilos de viagem'},
    'general': {'en':'General','zh-Hant':'綜合','zh-Hans':'综合','ja':'一般','ko':'일반','es':'General','fr':'Général','pt':'Geral'},
    'subgenres': {'en':'Genres & Subgenres','zh-Hant':'類型與細分類','zh-Hans':'类型与细分类','ja':'ジャンル','ko':'장르','es':'Géneros','fr':'Genres','pt':'Gêneros'},
    'classics': {'en':'Classics','zh-Hant':'經典','zh-Hans':'经典','ja':'クラシック','ko':'고전','es':'Clásicos','fr':'Classiques','pt':'Clássicos'},
    'modern_evergreen': {'en':'Modern Favorites','zh-Hant':'現代長青作品','zh-Hans':'现代长青作品','ja':'現代の名作','ko':'현대 명작','es':'Favoritos modernos','fr':'Classiques modernes','pt':'Favoritos modernos'},
    'drama': {'en':'Drama Series','zh-Hant':'劇集','zh-Hans':'剧集','ja':'ドラマ','ko':'드라마','es':'Series dramáticas','fr':'Séries dramatiques','pt':'Séries dramáticas'},
    'comedy_variety': {'en':'Comedy & Variety','zh-Hant':'喜劇、綜藝與真人秀','zh-Hans':'喜剧、综艺与真人秀','ja':'コメディ・バラエティ','ko':'코미디·예능','es':'Comedia y variedades','fr':'Comédie et variété','pt':'Comédia e variedades'},
    'titles_franchises': {'en':'Titles & Franchises','zh-Hant':'作品與系列','zh-Hans':'作品与系列','ja':'作品・シリーズ','ko':'작품·시리즈','es':'Títulos y franquicias','fr':'Titres et franchises','pt':'Títulos e franquias'},
    'categories_mechanics': {'en':'Types & Mechanics','zh-Hant':'類型與機制','zh-Hans':'类型与机制','ja':'種類・メカニクス','ko':'유형·메커니즘','es':'Tipos y mecánicas','fr':'Types et mécaniques','pt':'Tipos e mecânicas'},
    'boardgame_titles': {'en':'Board Game Titles','zh-Hant':'桌遊作品','zh-Hans':'桌游作品','ja':'ボードゲーム作品','ko':'보드게임 타이틀','es':'Juegos de mesa','fr':'Titres de jeux','pt':'Títulos de jogos'},
    'ttrpg': {'en':'Tabletop RPG','zh-Hant':'桌上角色扮演','zh-Hans':'桌上角色扮演','ja':'TRPG','ko':'TRPG','es':'Rol de mesa','fr':'JDR sur table','pt':'RPG de mesa'},
    'artists_global': {'en':'Global Artists','zh-Hant':'國際歌手與樂隊','zh-Hans':'国际歌手与乐队','ja':'海外アーティスト','ko':'글로벌 아티스트','es':'Artistas globales','fr':'Artistes internationaux','pt':'Artistas globais'},
    'kpop_artists': {'en':'K-Pop Artists','zh-Hant':'K-Pop 歌手','zh-Hans':'K-Pop 歌手','ja':'K-Popアーティスト','ko':'K-Pop 아티스트','es':'Artistas K-Pop','fr':'Artistes K-Pop','pt':'Artistas K-Pop'},
    'japanese_artists': {'en':'Japanese Artists','zh-Hant':'日本歌手與樂隊','zh-Hans':'日本歌手与乐队','ja':'日本のアーティスト','ko':'일본 아티스트','es':'Artistas japoneses','fr':'Artistes japonais','pt':'Artistas japoneses'},
    'hk_cantopop': {'en':'Hong Kong / Cantopop','zh-Hant':'香港與廣東歌','zh-Hans':'香港与粤语歌','ja':'香港・C-Pop','ko':'홍콩·캔토팝','es':'Hong Kong / Cantopop','fr':'Hong Kong / Cantopop','pt':'Hong Kong / Cantopop'},
    'mandopop_artists': {'en':'Mandopop Artists','zh-Hant':'華語歌手與樂隊','zh-Hans':'华语歌手与乐队','ja':'Mandopopアーティスト','ko':'만도팝 아티스트','es':'Artistas Mandopop','fr':'Artistes Mandopop','pt':'Artistas Mandopop'},
    'evergreen_titles': {'en':'Evergreen Titles','zh-Hant':'長青作品','zh-Hans':'长青作品','ja':'名作','ko':'명작','es':'Títulos clásicos','fr':'Titres incontournables','pt':'Títulos clássicos'},
  };

  static String category(String raw, String locale) {
    final key = raw.trim().toLowerCase();
    final labels = _categories[key];
    if (labels == null) return _titleize(raw);
    final code = _localeCode(locale);
    return labels[code] ?? labels[code.split('-').first] ?? labels['en']!;
  }

  static bool hasTaxonomyTranslation(String raw, String locale) {
    final key = raw.trim().toLowerCase();
    final labels = _taxonomy[key];
    if (labels == null) return false;
    final code = _localeCode(locale);
    return (labels[code]?.trim().isNotEmpty ?? false) ||
        (labels[code.split('-').first]?.trim().isNotEmpty ?? false);
  }

  static String taxonomy(String raw, String locale) {
    final key = raw.trim().toLowerCase();
    final labels = _taxonomy[key];
    if (labels == null) return _titleize(raw);
    final code = _localeCode(locale);
    return labels[code] ?? labels[code.split('-').first] ?? labels['en']!;
  }

  static String allInterests(String locale) => _pick(locale, {
        'en':'Popular','zh-Hant':'熱門','zh-Hans':'热门','ja':'人気','ko':'인기','es':'Popular','fr':'Populaires','pt':'Populares',
      });

  static String allInSection(String locale) => _pick(locale, {
        'en':'All','zh-Hant':'全部','zh-Hans':'全部','ja':'すべて','ko':'전체','es':'Todo','fr':'Tout','pt':'Tudo',
      });

  static String suggestedForYou(String locale) => _pick(locale, {
        'en':'Suggested for you','zh-Hant':'你可能都鍾意','zh-Hans':'你可能也喜欢','ja':'おすすめ','ko':'추천 관심사','es':'Sugerencias para ti','fr':'Suggestions pour vous','pt':'Sugestões para você',
      });

  static String popularInterests(String locale) => _pick(locale, {
        'en':'Popular interests','zh-Hant':'熱門興趣','zh-Hans':'热门兴趣','ja':'人気の興味','ko':'인기 관심사','es':'Intereses populares','fr':'Centres d’intérêt populaires','pt':'Interesses populares',
      });

  static String addExactly(String value, String locale) => _pick(locale, {
        'en':'Add “$value” instantly','zh-Hant':'直接加入「$value」','zh-Hans':'直接添加“$value”','ja':'「$value」をそのまま追加','ko':'“$value” 바로 추가','es':'Añadir “$value” al instante','fr':'Ajouter « $value » immédiatement','pt':'Adicionar “$value” agora',
      });

  static String noAiNeeded(String locale) => _pick(locale, {
        'en':'No AI check needed','zh-Hant':'毋須 AI 驗證','zh-Hans':'无需 AI 验证','ja':'AI確認は不要','ko':'AI 확인 불필요','es':'No necesita verificación con IA','fr':'Aucune vérification IA','pt':'Sem verificação por IA',
      });

  static String catalogCount(int count, String locale) => _pick(locale, {
        'en':'$count interests available offline','zh-Hant':'內置 $count 個興趣，可離線即時搜尋','zh-Hans':'内置 $count 个兴趣，可离线即时搜索','ja':'$count件をオフライン検索','ko':'$count개 관심사를 오프라인 검색','es':'$count intereses disponibles sin conexión','fr':'$count intérêts disponibles hors ligne','pt':'$count interesses disponíveis offline',
      });

  static String historyMeta({required int matches, required int sessions, required String locale}) {
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

  static String hiddenRemaining(int count, String locale) => _pick(locale, {
        'en': count == 1 ? '1 hidden connection left' : '$count hidden connections left',
        'zh-Hant':'仲有 $count 個隱藏連結',
        'zh-Hans':'还有 $count 个隐藏连接',
        'ja':'隠れたつながりがあと $count 個',
        'ko':'숨겨진 연결 $count개 남음',
        'es': count == 1 ? 'Queda 1 conexión oculta' : 'Quedan $count conexiones ocultas',
        'fr': count == 1 ? '1 connexion cachée restante' : '$count connexions cachées restantes',
        'pt': count == 1 ? 'Falta 1 ligação escondida' : 'Faltam $count ligações escondidas',
      });

  static String allHiddenRevealed(String locale) => _pick(locale, {
        'en':'All hidden connections revealed',
        'zh-Hant':'所有隱藏連結已揭曉',
        'zh-Hans':'所有隐藏连接已揭晓',
        'ja':'隠れたつながりをすべて発見',
        'ko':'숨겨진 연결을 모두 발견했어요',
        'es':'Todas las conexiones ocultas reveladas',
        'fr':'Toutes les connexions cachées ont été révélées',
        'pt':'Todas as ligações escondidas foram reveladas',
      });

  static String interactionLabel(String type, String locale) {
    final values = switch (type) {
      'pick' => {
          'en':'Pick together','zh-Hant':'一齊揀','zh-Hans':'一起选','ja':'一緒に選ぶ','ko':'함께 고르기',
          'es':'Elegid juntos','fr':'Choisissez ensemble','pt':'Escolham juntos',
        },
      'defend' => {
          'en':'Defend your pick','zh-Hant':'為你嘅選擇辯護','zh-Hans':'为你的选择辩护','ja':'選択を弁護','ko':'선택을 변호하기',
          'es':'Defiende tu elección','fr':'Défends ton choix','pt':'Defende a tua escolha',
        },
      'reveal' => {
          'en':'Share & react','zh-Hant':'分享再回應','zh-Hans':'分享再回应','ja':'共有して反応','ko':'공유하고 반응하기',
          'es':'Comparte y reacciona','fr':'Partage et réagis','pt':'Partilha e reage',
        },
      'guess' => {
          'en':'Guess first','zh-Hant':'先估對方','zh-Hans':'先猜对方','ja':'先に予想','ko':'먼저 맞혀보기',
          'es':'Adivina primero','fr':'Devine d’abord','pt':'Adivinha primeiro',
        },
      'surprise' => {
          'en':'Surprise round','zh-Hant':'驚喜回合','zh-Hans':'惊喜回合','ja':'サプライズラウンド','ko':'서프라이즈 라운드',
          'es':'Ronda sorpresa','fr':'Tour surprise','pt':'Ronda surpresa',
        },
      _ => {
          'en':'Quick play','zh-Hant':'快速玩法','zh-Hans':'快速玩法','ja':'クイックプレイ','ko':'빠른 플레이',
          'es':'Juego rápido','fr':'Jeu rapide','pt':'Jogo rápido',
        },
    };
    return _pick(locale, values);
  }

  static String interactionHint(String type, String locale) {
    final values = switch (type) {
      'pick' => {
          'en':'Choose at the same time, then compare.',
          'zh-Hant':'同一時間揀，之後先比較答案。',
          'zh-Hans':'同时选择，然后再比较答案。',
          'ja':'同時に選んでから答えを比べよう。',
          'ko':'동시에 고른 뒤 서로 비교해 보세요.',
          'es':'Elegid a la vez y después comparad.',
          'fr':'Choisissez en même temps, puis comparez.',
          'pt':'Escolham ao mesmo tempo e depois comparem.',
        },
      'defend' => {
          'en':'Pick a side, then defend it to each other.',
          'zh-Hant':'各自揀一邊，再向對方講點解。',
          'zh-Hans':'各自选一边，再向对方说明为什么。',
          'ja':'立場を選び、相手に理由を説明しよう。',
          'ko':'한쪽을 고른 뒤 서로 이유를 말해 보세요.',
          'es':'Elegid un lado y defendedlo ante la otra persona.',
          'fr':'Choisis un camp, puis défends-le face à l’autre.',
          'pt':'Escolhe um lado e depois defende-o perante a outra pessoa.',
        },
      'reveal' => {
          'en':'One shares first; the other reacts and follows up.',
          'zh-Hant':'一個先分享，另一個即場回應再追問。',
          'zh-Hans':'一个先分享，另一个即时回应再追问。',
          'ja':'一人が先に話し、もう一人が反応して掘り下げよう。',
          'ko':'한 사람이 먼저 말하고, 다른 사람이 반응하며 이어가세요.',
          'es':'Una persona comparte primero; la otra reacciona y continúa.',
          'fr':'Une personne partage d’abord; l’autre réagit et rebondit.',
          'pt':'Uma pessoa partilha primeiro; a outra reage e continua.',
        },
      'guess' => {
          'en':'Predict first. Do not reveal the answer until after the guess.',
          'zh-Hant':'先估，對方等你估完先揭曉答案。',
          'zh-Hans':'先猜，对方等你猜完再揭晓答案。',
          'ja':'先に予想し、答えは予想の後で明かそう。',
          'ko':'먼저 예측하세요. 추측이 끝난 뒤 정답을 공개하세요.',
          'es':'Adivina primero. No reveles la respuesta hasta después.',
          'fr':'Devine d’abord. Ne révèle la réponse qu’ensuite.',
          'pt':'Adivinha primeiro. Só depois revelem a resposta.',
        },
      'surprise' => {
          'en':'React instinctively first, then compare what surprised you.',
          'zh-Hant':'先憑直覺即時回應，再比較邊樣最出乎意料。',
          'zh-Hans':'先凭直觉即时回应，再比较什么最出乎意料。',
          'ja':'まず直感で反応し、何が意外だったか比べよう。',
          'ko':'먼저 직감적으로 반응한 뒤 무엇이 놀라웠는지 비교하세요.',
          'es':'Reaccionad por instinto y luego comparad qué os sorprendió.',
          'fr':'Réagissez d’instinct, puis comparez ce qui vous a surpris.',
          'pt':'Reajam por instinto e depois comparem o que vos surpreendeu.',
        },
      _ => {
          'en':'Do the prompt, then react to each other.',
          'zh-Hant':'跟住題目玩，之後直接回應對方。',
          'zh-Hans':'跟着题目玩，然后直接回应对方。',
          'ja':'お題をやってから、お互いの答えに反応しよう。',
          'ko':'질문대로 해본 뒤 서로의 답에 반응하세요.',
          'es':'Seguid la propuesta y reaccionad a la respuesta del otro.',
          'fr':'Suivez le prompt, puis réagissez à la réponse de l’autre.',
          'pt':'Sigam o desafio e reajam à resposta um do outro.',
        },
    };
    return _pick(locale, values);
  }

  static String quickStartTitle(String locale) => _pick(locale, {
        'en':'Pick 5 things that feel like you',
        'zh-Hant':'揀 5 樣最似你嘅興趣',
        'zh-Hans':'选 5 个最像你的兴趣',
        'ja':'自分らしい興味を5つ選ぼう',
        'ko':'나를 가장 잘 보여주는 관심사 5개를 골라보세요',
        'es':'Elige 5 cosas que te representen',
        'fr':'Choisis 5 centres d’intérêt qui te ressemblent',
        'pt':'Escolhe 5 interesses que tenham a tua cara',
      });

  static String quickStartSubtitle(String locale) => _pick(locale, {
        'en':'Five is enough to start Zync. Build the rest of your Interest DNA later.',
        'zh-Hant':'5 個就足夠開始 Zync。其餘 Interest DNA 可以之後慢慢加。',
        'zh-Hans':'5 个就足够开始 Zync。其余 Interest DNA 可以之后慢慢补。',
        'ja':'5つあればZyncを始められます。残りのInterest DNAは後から育てられます。',
        'ko':'5개면 Zync를 시작하기에 충분해요. 나머지 Interest DNA는 나중에 채워도 됩니다.',
        'es':'Con 5 basta para empezar Zync. Completa tu Interest DNA más adelante.',
        'fr':'Cinq suffisent pour commencer Zync. Tu pourras enrichir ton Interest DNA plus tard.',
        'pt':'Cinco chegam para começar no Zync. Completa o teu Interest DNA mais tarde.',
      });

  static String quickPicks(String locale) => _pick(locale, {
        'en':'Quick picks',
        'zh-Hant':'快速揀選',
        'zh-Hans':'快速选择',
        'ja':'クイック選択',
        'ko':'빠른 선택',
        'es':'Selección rápida',
        'fr':'Choix rapides',
        'pt':'Escolhas rápidas',
      });

  static String readyToZync(String locale) => _pick(locale, {
        'en':'Ready to Zync',
        'zh-Hant':'可以開始 Zync',
        'zh-Hans':'可以开始 Zync',
        'ja':'Zyncを始める',
        'ko':'Zync 시작하기',
        'es':'Listo para Zync',
        'fr':'Prêt pour Zync',
        'pt':'Pronto para Zync',
      });

  static String readyToZyncHint(String locale) => _pick(locale, {
        'en':'You can add more interests anytime.',
        'zh-Hant':'之後任何時候都可以再加興趣。',
        'zh-Hans':'之后任何时候都可以继续添加兴趣。',
        'ja':'興味はいつでも追加できます。',
        'ko':'관심사는 언제든 더 추가할 수 있어요.',
        'es':'Puedes añadir más intereses cuando quieras.',
        'fr':'Tu pourras ajouter d’autres centres d’intérêt à tout moment.',
        'pt':'Podes adicionar mais interesses quando quiseres.',
      });

  static String achievementsTitle(String locale) => _pick(locale, {
        'en':'Trophy Case','zh-Hant':'成就收藏','zh-Hans':'成就收藏','ja':'トロフィー','ko':'트로피','es':'Trofeos','fr':'Trophées','pt':'Troféus',
      });

  static String achievementsIntro(String locale) => _pick(locale, {
        'en':'A map of the people and interests you have discovered in real life.',
        'zh-Hant':'你喺現實世界遇過嘅人，同一路發現過嘅興趣地圖。',
        'zh-Hans':'你在现实世界遇过的人，以及一路发现过的兴趣地图。',
        'ja':'現実で出会った人と興味の発見を集める記録です。',
        'ko':'현실에서 만난 사람과 발견한 관심사를 모아보세요.',
        'es':'Tu mapa de personas e intereses descubiertos en la vida real.',
        'fr':'La carte des personnes et centres d’intérêt découverts dans la vraie vie.',
        'pt':'Seu mapa de pessoas e interesses descobertos na vida real.',
      });

  static String achievementUnlockedMeta(int unlocked, int total, String locale) => _pick(locale, {
        'en':'$unlocked of $total unlocked','zh-Hant':'已解鎖 $unlocked / $total','zh-Hans':'已解锁 $unlocked / $total',
        'ja':'$total 個中 $unlocked 個を解除','ko':'$total개 중 $unlocked개 달성',
        'es':'$unlocked de $total desbloqueados','fr':'$unlocked sur $total débloqués','pt':'$unlocked de $total desbloqueados',
      });

  static String newAchievement(String locale) => _pick(locale, {
        'en':'New trophy unlocked','zh-Hant':'解鎖新成就','zh-Hans':'解锁新成就','ja':'新しいトロフィー','ko':'새 트로피 달성',
        'es':'Nuevo trofeo desbloqueado','fr':'Nouveau trophée débloqué','pt':'Novo troféu desbloqueado',
      });

  static String sportsDiscovered(String locale) => _pick(locale, {
        'en':'Sports discovered','zh-Hant':'已發現運動','zh-Hans':'已发现运动','ja':'発見したスポーツ','ko':'발견한 스포츠',
        'es':'Deportes descubiertos','fr':'Sports découverts','pt':'Esportes descobertos',
      });

  static String secretAchievementTitle(String locale) => _pick(locale, {
        'en':'Secret trophy',
        'zh-Hant':'隱藏成就',
        'zh-Hans':'隐藏成就',
        'ja':'シークレットトロフィー',
        'ko':'숨겨진 트로피',
        'es':'Trofeo secreto',
        'fr':'Trophée secret',
        'pt':'Troféu secreto',
      });

  static String secretAchievementHint(
    String family,
    String locale,
  ) {
    final values = switch (family) {
      'connection' => {
          'en':'Something about how your connections deepen.',
          'zh-Hant':'同「關係點樣變熟」有關。繼續真人 Zync。',
          'zh-Hans':'和“关系如何变熟”有关。继续真人 Zync。',
        },
      'discovery' => {
          'en':'A particular mix of interests is hiding here.',
          'zh-Hant':'某種特別嘅興趣組合藏喺呢度。',
          'zh-Hans':'某种特别的兴趣组合藏在这里。',
        },
      'crew' => {
          'en':'Meet the right mix of people and this crew will reveal itself.',
          'zh-Hant':'遇到啱嘅一班同好，呢個成就自然會現身。',
          'zh-Hans':'遇到合适的一群同好，这个成就自然会出现。',
        },
      'realWorld' => {
          'en':'Do more things together in the real world.',
          'zh-Hant':'真係同人一齊做多啲嘢，條件會自己揭曉。',
          'zh-Hans':'真的和人一起多做些事，条件会自己揭晓。',
        },
      _ => {
          'en':'Keep exploring Zync in real life.',
          'zh-Hant':'繼續喺真實世界探索 Zync。',
          'zh-Hans':'继续在现实世界探索 Zync。',
        },
    };
    return _pick(locale, values);
  }

  static String achievementProgress(int current, int target, String locale) => _pick(locale, {
        'en':'$current / $target','zh-Hant':'$current / $target','zh-Hans':'$current / $target','ja':'$current / $target','ko':'$current / $target',
        'es':'$current / $target','fr':'$current / $target','pt':'$current / $target',
      });

  static String achievementFamilyTitle(String family, String locale) {
    final values = switch (family) {
      'connection' => {
          'en':'People & Connections',
          'zh-Hant':'人與連結',
          'zh-Hans':'人与连接',
        },
      'discovery' => {
          'en':'Interest Discovery',
          'zh-Hant':'興趣探索',
          'zh-Hans':'兴趣探索',
        },
      'crew' => {
          'en':'Your Crews',
          'zh-Hant':'你遇見嘅同好',
          'zh-Hans':'你遇见的同好',
        },
      'realWorld' => {
          'en':'Do It for Real',
          'zh-Hant':'真係一齊做',
          'zh-Hans':'真的一起做',
        },
      _ => {'en': family},
    };
    return _pick(locale, values);
  }

  static String achievementTitle(String id, String locale) {
    final values = switch (id) {
      'first_zync' => {
          'en':'First Contact','zh-Hant':'第一次相遇','zh-Hans':'第一次相遇',
        },
      'people_five' => {
          'en':'High Five','zh-Hant':'High Five','zh-Hans':'High Five',
        },
      'people_ten' => {
          'en':'Open Circle','zh-Hant':'十人圈','zh-Hans':'十人圈',
        },
      'people_twentyfive' => {
          'en':'Constellation','zh-Hant':'人際星圖','zh-Hans':'人际星图',
        },
      'zync_sessions_ten' => {
          'en':'Ten Conversations','zh-Hant':'十次連結','zh-Hans':'十次连接',
        },
      'zync_sessions_twentyfive' => {
          'en':'Keep Connecting','zh-Hant':'一路有話題','zh-Hans':'一路有话题',
        },
      'familiar_face_three' => {
          'en':'Not Just Hello','zh-Hant':'不止打招呼','zh-Hans':'不止打招呼',
        },
      'familiar_circle_three' => {
          'en':'Familiar Faces','zh-Hant':'熟面孔','zh-Hans':'熟面孔',
        },
      'deep_circle_three' => {
          'en':'Inner Orbit','zh-Hant':'熟人軌道','zh-Hans':'熟人轨道',
        },
      'conversation_modes_three' => {
          'en':'Conversation Sampler','zh-Hant':'三種打開方式','zh-Hans':'三种打开方式',
        },
      'conversation_modes_six' => {
          'en':'Full Spectrum','zh-Hant':'全頻對話','zh-Hans':'全频对话',
        },
      'curiosity_10' => {
          'en':'Curiosity Shelf','zh-Hant':'好奇小架','zh-Hans':'好奇小架',
        },
      'curiosity_25' => {
          'en':'Curiosity Cabinet','zh-Hant':'好奇收藏櫃','zh-Hans':'好奇收藏柜',
        },
      'curiosity_50' => {
          'en':'Curiosity Library','zh-Hant':'好奇圖書館','zh-Hans':'好奇图书馆',
        },
      'curiosity_100' => {
          'en':'Human Encyclopedia','zh-Hant':'人類百科','zh-Hans':'人类百科',
        },
      'categories_three' => {
          'en':'Three Worlds','zh-Hant':'三個世界','zh-Hans':'三个世界',
        },
      'categories_five' => {
          'en':'Five Worlds','zh-Hant':'五個世界','zh-Hans':'五个世界',
        },
      'categories_eight' => {
          'en':'World Hopper','zh-Hant':'世界跳躍者','zh-Hans':'世界跳跃者',
        },
      'categories_twelve' => {
          'en':'Wide Horizon','zh-Hant':'廣闊視野','zh-Hans':'广阔视野',
        },
      'basketball_starting_five' => {
          'en':'Starting Five','zh-Hant':'正選五人','zh-Hans':'首发五人',
        },
      'basketball_full_roster' => {
          'en':'Full Roster','zh-Hant':'完整球隊名單','zh-Hans':'完整球队名单',
        },
      'football_starting_eleven' => {
          'en':'Starting XI','zh-Hant':'正選十一人','zh-Hans':'首发十一人',
        },
      'badminton_doubles_four' => {
          'en':'Doubles Court','zh-Hant':'雙打成局','zh-Hans':'双打成局',
        },
      'coffee_table_five' => {
          'en':'Coffee Table','zh-Hant':'咖啡五人桌','zh-Hans':'咖啡五人桌',
        },
      'gaming_party_four' => {
          'en':'Full Party','zh-Hant':'四人滿隊','zh-Hans':'四人满队',
        },
      'book_club_five' => {
          'en':'Book Club','zh-Hant':'讀書會','zh-Hans':'读书会',
        },
      'ai_roundtable_three' => {
          'en':'AI Roundtable','zh-Hant':'AI 圓桌','zh-Hans':'AI 圆桌',
        },
      'photo_walk_three' => {
          'en':'Photo Walk','zh-Hant':'攝影散步隊','zh-Hans':'摄影散步队',
        },
      'japan_crew_three' => {
          'en':'Japan Crew','zh-Hant':'日本同好三人組','zh-Hans':'日本同好三人组',
        },
      'music_crew_five' => {
          'en':'Festival Crew','zh-Hant':'音樂祭五人組','zh-Hans':'音乐节五人组',
        },
      'sports_five' => {
          'en':'Multi-Sport Rookie','zh-Hant':'多項運動新秀','zh-Hans':'多项运动新秀',
        },
      'sports_ten' => {
          'en':'Ten-Sport Explorer','zh-Hant':'十項運動探索者','zh-Hans':'十项运动探索者',
        },
      'racket_four' => {
          'en':'Racket Rack','zh-Hant':'球拍架','zh-Hans':'球拍架',
        },
      'active_mix' => {
          'en':'Active Weekend','zh-Hant':'動感週末','zh-Hans':'动感周末',
        },
      'culture_mix' => {
          'en':'Culture Mixer','zh-Hant':'文化混合器','zh-Hans':'文化混合器',
        },
      'maker_mix' => {
          'en':'Maker Mindset','zh-Hant':'創作腦','zh-Hans':'创作脑',
        },
      'taste_trip' => {
          'en':'Taste Trip','zh-Hant':'味覺旅行','zh-Hans':'味觉旅行',
        },
      'mind_body_mix' => {
          'en':'Mind & Body','zh-Hant':'身心雙修','zh-Hans':'身心双修',
        },
      'tried_together_first' => {
          'en':'From Talk to Action','zh-Hant':'由傾到做','zh-Hans':'从聊到做',
        },
      'tried_together_three' => {
          'en':'Three for Real','zh-Hant':'真做三次','zh-Hans':'真做三次',
        },
      'tried_together_ten' => {
          'en':'Actually Doing It','zh-Hant':'真係有做','zh-Hans':'真的有做',
        },
      'group_activity_first' => {
          'en':'Better Together','zh-Hant':'一齊先好玩','zh-Hans':'一起才好玩',
        },
      'group_activity_three' => {
          'en':'Group Momentum','zh-Hant':'群體動起來','zh-Hans':'群体动起来',
        },
      'activity_categories_three' => {
          'en':'Try Three Worlds','zh-Hant':'玩過三個世界','zh-Hans':'玩过三个世界',
        },
      'activity_categories_five' => {
          'en':'Five Ways Out','zh-Hant':'五種新玩法','zh-Hans':'五种新玩法',
        },
      'activity_modes_three' => {
          'en':'Mix It Up','zh-Hant':'三種玩法','zh-Hans':'三种玩法',
        },
      'real_world_actions_ten' => {
          'en':'Real-World Ten','zh-Hant':'現實十連','zh-Hans':'现实十连',
        },
      'real_world_actions_twentyfive' => {
          'en':'Life, Not Feed','zh-Hant':'生活唔係 Feed','zh-Hans':'生活不是 Feed',
        },
      _ => {'en': id},
    };
    return _pick(locale, values);
  }

  static String achievementDescription(String id, String locale) {
    final values = switch (id) {
      'first_zync' => {
          'en':'Complete your first face-to-face Zync.','zh-Hant':'完成你第一次真人 Zync。','zh-Hans':'完成你第一次真人 Zync。',
        },
      'people_five' => {
          'en':'Meet 5 different people through Zync.','zh-Hant':'透過 Zync 遇到 5 個唔同嘅人。','zh-Hans':'通过 Zync 遇到 5 个不同的人。',
        },
      'people_ten' => {
          'en':'Meet 10 different people through Zync.','zh-Hant':'透過 Zync 遇到 10 個唔同嘅人。','zh-Hans':'通过 Zync 遇到 10 个不同的人。',
        },
      'people_twentyfive' => {
          'en':'Build a constellation of 25 real-world connections.','zh-Hant':'累積 25 個真實世界入面嘅 Zync 連結。','zh-Hans':'累积 25 个现实世界里的 Zync 连接。',
        },
      'zync_sessions_ten' => {
          'en':'Complete 10 face-to-face Zync sessions, repeats included.','zh-Hant':'完成 10 次真人 Zync；同一個人再 Zync 都算。','zh-Hans':'完成 10 次真人 Zync；和同一个人再次 Zync 也算。',
        },
      'zync_sessions_twentyfive' => {
          'en':'Complete 25 face-to-face Zync sessions.','zh-Hant':'完成 25 次真人 Zync。','zh-Hans':'完成 25 次真人 Zync。',
        },
      'familiar_face_three' => {
          'en':'Zync with the same person 3 times.','zh-Hant':'同同一個人完成 3 次 Zync。','zh-Hans':'和同一个人完成 3 次 Zync。',
        },
      'familiar_circle_three' => {
          'en':'Zync again with 3 different people.','zh-Hant':'同 3 個唔同嘅人各自再 Zync 至少一次。','zh-Hans':'和 3 个不同的人各自再次 Zync 至少一次。',
        },
      'deep_circle_three' => {
          'en':'Have 3 people you have Zynced with at least 3 times each.','zh-Hant':'有 3 個人，你同佢哋每個都 Zync 過至少 3 次。','zh-Hans':'有 3 个人，你和他们每个人都 Zync 过至少 3 次。',
        },
      'conversation_modes_three' => {
          'en':'Use 3 different conversation styles across real Zyncs.','zh-Hant':'喺真人 Zync 入面玩過 3 種唔同對話方式。','zh-Hans':'在真人 Zync 里玩过 3 种不同对话方式。',
        },
      'conversation_modes_six' => {
          'en':'Use all 6 conversation styles across real Zyncs.','zh-Hant':'喺真人 Zync 入面玩齊 6 種對話方式。','zh-Hans':'在真人 Zync 里玩齐 6 种对话方式。',
        },
      'curiosity_10' => {
          'en':'Discover 10 different interests through people you meet.','zh-Hant':'從真人相遇中發現 10 個唔同興趣。','zh-Hans':'从真人相遇中发现 10 个不同兴趣。',
        },
      'curiosity_25' => {
          'en':'Discover 25 different interests through people you meet.','zh-Hant':'從真人相遇中發現 25 個唔同興趣。','zh-Hans':'从真人相遇中发现 25 个不同兴趣。',
        },
      'curiosity_50' => {
          'en':'Discover 50 different interests through people you meet.','zh-Hant':'從真人相遇中發現 50 個唔同興趣。','zh-Hans':'从真人相遇中发现 50 个不同兴趣。',
        },
      'curiosity_100' => {
          'en':'Discover 100 different interests through real people.','zh-Hant':'從真人相遇中發現 100 個唔同興趣。','zh-Hans':'从真人相遇中发现 100 个不同兴趣。',
        },
      'categories_three' => {
          'en':'Discover interests across 3 different worlds.','zh-Hant':'從真人相遇中接觸 3 個唔同興趣類別。','zh-Hans':'从真人相遇中接触 3 个不同兴趣类别。',
        },
      'categories_five' => {
          'en':'Discover interests across 5 different worlds.','zh-Hant':'從真人相遇中接觸 5 個唔同興趣類別。','zh-Hans':'从真人相遇中接触 5 个不同兴趣类别。',
        },
      'categories_eight' => {
          'en':'Discover interests across 8 different worlds.','zh-Hant':'從真人相遇中接觸 8 個唔同興趣類別。','zh-Hans':'从真人相遇中接触 8 个不同兴趣类别。',
        },
      'categories_twelve' => {
          'en':'Discover interests across 12 different worlds.','zh-Hant':'從真人相遇中接觸 12 個唔同興趣類別。','zh-Hans':'从真人相遇中接触 12 个不同兴趣类别。',
        },
      'basketball_starting_five' => {
          'en':'Meet 5 different people who are into basketball.','zh-Hant':'遇到 5 個都鍾意籃球嘅唔同人物。','zh-Hans':'遇到 5 个都喜欢篮球的不同的人。',
        },
      'basketball_full_roster' => {
          'en':'Meet 12 different basketball people — a full roster.','zh-Hant':'遇到 12 個唔同嘅籃球同好，湊成完整名單。','zh-Hans':'遇到 12 个不同的篮球同好，凑成完整名单。',
        },
      'football_starting_eleven' => {
          'en':'Meet 11 different people who are into football.','zh-Hant':'遇到 11 個唔同嘅足球同好，砌出正選十一人。','zh-Hans':'遇到 11 个不同的足球同好，组成首发十一人。',
        },
      'badminton_doubles_four' => {
          'en':'Meet 4 different badminton people — enough for doubles.','zh-Hant':'遇到 4 個唔同嘅羽毛球同好，啱啱好可以雙打。','zh-Hans':'遇到 4 个不同的羽毛球同好，刚好可以双打。',
        },
      'coffee_table_five' => {
          'en':'Meet 5 different people who are into coffee.','zh-Hant':'遇到 5 個唔同嘅咖啡同好。','zh-Hans':'遇到 5 个不同的咖啡同好。',
        },
      'gaming_party_four' => {
          'en':'Meet 4 different people who are into video games.','zh-Hant':'遇到 4 個唔同嘅電玩同好，四人滿隊。','zh-Hans':'遇到 4 个不同的电玩同好，四人满队。',
        },
      'book_club_five' => {
          'en':'Meet 5 different people who are into reading.','zh-Hant':'遇到 5 個唔同嘅閱讀同好。','zh-Hans':'遇到 5 个不同的阅读同好。',
        },
      'ai_roundtable_three' => {
          'en':'Meet 3 different people who are into AI.','zh-Hant':'遇到 3 個唔同嘅 AI 同好。','zh-Hans':'遇到 3 个不同的 AI 同好。',
        },
      'photo_walk_three' => {
          'en':'Meet 3 different people who are into photography.','zh-Hant':'遇到 3 個唔同嘅攝影同好。','zh-Hans':'遇到 3 个不同的摄影同好。',
        },
      'japan_crew_three' => {
          'en':'Meet 3 different people who share an interest in Japan.','zh-Hant':'遇到 3 個同樣對日本有興趣嘅唔同人物。','zh-Hans':'遇到 3 个同样对日本有兴趣的不同的人。',
        },
      'music_crew_five' => {
          'en':'Meet 5 different people with music somewhere in their Interest DNA.','zh-Hant':'遇到 5 個 Interest DNA 入面有音樂世界嘅唔同人物。','zh-Hans':'遇到 5 个 Interest DNA 里有音乐世界的不同的人。',
        },
      'sports_five' => {
          'en':'Discover 5 different sports through people you meet.','zh-Hant':'從你遇到嘅人身上發現 5 種唔同運動。','zh-Hans':'从你遇到的人身上发现 5 种不同运动。',
        },
      'sports_ten' => {
          'en':'Discover 10 different sports through people you meet.','zh-Hant':'從你遇到嘅人身上發現 10 種唔同運動。','zh-Hans':'从你遇到的人身上发现 10 种不同运动。',
        },
      'racket_four' => {
          'en':'Discover 4 different racket sports.','zh-Hant':'從真人相遇中發現 4 種唔同球拍運動。','zh-Hans':'从真人相遇中发现 4 种不同球拍运动。',
        },
      'active_mix' => {
          'en':'Discover at least 3 sports and 2 outdoor interests.','zh-Hant':'發現至少 3 種運動加 2 種戶外興趣。','zh-Hans':'发现至少 3 种运动加 2 种户外兴趣。',
        },
      'culture_mix' => {
          'en':'Discover 2 music, 2 entertainment and 1 arts interest.','zh-Hant':'發現 2 個音樂、2 個娛樂同 1 個藝術興趣。','zh-Hans':'发现 2 个音乐、2 个娱乐和 1 个艺术兴趣。',
        },
      'maker_mix' => {
          'en':'Discover 2 technology, 1 arts and 1 crafts interest.','zh-Hant':'發現 2 個科技、1 個藝術同 1 個手作興趣。','zh-Hans':'发现 2 个科技、1 个艺术和 1 个手作兴趣。',
        },
      'taste_trip' => {
          'en':'Discover 3 food interests and 2 travel interests.','zh-Hant':'發現 3 個飲食興趣加 2 個旅行興趣。','zh-Hans':'发现 3 个饮食兴趣加 2 个旅行兴趣。',
        },
      'mind_body_mix' => {
          'en':'Discover 2 wellness interests and 2 sports.','zh-Hant':'發現 2 個身心健康興趣加 2 種運動。','zh-Hans':'发现 2 个身心健康兴趣加 2 种运动。',
        },
      'tried_together_first' => {
          'en':'Actually complete your first Zync Now activity together.','zh-Hant':'第一次真係完成一個 Zync Now 揀出嚟嘅活動。','zh-Hans':'第一次真正完成一个 Zync Now 选出来的活动。',
        },
      'tried_together_three' => {
          'en':'Complete 3 Zync Now activities in real life.','zh-Hant':'真實完成 3 個 Zync Now 活動。','zh-Hans':'真实完成 3 个 Zync Now 活动。',
        },
      'tried_together_ten' => {
          'en':'Complete 10 Zync Now activities in real life.','zh-Hant':'真實完成 10 個 Zync Now 活動。','zh-Hans':'真实完成 10 个 Zync Now 活动。',
        },
      'group_activity_first' => {
          'en':'Complete a Zync Now activity with 3 or more people.','zh-Hant':'同 3 個或以上嘅人真實完成一次 Zync Now 活動。','zh-Hans':'和 3 个或以上的人真实完成一次 Zync Now 活动。',
        },
      'group_activity_three' => {
          'en':'Complete 3 group Zync Now activities with 3+ people.','zh-Hant':'完成 3 次三人或以上嘅 Zync Now 群體活動。','zh-Hans':'完成 3 次三人或以上的 Zync Now 群体活动。',
        },
      'activity_categories_three' => {
          'en':'Complete activities spanning 3 different interest worlds.','zh-Hant':'真實做過橫跨 3 個唔同興趣類別嘅活動。','zh-Hans':'真实做过横跨 3 个不同兴趣类别的活动。',
        },
      'activity_categories_five' => {
          'en':'Complete activities spanning 5 different interest worlds.','zh-Hant':'真實做過橫跨 5 個唔同興趣類別嘅活動。','zh-Hans':'真实做过横跨 5 个不同兴趣类别的活动。',
        },
      'activity_modes_three' => {
          'en':'Complete Zync Now activities in 3 different activity modes.','zh-Hant':'真實完成過 3 種唔同模式嘅 Zync Now 活動。','zh-Hans':'真实完成过 3 种不同模式的 Zync Now 活动。',
        },
      'real_world_actions_ten' => {
          'en':'Complete 10 real-world Zync actions.','zh-Hant':'累積 10 次真人 Zync 或 Tried Together 行動。','zh-Hans':'累积 10 次真人 Zync 或 Tried Together 行动。',
        },
      'real_world_actions_twentyfive' => {
          'en':'Complete 25 real-world Zync actions.','zh-Hant':'累積 25 次真人 Zync 或 Tried Together 行動。','zh-Hans':'累积 25 次真人 Zync 或 Tried Together 行动。',
        },
      _ => {'en': id},
    };
    return _pick(locale, values);
  }

  static String groupZyncTitle(String locale) => _pick(locale, {
        'en':'Group Zync','zh-Hant':'Group Zync','zh-Hans':'Group Zync',
        'ja':'Group Zync','ko':'Group Zync','es':'Group Zync','fr':'Group Zync','pt':'Group Zync',
      });

  static String groupZyncSubtitle(String locale) => _pick(locale, {
        'en':'Discover what connects the room — then decide what to do together.',
        'zh-Hant':'一班人一齊發現彼此嘅連結，再決定一齊做咩。',
        'zh-Hans':'一群人一起发现彼此的连接，再决定一起做什么。',
        'ja':'みんなのつながりを見つけて、一緒に何をするか決めよう。',
        'ko':'함께 연결점을 발견하고 무엇을 할지 정해 보세요.',
        'es':'Descubrid qué conecta al grupo y decidid qué hacer juntos.',
        'fr':'Découvrez ce qui relie le groupe, puis choisissez quoi faire ensemble.',
        'pt':'Descubram o que liga o grupo e decidam o que fazer juntos.',
      });

  static String startGroupZync(String locale) => _pick(locale, {
        'en':'Start a Group Zync','zh-Hant':'開始 Group Zync','zh-Hans':'开始 Group Zync',
        'ja':'Group Zyncを開始','ko':'Group Zync 시작','es':'Iniciar Group Zync',
        'fr':'Démarrer un Group Zync','pt':'Iniciar Group Zync',
      });

  static String groupHostHint(String locale) => _pick(locale, {
        'en':'Show this QR. Everyone joins privately with only the interests needed for this room.',
        'zh-Hant':'俾大家掃呢個 QR。每個人只會為今次房間分享所需嘅興趣資料。',
        'zh-Hans':'让大家扫描这个 QR。每个人只会为这次房间分享所需的兴趣资料。',
        'ja':'このQRを見せてください。この部屋に必要な興味だけが共有されます。',
        'ko':'이 QR을 보여주세요. 이 방에 필요한 관심사만 공유됩니다.',
        'es':'Muestra este QR. Solo se comparten los intereses necesarios para esta sala.',
        'fr':'Montrez ce QR. Seuls les intérêts nécessaires à cette session sont partagés.',
        'pt':'Mostre este QR. Só os interesses necessários para esta sala são partilhados.',
      });

  static String groupReadyCount(int count, int max, String locale) => _pick(locale, {
        'en':'$count of $max people in the room',
        'zh-Hant':'房間已有 $count / $max 人',
        'zh-Hans':'房间已有 $count / $max 人',
        'ja':'$count / $max 人が参加中',
        'ko':'$count / $max명 참여 중',
        'es':'$count de $max personas en la sala',
        'fr':'$count personnes sur $max dans la salle',
        'pt':'$count de $max pessoas na sala',
      });

  static String groupNeedThree(String locale) => _pick(locale, {
        'en':'Group Zync starts with 3 people.',
        'zh-Hant':'Group Zync 3 個人就可以開始。',
        'zh-Hans':'Group Zync 3 个人就可以开始。',
        'ja':'Group Zyncは3人から開始できます。',
        'ko':'Group Zync는 3명부터 시작할 수 있어요.',
        'es':'Group Zync empieza con 3 personas.',
        'fr':'Group Zync commence à 3 personnes.',
        'pt':'Group Zync começa com 3 pessoas.',
      });

  static String everyoneReady(String locale) => _pick(locale, {
        'en':'Everyone is ready','zh-Hant':'大家都準備好','zh-Hans':'大家都准备好了',
        'ja':'全員準備完了','ko':'모두 준비됐어요','es':'Todo el mundo está listo',
        'fr':'Tout le monde est prêt','pt':'Todos estão prontos',
      });

  static String startFirstRound(String locale) => _pick(locale, {
        'en':'Start the first round','zh-Hant':'開始第一回合','zh-Hans':'开始第一回合',
        'ja':'最初のラウンドを開始','ko':'첫 라운드 시작','es':'Empezar la primera ronda',
        'fr':'Commencer le premier tour','pt':'Começar a primeira ronda',
      });

  static String waitingForHost(String locale) => _pick(locale, {
        'en':'You’re in. Waiting for the host…','zh-Hant':'你已加入，等 host 開始…','zh-Hans':'你已加入，等待主持人开始…',
        'ja':'参加しました。ホストを待っています…','ko':'참여했어요. 호스트를 기다리는 중…',
        'es':'Ya estás dentro. Esperando al anfitrión…','fr':'Vous êtes dedans. En attente de l’hôte…',
        'pt':'Já entrou. A aguardar o anfitrião…',
      });

  static String privateAnswerHint(String locale) => _pick(locale, {
        'en':'Your answer stays private until the reveal.',
        'zh-Hant':'你嘅答案會保持私下，揭曉嗰刻先顯示。',
        'zh-Hans':'你的答案会保持私密，揭晓时才显示。',
        'ja':'回答は公開の瞬間まで非公開です。','ko':'답변은 공개할 때까지 비공개예요.',
        'es':'Tu respuesta seguirá privada hasta la revelación.',
        'fr':'Votre réponse reste privée jusqu’à la révélation.',
        'pt':'A sua resposta fica privada até à revelação.',
      });

  static String answerSubmitted(String locale) => _pick(locale, {
        'en':'Answer locked. Waiting for everyone else…',
        'zh-Hant':'答案已鎖定，等埋其他人…','zh-Hans':'答案已锁定，等待其他人…',
        'ja':'回答を確定しました。ほかの人を待っています…','ko':'답변을 확정했어요. 다른 사람을 기다리는 중…',
        'es':'Respuesta guardada. Esperando al resto…','fr':'Réponse verrouillée. En attente des autres…',
        'pt':'Resposta confirmada. A aguardar os restantes…',
      });

  static String groupConnectionIssue(String locale) => _pick(locale, {
        'en':'Group Zync lost the connection. Try again while the room is still open.',
        'zh-Hant':'Group Zync 連線中斷。房間未過期前可以再試。',
        'zh-Hans':'Group Zync 连接中断。房间未过期前可以重试。',
        'ja':'接続が切れました。部屋が有効なうちに再試行してください。',
        'ko':'연결이 끊겼어요. 방이 열려 있는 동안 다시 시도해 주세요.',
        'es':'Se perdió la conexión. Vuelve a intentarlo mientras la sala siga abierta.',
        'fr':'Connexion perdue. Réessayez tant que la salle est ouverte.',
        'pt':'A ligação caiu. Tente novamente enquanto a sala estiver aberta.',
      });

  static String zyncNowTitle(String locale) => _pick(locale, {
        'en':'Zync Now','zh-Hant':'Zync Now','zh-Hans':'Zync Now','ja':'Zync Now','ko':'Zync Now',
        'es':'Zync Now','fr':'Zync Now','pt':'Zync Now',
      });

  static String zyncNowGroupCta(String locale) => _pick(locale, {
        'en':'What should we do together?','zh-Hant':'我哋一齊做咩好？','zh-Hans':'我们一起做什么好？',
        'ja':'一緒に何をする？','ko':'우리 같이 뭐 할까?','es':'¿Qué hacemos juntos?',
        'fr':'Qu’est-ce qu’on fait ensemble ?','pt':'O que fazemos juntos?',
      });

  static String anotherGroupRound(String locale) => _pick(locale, {
        'en':'Discover another connection','zh-Hant':'再發現一個連結','zh-Hans':'再发现一个连接',
        'ja':'もう一つ発見する','ko':'연결 하나 더 발견하기','es':'Descubrir otra conexión',
        'fr':'Découvrir une autre connexion','pt':'Descobrir outra ligação',
      });

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
