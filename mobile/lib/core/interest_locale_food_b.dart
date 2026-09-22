/// Food localization batch B: dishes, drinks and food activities.
/// Format: id|es|fr|pt|ja|ko
const String kInterestLocaleFoodBRaw = r'''food.dish.bagels|Bagels|Bagels|Bagels|ベーグル|베이글
food.dish.baguette|Baguette|Baguette|Baguete|バゲット|바게트
food.dish.bak_kut_teh|Bak kut teh|Bak kut teh|Bak kut teh|肉骨茶|바쿠테
food.dish.banh_mi|Bánh mì|Bánh mì|Bánh mì|バインミー|반미
food.dish.basque_cheesecake|Tarta de queso vasca|Cheesecake basque|Cheesecake basco|バスクチーズケーキ|바스크 치즈케이크
food.dish.beef_bourguignon|Boeuf bourguignon|Bœuf bourguignon|Boeuf bourguignon|牛肉のブルゴーニュ風煮込み|뵈프 부르기뇽
food.dish.beef_brisket_noodles|Fideos con falda de ternera|Nouilles au bœuf braisé|Noodles de peito bovino|牛バラ肉麺|우육면
food.dish.bibimbap|Bibimbap|Bibimbap|Bibimbap|ビビンバ|비빔밥
food.dish.biryani|Biryani|Biryani|Biryani|ビリヤニ|비리야니
food.dish.bolognese|Boloñesa|Bolognaise|Bolonhesa|ボロネーゼ|볼로네제
food.dish.brownies|Brownies|Brownies|Brownies|ブラウニー|브라우니
food.dish.bulgogi|Bulgogi|Bulgogi|Bulgogi|プルコギ|불고기
food.dish.bun_cha|Bún chả|Bún chả|Bún chả|ブンチャー|분짜
food.dish.burritos|Burritos|Burritos|Burritos|ブリトー|부리토
food.dish.butter_chicken|Pollo con mantequilla|Poulet au beurre|Frango com manteiga|バターチキン|버터 치킨
food.dish.cacio_e_pepe|Cacio e pepe|Cacio e pepe|Cacio e pepe|カチョ・エ・ペペ|카초 에 페페
food.dish.cantonese_roast_meat|Carnes asadas cantonesas|Rôtis cantonais|Carnes assadas cantonesas|広東焼味|광둥식 구이
food.dish.carbonara|Carbonara|Carbonara|Carbonara|カルボナーラ|카르보나라
food.dish.ceviche|Ceviche|Ceviche|Ceviche|セビーチェ|세비체
food.dish.char_siu|Char siu|Char siu|Char siu|チャーシュー|차슈
food.dish.cheesecake|Tarta de queso|Cheesecake|Cheesecake|チーズケーキ|치즈케이크
food.dish.churrasco|Churrasco|Churrasco|Churrasco|シュラスコ|슈하스코
food.dish.churros|Churros|Churros|Churros|チュロス|츄러스
food.dish.clam_chowder|Sopa de almejas|Chaudrée de palourdes|Sopa de amêijoas|クラムチャウダー|클램 차우더
food.dish.claypot_rice|Arroz en cazuela de barro|Riz en cocotte d'argile|Arroz em panela de barro|土鍋ご飯|뚝배기밥
food.dish.congee|Congee|Congee|Papa de arroz|中華粥|죽
food.dish.cookies|Galletas|Biscuits|Bolachas|クッキー|쿠키
food.dish.creme_brulee|Crème brûlée|Crème brûlée|Crème brûlée|クレームブリュレ|크렘 브륄레
food.dish.crepes|Crepes|Crêpes|Crepes|クレープ|크레페
food.dish.croissant|Croissant|Croissant|Croissant|クロワッサン|크루아상
food.dish.curry_laksa|Laksa al curry|Laksa au curry|Laksa de caril|カレーラクサ|커리 락사
food.dish.dan_dan_noodles|Fideos dan dan|Nouilles dan dan|Noodles dan dan|担々麺|탄탄면
food.dish.donburi|Donburi|Donburi|Donburi|丼もの|돈부리
food.dish.donuts|Donuts|Donuts|Donuts|ドーナツ|도넛
food.dish.egg_tart|Tarta de huevo|Tarte aux œufs|Tarte de ovo|エッグタルト|에그타르트
food.dish.empanadas|Empanadas|Empanadas|Empadas|エンパナーダ|엠파나다
food.dish.feijoada|Feijoada|Feijoada|Feijoada|フェジョアーダ|페이조아다
food.dish.fish_and_chips|Fish and chips|Fish and chips|Fish and chips|フィッシュ・アンド・チップス|피시 앤 칩스
food.dish.french_toast|Tostada francesa|Pain perdu|Torrada francesa|フレンチトースト|프렌치토스트
food.dish.french_toast_hong_kong_style|Tostada francesa al estilo de Hong Kong|Pain perdu hongkongais|Torrada francesa ao estilo de Hong Kong|香港式フレンチトースト|홍콩식 프렌치토스트
food.dish.fried_chicken|Pollo frito|Poulet frit|Frango frito|フライドチキン|프라이드치킨
food.dish.full_english_breakfast|Desayuno inglés completo|Petit-déjeuner anglais complet|Pequeno-almoço inglês completo|フル・イングリッシュ・ブレックファスト|풀 잉글리시 브렉퍼스트
food.dish.gelato|Gelato|Gelato|Gelato|ジェラート|젤라토
food.dish.green_curry|Curry verde|Curry vert|Caril verde|グリーンカレー|그린 커리
food.dish.gua_bao|Gua bao|Gua bao|Gua bao|刈包|과바오
food.dish.guacamole|Guacamole|Guacamole|Guacamole|ワカモレ|과카몰리
food.dish.gyudon|Gyudon|Gyudon|Gyudon|牛丼|규동
food.dish.hainanese_chicken_rice|Arroz con pollo de Hainan|Riz au poulet de Hainan|Arroz de frango à Hainan|海南鶏飯|하이난 치킨라이스
food.dish.hong_kong_milk_tea|Té con leche de Hong Kong|Thé au lait hongkongais|Chá com leite de Hong Kong|香港式ミルクティー|홍콩식 밀크티
food.dish.hot_dogs|Perritos calientes|Hot-dogs|Cachorros-quentes|ホットドッグ|핫도그
food.dish.japanese_cheesecake|Cheesecake japonés|Cheesecake japonais|Cheesecake japonês|スフレチーズケーキ|일본식 치즈케이크
food.dish.japanese_curry|Curry japonés|Curry japonais|Caril japonês|カレーライス|일본식 카레
food.dish.japchae|Japchae|Japchae|Japchae|チャプチェ|잡채
food.dish.kimbap|Kimbap|Kimbap|Kimbap|キンパ|김밥
food.dish.kimchi|Kimchi|Kimchi|Kimchi|キムチ|김치
food.dish.kung_pao_chicken|Pollo kung pao|Poulet kung pao|Frango kung pao|宮保鶏丁|쿵파오 치킨
food.dish.laksa|Laksa|Laksa|Laksa|ラクサ|락사
food.dish.lasagna|Lasaña|Lasagnes|Lasanha|ラザニア|라자냐
food.dish.lobster_rolls|Rolls de langosta|Lobster rolls|Rolinhos de lagosta|ロブスターロール|랍스터 롤
food.dish.lu_rou_fan|Lu rou fan|Lu rou fan|Lu rou fan|魯肉飯|루러우판
food.dish.macarons|Macarons|Macarons|Macarons|マカロン|마카롱
food.dish.mala_xiang_guo|Mala xiang guo|Mala xiang guo|Mala xiang guo|麻辣香鍋|마라샹궈
food.dish.mango_sticky_rice|Arroz pegajoso con mango|Riz gluant à la mangue|Arroz glutinoso com manga|マンゴースティッキーライス|망고 찹쌀밥
food.dish.mapo_tofu|Mapo tofu|Mapo tofu|Mapo tofu|麻婆豆腐|마파두부
food.dish.masala_dosa|Masala dosa|Masala dosa|Masala dosa|マサラドーサ|마살라 도사
food.dish.mochi|Mochi|Mochi|Mochi|もち|모찌
food.dish.naan|Naan|Naan|Naan|ナン|난
food.dish.naengmyeon|Naengmyeon|Naengmyeon|Naengmyeon|冷麺|냉면
food.dish.nasi_lemak|Nasi lemak|Nasi lemak|Nasi lemak|ナシレマ|나시 르막
food.dish.neapolitan_pizza|Pizza napolitana|Pizza napolitaine|Pizza napolitana|ナポリピッツァ|나폴리 피자
food.dish.new_york_pizza|Pizza de Nueva York|Pizza new-yorkaise|Pizza de Nova Iorque|ニューヨークピザ|뉴욕 피자
food.dish.okonomiyaki|Okonomiyaki|Okonomiyaki|Okonomiyaki|お好み焼き|오코노미야키
food.dish.omurice|Omurice|Omurice|Omurice|オムライス|오므라이스
food.dish.onigiri|Onigiri|Onigiri|Onigiri|おにぎり|오니기리
food.dish.oyakodon|Oyakodon|Oyakodon|Oyakodon|親子丼|오야코동
food.dish.oyster_omelette|Tortilla de ostras|Omelette aux huîtres|Omelete de ostras|牡蠣オムレツ|굴 오믈렛
food.dish.pad_thai|Pad thai|Pad thaï|Pad thai|パッタイ|팟타이
food.dish.paella|Paella|Paella|Paella|パエリア|파에야
food.dish.pancakes|Pancakes|Pancakes|Panquecas|パンケーキ|팬케이크
food.dish.panna_cotta|Panna cotta|Panna cotta|Panna cotta|パンナコッタ|판나코타
food.dish.pasta|Pasta|Pâtes|Massa|パスタ|파스타
food.dish.peking_duck|Pato de Pekín|Canard laqué de Pékin|Pato à Pequim|北京ダック|베이징 덕
food.dish.pho|Pho|Pho|Pho|フォー|쌀국수
food.dish.pineapple_bun|Bollo de piña|Pain ananas|Pão de ananás|パイナップルパン|파인애플번
food.dish.poutine|Poutine|Poutine|Poutine|プーティン|푸틴
food.dish.quesadillas|Quesadillas|Quesadillas|Quesadillas|ケサディーヤ|케사디야
food.dish.ratatouille|Ratatouille|Ratatouille|Ratatouille|ラタトゥイユ|라따뚜이
food.dish.rice_noodle_rolls|Rollos de fideos de arroz|Rouleaux de nouilles de riz|Rolos de massa de arroz|腸粉|창펀
food.dish.risotto|Risotto|Risotto|Risotto|リゾット|리소토
food.dish.roast_goose|Ganso asado|Oie rôtie|Ganso assado|ローストグース|구운 거위
food.dish.roti_canai|Roti canai|Roti canai|Roti canai|ロティチャナイ|로티 차나이
food.dish.samgyeopsal|Samgyeopsal|Samgyeopsal|Samgyeopsal|サムギョプサル|삼겹살
food.dish.samosa|Samosa|Samosa|Samosa|サモサ|사모사
food.dish.satay|Satay|Satay|Satay|サテ|사테
food.dish.scallion_pancakes|Tortitas de cebolleta|Galettes aux oignons verts|Panquecas de cebolinho|葱油餅|파전
food.dish.sheng_jian_bao|Sheng jian bao|Sheng jian bao|Sheng jian bao|生煎包|셩젠바오
food.dish.sichuan_boiled_fish|Pescado hervido de Sichuan|Poisson bouilli du Sichuan|Peixe cozido de Sichuan|四川水煮魚|쓰촨 수이주위
food.dish.smoked_brisket|Brisket ahumado|Poitrine de bœuf fumée|Peito bovino fumado|スモークブリスケット|훈제 브리스킷
food.dish.soba|Soba|Soba|Soba|そば|소바
food.dish.souffle|Soufflé|Soufflé|Soufflé|スフレ|수플레
food.dish.steak_frites|Bistec con patatas fritas|Steak-frites|Bife com batatas fritas|ステーキフリット|스테이크 프리트
food.dish.stinky_tofu|Tofu apestoso|Tofu puant|Tofu fedorento|臭豆腐|취두부
food.dish.sunday_roast|Asado dominical|Sunday roast|Assado de domingo|サンデーロースト|선데이 로스트
food.dish.sundubu_jjigae|Sundubu jjigae|Sundubu jjigae|Sundubu jjigae|スンドゥブチゲ|순두부찌개
food.dish.tacos|Tacos|Tacos|Tacos|タコス|타코
food.dish.taiwanese_beef_noodles|Fideos taiwaneses con ternera|Nouilles taïwanaises au bœuf|Noodles taiwaneses de carne|台湾牛肉麺|대만 우육면
food.dish.takoyaki|Takoyaki|Takoyaki|Takoyaki|たこ焼き|타코야키
food.dish.tandoori_chicken|Pollo tandoori|Poulet tandoori|Frango tandoori|タンドリーチキン|탄두리 치킨
food.dish.tapas|Tapas|Tapas|Tapas|タパス|타파스
food.dish.tempura|Tempura|Tempura|Tempura|天ぷら|덴푸라
food.dish.texas_bbq|Barbacoa de Texas|Barbecue texan|Churrasco do Texas|テキサスBBQ|텍사스 바비큐
food.dish.tiramisu|Tiramisú|Tiramisu|Tiramisù|ティラミス|티라미수
food.dish.tom_yum|Tom yum|Tom yum|Tom yum|トムヤム|똠얌
food.dish.tonkatsu|Tonkatsu|Tonkatsu|Tonkatsu|とんかつ|돈카츠
food.dish.tortilla_espanola|Tortilla española|Tortilla espagnole|Tortilha espanhola|スペイン風オムレツ|스페인식 오믈렛
food.dish.tteokbokki|Tteokbokki|Tteokbokki|Tteokbokki|トッポッキ|떡볶이
food.dish.udon|Udon|Udon|Udon|うどん|우동
food.dish.waffles|Gofres|Gaufres|Waffles|ワッフル|와플
food.dish.wonton_noodles|Fideos wonton|Nouilles wonton|Noodles wonton|ワンタン麺|완탕면
food.dish.xiaolongbao|Xiaolongbao|Xiaolongbao|Xiaolongbao|小籠包|샤오룽바오
food.drink.americano|Café americano|Café americano|Café americano|アメリカーノ|아메리카노
food.drink.belgian_beer|Cerveza belga|Bière belge|Cerveja belga|ベルギービール|벨기에 맥주
food.drink.black_tea|Té negro|Thé noir|Chá preto|紅茶|홍차
food.drink.bourbon|Bourbon|Bourbon|Bourbon|バーボン|버번
food.drink.cafe_latte|Café latte|Café latte|Café latte|カフェラテ|카페라테
food.drink.cappuccino|Capuchino|Cappuccino|Cappuccino|カプチーノ|카푸치노
food.drink.chai|Chai|Chai|Chai|チャイ|차이
food.drink.champagne|Champán|Champagne|Champanhe|シャンパン|샴페인
food.drink.classic_cocktails|Cócteles clásicos|Cocktails classiques|Cocktails clássicos|クラシックカクテル|클래식 칵테일
food.drink.cocktail_bars|Bares de cócteles|Bars à cocktails|Bares de cocktails|カクテルバー|칵테일 바
food.drink.cocktails|Cócteles|Cocktails|Cocktails|カクテル|칵테일
food.drink.coffee_gear|Equipo de café|Matériel de café|Equipamento de café|コーヒー器具|커피 장비
food.drink.coffee_grinders|Molinillos de café|Moulins à café|Moinhos de café|コーヒーグラインダー|커피 그라인더
food.drink.coffee_roasting|Tostado de café|Torréfaction du café|Torra de café|コーヒー焙煎|커피 로스팅
food.drink.cold_brew_coffee|Café cold brew|Café infusé à froid|Café cold brew|コールドブリュー|콜드브루
food.drink.craft_beer|Cerveza artesanal|Bière artisanale|Cerveja artesanal|クラフトビール|수제 맥주
food.drink.craft_soda|Refresco artesanal|Soda artisanal|Refrigerante artesanal|クラフトソーダ|수제 탄산음료
food.drink.flat_white|Flat white|Flat white|Flat white|フラットホワイト|플랫화이트
food.drink.fresh_juice|Zumo fresco|Jus frais|Sumo fresco|フレッシュジュース|생과일 주스
food.drink.gin|Ginebra|Gin|Gin|ジン|진
food.drink.gongfu_tea|Té gongfu|Thé gongfu|Chá gongfu|工夫茶|공부차
food.drink.green_tea|Té verde|Thé vert|Chá verde|緑茶|녹차
food.drink.herbal_tea|Infusión de hierbas|Tisane|Chá de ervas|ハーブティー|허브티
food.drink.home_bartending|Coctelería en casa|Cocktails à la maison|Bartending em casa|ホームバーテンディング|홈 바텐딩
food.drink.home_espresso|Espresso en casa|Espresso à la maison|Espresso em casa|おうちエスプレッソ|홈 에스프레소
food.drink.hot_chocolate|Chocolate caliente|Chocolat chaud|Chocolate quente|ホットチョコレート|핫초코
food.drink.ipa_beer|Cerveza IPA|Bière IPA|Cerveja IPA|IPAビール|IPA 맥주
food.drink.japanese_sake|Sake japonés|Saké japonais|Saquê japonês|日本酒|사케
food.drink.japanese_whisky|Whisky japonés|Whisky japonais|Whisky japonês|ジャパニーズウイスキー|일본 위스키
food.drink.jasmine_tea|Té de jazmín|Thé au jasmin|Chá de jasmim|ジャスミン茶|자스민차
food.drink.kombucha|Kombucha|Kombucha|Kombucha|コンブチャ|콤부차
food.drink.milk_tea|Té con leche|Thé au lait|Chá com leite|ミルクティー|밀크티
food.drink.mocha|Moca|Moka|Mocha|モカ|모카
food.drink.mocktails|Cócteles sin alcohol|Mocktails|Mocktails|モクテル|목테일
food.drink.natural_wine|Vino natural|Vin naturel|Vinho natural|ナチュラルワイン|내추럴 와인
food.drink.oolong_tea|Té oolong|Thé oolong|Chá oolong|烏龍茶|우롱차
food.drink.pu_erh_tea|Té pu-erh|Thé pu-erh|Chá pu-erh|プーアル茶|보이차
food.drink.red_wine|Vino tinto|Vin rouge|Vinho tinto|赤ワイン|레드와인
food.drink.rum|Ron|Rhum|Rum|ラム|럼
food.drink.scotch_whisky|Whisky escocés|Whisky écossais|Whisky escocês|スコッチウイスキー|스카치위스키
food.drink.single_origin_coffee|Café de origen único|Café single origin|Café de origem única|シングルオリジンコーヒー|싱글 오리진 커피
food.drink.smoothies|Batidos|Smoothies|Smoothies|スムージー|스무디
food.drink.sparkling_water|Agua con gas|Eau pétillante|Água com gás|炭酸水|탄산수
food.drink.stout_beer|Cerveza stout|Bière stout|Cerveja stout|スタウトビール|스타우트 맥주
food.drink.tea_ceremony|Ceremonia del té|Cérémonie du thé|Cerimónia do chá|茶道|다도
food.drink.tequila|Tequila|Tequila|Tequila|テキーラ|테킬라
food.drink.thai_milk_tea|Té tailandés con leche|Thé au lait thaï|Chá tailandês com leite|タイミルクティー|태국 밀크티
food.drink.tiki_cocktails|Cócteles tiki|Cocktails tiki|Cocktails tiki|ティキカクテル|티키 칵테일
food.drink.whisky_appreciation|Cata de whisky|Dégustation de whisky|Prova de whisky|ウイスキー鑑賞|위스키 테이스팅
food.drink.white_wine|Vino blanco|Vin blanc|Vinho branco|白ワイン|화이트와인
food.drink.wine_appreciation|Cata de vinos|Dégustation de vin|Prova de vinhos|ワイン鑑賞|와인 테이스팅
food.drink.yerba_mate|Yerba mate|Maté|Erva-mate|マテ茶|마테차
food.fermentation|Fermentación|Fermentation|Fermentação|発酵食品|발효 음식
food.food_markets|Mercados gastronómicos|Marchés alimentaires|Mercados de comida|フードマーケット|푸드 마켓
food.food_preserving|Conservación de alimentos|Conservation des aliments|Conservação de alimentos|食品保存|식품 보존
food.healthy_cooking|Cocina saludable|Cuisine saine|Cozinha saudável|ヘルシー料理|건강 요리
food.home_brewing|Elaboración casera de bebidas|Brassage maison|Produção caseira de bebidas|自家醸造|홈브루잉
food.meal_planning|Planificación de comidas|Planification des repas|Planeamento de refeições|献立計画|식단 계획
food.meal_prep|Preparación de comidas|Préparation des repas|Preparação de refeições|作り置き・ミールプレップ|밀프렙
food.night_markets|Mercados nocturnos|Marchés de nuit|Mercados noturnos|夜市|야시장
food.omakase|Omakase|Omakase|Omakase|おまかせ|오마카세
food.pastry_making|Elaboración de pastelería|Pâtisserie|Pastelaria|洋菓子作り|제과
food.pickling|Encurtidos|Pickles et conserves au vinaigre|Conservas em vinagre|漬物作り|피클링
food.potlucks|Comidas compartidas|Repas-partage|Refeições partilhadas|持ち寄りパーティー|포틀럭
food.recipe_swaps|Intercambio de recetas|Échanges de recettes|Trocas de receitas|レシピ交換|레시피 교환
food.restaurant_hopping|Ruta de restaurantes|Tournée des restaurants|Circuito de restaurantes|レストラン巡り|맛집 투어
food.sourdough_baking|Pan de masa madre|Pain au levain|Pão de massa mãe|サワードウ作り|사워도우 베이킹
food.tea_house_hopping|Ruta de casas de té|Tournée des maisons de thé|Circuito de casas de chá|茶館巡り|찻집 투어
food.tea_tasting|Cata de té|Dégustation de thé|Prova de chá|お茶のテイスティング|차 테이스팅
food.yum_cha|Yum cha|Yum cha|Yum cha|飲茶|얌차''';
