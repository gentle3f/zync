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

  static String achievementProgress(int current, int target, String locale) => _pick(locale, {
        'en':'$current / $target','zh-Hant':'$current / $target','zh-Hans':'$current / $target','ja':'$current / $target','ko':'$current / $target',
        'es':'$current / $target','fr':'$current / $target','pt':'$current / $target',
      });

  static String achievementTitle(String id, String locale) {
    final values = switch (id) {
      'first_zync' => {
          'en':'First Contact','zh-Hant':'第一次相遇','zh-Hans':'第一次相遇','ja':'最初の出会い','ko':'첫 만남',
          'es':'Primer contacto','fr':'Premier contact','pt':'Primeiro contato',
        },
      'people_five' => {
          'en':'High Five','zh-Hant':'High Five','zh-Hans':'High Five','ja':'ハイファイブ','ko':'하이파이브',
          'es':'Choca esos cinco','fr':'High Five','pt':'High Five',
        },
      'basketball_starting_five' => {
          'en':'Starting Five','zh-Hant':'正選五人','zh-Hans':'首发五人','ja':'スターティング5','ko':'스타팅 파이브',
          'es':'Quinteto titular','fr':'Cinq majeur','pt':'Cinco inicial',
        },
      'sports_five' => {
          'en':'Multi-Sport Rookie','zh-Hant':'多項運動新秀','zh-Hans':'多项运动新秀','ja':'マルチスポーツ新人','ko':'멀티스포츠 루키',
          'es':'Novato multideporte','fr':'Rookie multisport','pt':'Novato multiesporte',
        },
      'sports_ten' => {
          'en':'Ten-Sport Explorer','zh-Hant':'十項運動探索者','zh-Hans':'十项运动探索者','ja':'10スポーツ探検家','ko':'10종목 탐험가',
          'es':'Explorador de 10 deportes','fr':'Explorateur de 10 sports','pt':'Explorador de 10 esportes',
        },
      'curiosity_25' => {
          'en':'Curiosity Cabinet','zh-Hant':'好奇收藏櫃','zh-Hans':'好奇收藏柜','ja':'好奇心コレクション','ko':'호기심 컬렉션',
          'es':'Gabinete de curiosidades','fr':'Cabinet de curiosités','pt':'Gabinete de curiosidades',
        },
      _ => {'en': id},
    };
    return _pick(locale, values);
  }

  static String achievementDescription(String id, String locale) {
    final values = switch (id) {
      'first_zync' => {
          'en':'Zync with your first person.','zh-Hant':'完成你第一次真人 Zync。','zh-Hans':'完成你第一次真人 Zync。',
          'ja':'最初の相手とZyncする。','ko':'첫 사람과 Zync 하세요.','es':'Haz Zync con tu primera persona.',
          'fr':'Faites votre premier Zync.','pt':'Faça seu primeiro Zync.',
        },
      'people_five' => {
          'en':'Meet 5 different people through Zync.','zh-Hant':'透過 Zync 遇到 5 個唔同嘅人。','zh-Hans':'通过 Zync 遇到 5 个不同的人。',
          'ja':'5人の異なる人とZyncする。','ko':'서로 다른 5명과 Zync 하세요.','es':'Conoce a 5 personas distintas con Zync.',
          'fr':'Rencontrez 5 personnes différentes avec Zync.','pt':'Conheça 5 pessoas diferentes com Zync.',
        },
      'basketball_starting_five' => {
          'en':'Meet 5 different people who are into basketball.','zh-Hant':'遇到 5 個都鍾意籃球嘅唔同人物。','zh-Hans':'遇到 5 个都喜欢篮球的不同的人。',
          'ja':'バスケットボール好きの5人と出会う。','ko':'농구를 좋아하는 서로 다른 5명을 만나세요.',
          'es':'Conoce a 5 personas distintas a las que les gusta el baloncesto.',
          'fr':'Rencontrez 5 personnes différentes qui aiment le basket.',
          'pt':'Conheça 5 pessoas diferentes que gostam de basquete.',
        },
      'sports_five' => {
          'en':'Discover 5 different sports through people you meet.','zh-Hant':'從你遇到嘅人身上發現 5 種唔同運動。','zh-Hans':'从你遇到的人身上发现 5 种不同运动。',
          'ja':'出会った人から5種類のスポーツを発見する。','ko':'만난 사람들을 통해 5가지 스포츠를 발견하세요.',
          'es':'Descubre 5 deportes distintos a través de la gente que conoces.',
          'fr':'Découvrez 5 sports différents grâce aux personnes rencontrées.',
          'pt':'Descubra 5 esportes diferentes através das pessoas que conhece.',
        },
      'sports_ten' => {
          'en':'Discover 10 different sports through people you meet.','zh-Hant':'從你遇到嘅人身上發現 10 種唔同運動。','zh-Hans':'从你遇到的人身上发现 10 种不同运动。',
          'ja':'出会った人から10種類のスポーツを発見する。','ko':'만난 사람들을 통해 10가지 스포츠를 발견하세요.',
          'es':'Descubre 10 deportes distintos a través de la gente que conoces.',
          'fr':'Découvrez 10 sports différents grâce aux personnes rencontrées.',
          'pt':'Descubra 10 esportes diferentes através das pessoas que conhece.',
        },
      'curiosity_25' => {
          'en':'Discover 25 different interests through people you meet.','zh-Hant':'從真人相遇中發現 25 個唔同興趣。','zh-Hans':'从真人相遇中发现 25 个不同兴趣。',
          'ja':'出会いを通して25種類の興味を発見する。','ko':'사람들을 만나며 25가지 관심사를 발견하세요.',
          'es':'Descubre 25 intereses distintos a través de la gente que conoces.',
          'fr':'Découvrez 25 centres d’intérêt différents grâce aux rencontres.',
          'pt':'Descubra 25 interesses diferentes através das pessoas que conhece.',
        },
      _ => {'en': id},
    };
    return _pick(locale, values);
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
