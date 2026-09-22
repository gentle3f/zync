/// Food localization batch A: core food, cooking and cuisines.
/// Format: id|es|fr|pt|ja|ko
const String kInterestLocaleFoodARaw = r'''food.baking|Horneado y repostería|Boulangerie et pâtisserie|Panificação e pastelaria|お菓子・パン作り|베이킹
food.bbq|Barbacoa y parrilla|Barbecue et grillades|Churrasco e grelhados|BBQ・グリル|바비큐·그릴
food.bread|Pan|Pain|Pão|パン|빵
food.brunch|Brunch|Brunch|Brunch|ブランチ|브런치
food.bubble_tea|Té de burbujas|Bubble tea|Bubble tea|タピオカティー|버블티
food.burgers|Hamburguesas|Burgers|Hambúrgueres|ハンバーガー|햄버거
food.cafe_hopping|Ruta de cafés|Tournée des cafés|Circuito de cafés|カフェ巡り|카페 투어
food.cantonese|Comida cantonesa|Cuisine cantonaise|Comida cantonesa|広東料理|광둥 요리
food.cheese|Queso|Fromage|Queijo|チーズ|치즈
food.chinese|Comida china|Cuisine chinoise|Comida chinesa|中華料理|중국 요리
food.chinese_tea|Té chino|Thé chinois|Chá chinês|中国茶|중국차
food.chocolate|Chocolate|Chocolat|Chocolate|チョコレート|초콜릿
food.coffee|Café|Café|Café|コーヒー|커피
food.cooking|Cocina|Cuisine|Cozinhar|料理|요리
food.desserts|Postres|Desserts|Sobremesas|デザート|디저트
food.dim_sum|Dim sum|Dim sum|Dim sum|点心|딤섬
food.espresso|Espresso|Espresso|Expresso|エスプレッソ|에스프레소
food.fine_dining|Alta cocina|Gastronomie|Alta gastronomia|高級レストラン|파인다이닝
food.food_hunting|Búsqueda gastronómica|Découverte gourmande|Descoberta gastronómica|食べ歩き|맛집 탐방
food.french|Comida francesa|Cuisine française|Comida francesa|フランス料理|프랑스 요리
food.hong_kong|Comida de Hong Kong|Cuisine hongkongaise|Comida de Hong Kong|香港グルメ|홍콩 음식
food.hot_pot|Hot pot|Fondue chinoise|Hot pot|火鍋|훠궈
food.ice_cream|Helado|Glace|Gelado|アイスクリーム|아이스크림
food.indian|Comida india|Cuisine indienne|Comida indiana|インド料理|인도 요리
food.italian|Comida italiana|Cuisine italienne|Comida italiana|イタリア料理|이탈리아 요리
food.japanese|Comida japonesa|Cuisine japonaise|Comida japonesa|日本料理|일본 요리
food.korean|Comida coreana|Cuisine coréenne|Comida coreana|韓国料理|한식
food.latte_art|Latte art|Latte art|Latte art|ラテアート|라테 아트
food.malaysian|Comida malasia|Cuisine malaisienne|Comida malaia|マレーシア料理|말레이시아 요리
food.matcha|Matcha|Matcha|Matcha|抹茶|말차
food.mediterranean|Comida mediterránea|Cuisine méditerranéenne|Comida mediterrânica|地中海料理|지중해 요리
food.mexican|Comida mexicana|Cuisine mexicaine|Comida mexicana|メキシコ料理|멕시코 요리
food.middle_eastern|Comida de Oriente Medio|Cuisine du Moyen-Orient|Comida do Médio Oriente|中東料理|중동 요리
food.noodles|Fideos|Nouilles|Massas e noodles|麺料理|면 요리
food.pizza|Pizza|Pizza|Pizza|ピザ|피자
food.pour_over|Café filtrado manual|Café filtre manuel|Café coado manual|ハンドドリップコーヒー|핸드드립 커피
food.ramen|Ramen|Ramen|Ramen|ラーメン|라멘
food.seafood|Marisco y pescado|Fruits de mer|Marisco e peixe|シーフード|해산물
food.sichuan|Comida de Sichuan|Cuisine sichuanaise|Comida de Sichuan|四川料理|쓰촨 요리
food.singaporean|Comida singapurense|Cuisine singapourienne|Comida singapurense|シンガポール料理|싱가포르 요리
food.spanish|Comida española|Cuisine espagnole|Comida espanhola|スペイン料理|스페인 요리
food.specialty_coffee|Café de especialidad|Café de spécialité|Café de especialidade|スペシャルティコーヒー|스페셜티 커피
food.steak|Bistec|Steak|Bife|ステーキ|스테이크
food.street_food|Comida callejera|Street food|Comida de rua|ストリートフード|길거리 음식
food.sushi|Sushi|Sushi|Sushi|寿司|스시
food.taiwanese|Comida taiwanesa|Cuisine taïwanaise|Comida taiwanesa|台湾料理|대만 요리
food.tea|Té|Thé|Chá|お茶|차
food.thai|Comida tailandesa|Cuisine thaïlandaise|Comida tailandesa|タイ料理|태국 요리
food.vegan|Comida vegana|Cuisine végane|Comida vegana|ヴィーガン料理|비건 음식
food.vegetarian|Comida vegetariana|Cuisine végétarienne|Comida vegetariana|ベジタリアン料理|채식 음식
food.vietnamese|Comida vietnamita|Cuisine vietnamienne|Comida vietnamita|ベトナム料理|베트남 요리
food.baking_classes|Clases de repostería|Cours de pâtisserie|Aulas de pastelaria|お菓子・パン教室|베이킹 클래스
food.bread_baking|Horneado de pan|Boulangerie maison|Panificação|パン作り|빵 만들기
food.cake_decorating|Decoración de tartas|Décoration de gâteaux|Decoração de bolos|ケーキデコレーション|케이크 데코레이션
food.canning|Conservas caseras|Mise en conserve|Conservas|瓶詰め・保存食|병조림
food.cheese_making|Elaboración de queso|Fabrication de fromage|Produção de queijo|チーズ作り|치즈 만들기
food.chocolate_making|Elaboración de chocolate|Fabrication de chocolat|Produção de chocolate|チョコレート作り|초콜릿 만들기
food.coffee_tasting|Cata de café|Dégustation de café|Prova de café|コーヒーテイスティング|커피 테이스팅
food.cookie_decorating|Decoración de galletas|Décoration de biscuits|Decoração de bolachas|クッキーデコレーション|쿠키 데코레이션
food.cooking_classes|Clases de cocina|Cours de cuisine|Aulas de culinária|料理教室|요리 클래스
food.cuisine_deep.argentinian_cuisine|Cocina argentina|Cuisine argentine|Cozinha argentina|アルゼンチン料理|아르헨티나 요리
food.cuisine_deep.austrian_food|Cocina austriaca|Cuisine autrichienne|Cozinha austríaca|オーストリア料理|오스트리아 요리
food.cuisine_deep.balinese_cuisine|Cocina balinesa|Cuisine balinaise|Cozinha balinesa|バリ料理|발리 요리
food.cuisine_deep.balkan_cuisine|Cocina balcánica|Cuisine des Balkans|Cozinha balcânica|バルカン料理|발칸 요리
food.cuisine_deep.bangladeshi_cuisine|Cocina bangladesí|Cuisine bangladaise|Cozinha bengalesa|バングラデシュ料理|방글라데시 요리
food.cuisine_deep.basque_cuisine|Cocina vasca|Cuisine basque|Cozinha basca|バスク料理|바스크 요리
food.cuisine_deep.beijing_cuisine|Cocina de Pekín|Cuisine de Pékin|Cozinha de Pequim|北京料理|베이징 요리
food.cuisine_deep.brazilian_cuisine|Cocina brasileña|Cuisine brésilienne|Cozinha brasileira|ブラジル料理|브라질 요리
food.cuisine_deep.british_food|Cocina británica|Cuisine britannique|Cozinha britânica|イギリス料理|영국 요리
food.cuisine_deep.burmese_cuisine|Cocina birmana|Cuisine birmane|Cozinha birmanesa|ミャンマー料理|미얀마 요리
food.cuisine_deep.cajun_cuisine|Cocina cajún|Cuisine cajun|Cozinha cajun|ケイジャン料理|케이준 요리
food.cuisine_deep.californian_cuisine|Cocina californiana|Cuisine californienne|Cozinha californiana|カリフォルニア料理|캘리포니아 요리
food.cuisine_deep.cambodian_cuisine|Cocina camboyana|Cuisine cambodgienne|Cozinha cambojana|カンボジア料理|캄보디아 요리
food.cuisine_deep.caribbean_cuisine|Cocina caribeña|Cuisine caribéenne|Cozinha caribenha|カリブ料理|카리브 요리
food.cuisine_deep.catalan_cuisine|Cocina catalana|Cuisine catalane|Cozinha catalã|カタルーニャ料理|카탈루냐 요리
food.cuisine_deep.chaoshan_cuisine|Cocina de Chaoshan|Cuisine de Chaoshan|Cozinha de Chaoshan|潮汕料理|차오산 요리
food.cuisine_deep.colombian_cuisine|Cocina colombiana|Cuisine colombienne|Cozinha colombiana|コロンビア料理|콜롬비아 요리
food.cuisine_deep.creole_cuisine|Cocina criolla|Cuisine créole|Cozinha crioula|クレオール料理|크리올 요리
food.cuisine_deep.cuban_cuisine|Cocina cubana|Cuisine cubaine|Cozinha cubana|キューバ料理|쿠바 요리
food.cuisine_deep.eastern_european_food|Cocina de Europa del Este|Cuisine d'Europe de l'Est|Cozinha da Europa de Leste|東欧料理|동유럽 요리
food.cuisine_deep.egyptian_cuisine|Cocina egipcia|Cuisine égyptienne|Cozinha egípcia|エジプト料理|이집트 요리
food.cuisine_deep.ethiopian_cuisine|Cocina etíope|Cuisine éthiopienne|Cozinha etíope|エチオピア料理|에티오피아 요리
food.cuisine_deep.farm_to_table|De la granja a la mesa|De la ferme à la table|Do campo à mesa|ファーム・トゥ・テーブル|팜투테이블
food.cuisine_deep.filipino_cuisine|Cocina filipina|Cuisine philippine|Cozinha filipina|フィリピン料理|필리핀 요리
food.cuisine_deep.fujian_cuisine|Cocina de Fujian|Cuisine du Fujian|Cozinha de Fujian|福建料理|푸젠 요리
food.cuisine_deep.fusion_cuisine|Cocina fusión|Cuisine fusion|Cozinha de fusão|フュージョン料理|퓨전 요리
food.cuisine_deep.georgian_cuisine|Cocina georgiana|Cuisine géorgienne|Cozinha georgiana|ジョージア料理|조지아 요리
food.cuisine_deep.german_food|Cocina alemana|Cuisine allemande|Cozinha alemã|ドイツ料理|독일 요리
food.cuisine_deep.gluten_free_food|Comida sin gluten|Cuisine sans gluten|Comida sem glúten|グルテンフリー料理|글루텐프리 음식
food.cuisine_deep.greek_cuisine|Cocina griega|Cuisine grecque|Cozinha grega|ギリシャ料理|그리스 요리
food.cuisine_deep.hakka_cuisine|Cocina hakka|Cuisine hakka|Cozinha hakka|客家料理|하카 요리
food.cuisine_deep.halal_food|Comida halal|Cuisine halal|Comida halal|ハラール料理|할랄 음식
food.cuisine_deep.hunan_cuisine|Cocina de Hunan|Cuisine du Hunan|Cozinha de Hunan|湖南料理|후난 요리
food.cuisine_deep.hungarian_food|Cocina húngara|Cuisine hongroise|Cozinha húngara|ハンガリー料理|헝가리 요리
food.cuisine_deep.indonesian_cuisine|Cocina indonesia|Cuisine indonésienne|Cozinha indonésia|インドネシア料理|인도네시아 요리
food.cuisine_deep.irish_food|Cocina irlandesa|Cuisine irlandaise|Cozinha irlandesa|アイルランド料理|아일랜드 요리
food.cuisine_deep.israeli_cuisine|Cocina israelí|Cuisine israélienne|Cozinha israelita|イスラエル料理|이스라엘 요리
food.cuisine_deep.izakaya_food|Comida de izakaya|Cuisine d'izakaya|Comida de izakaya|居酒屋料理|이자카야 음식
food.cuisine_deep.jiangsu_cuisine|Cocina de Jiangsu|Cuisine du Jiangsu|Cozinha de Jiangsu|江蘇料理|장쑤 요리
food.cuisine_deep.kaiseki|Kaiseki|Kaiseki|Kaiseki|懐石料理|가이세키
food.cuisine_deep.korean_bbq|Barbacoa coreana|Barbecue coréen|Churrasco coreano|韓国焼肉|코리안 바비큐
food.cuisine_deep.korean_fried_chicken|Pollo frito coreano|Poulet frit coréen|Frango frito coreano|韓国フライドチキン|한국식 치킨
food.cuisine_deep.kosher_food|Comida kosher|Cuisine casher|Comida kosher|コーシャ料理|코셔 음식
food.cuisine_deep.laotian_cuisine|Cocina laosiana|Cuisine laotienne|Cozinha laociana|ラオス料理|라오스 요리
food.cuisine_deep.lebanese_cuisine|Cocina libanesa|Cuisine libanaise|Cozinha libanesa|レバノン料理|레바논 요리
food.cuisine_deep.macanese_cuisine|Cocina macaense|Cuisine macanaise|Cozinha macaense|マカオ料理|마카오 요리
food.cuisine_deep.moroccan_cuisine|Cocina marroquí|Cuisine marocaine|Cozinha marroquina|モロッコ料理|모로코 요리
food.cuisine_deep.nepalese_cuisine|Cocina nepalesa|Cuisine népalaise|Cozinha nepalesa|ネパール料理|네팔 요리
food.cuisine_deep.new_york_food|Comida de Nueva York|Cuisine new-yorkaise|Comida de Nova Iorque|ニューヨークグルメ|뉴욕 음식
food.cuisine_deep.nigerian_cuisine|Cocina nigeriana|Cuisine nigériane|Cozinha nigeriana|ナイジェリア料理|나이지리아 요리
food.cuisine_deep.nordic_cuisine|Cocina nórdica|Cuisine nordique|Cozinha nórdica|北欧料理|북유럽 요리
food.cuisine_deep.okinawan_cuisine|Cocina de Okinawa|Cuisine d'Okinawa|Cozinha de Okinawa|沖縄料理|오키나와 요리
food.cuisine_deep.pakistani_cuisine|Cocina pakistaní|Cuisine pakistanaise|Cozinha paquistanesa|パキスタン料理|파키스탄 요리
food.cuisine_deep.persian_cuisine|Cocina persa|Cuisine perse|Cozinha persa|ペルシャ料理|페르시아 요리
food.cuisine_deep.peruvian_cuisine|Cocina peruana|Cuisine péruvienne|Cozinha peruana|ペルー料理|페루 요리
food.cuisine_deep.plant_based_cooking|Cocina basada en plantas|Cuisine végétale|Cozinha à base de plantas|プラントベース料理|식물성 요리
food.cuisine_deep.polish_food|Cocina polaca|Cuisine polonaise|Cozinha polaca|ポーランド料理|폴란드 요리
food.cuisine_deep.portuguese_food|Cocina portuguesa|Cuisine portugaise|Cozinha portuguesa|ポルトガル料理|포르투갈 요리
food.cuisine_deep.raw_food|Alimentación crudista|Cuisine crue|Alimentação crua|ローフード|생식
food.cuisine_deep.russian_food|Cocina rusa|Cuisine russe|Cozinha russa|ロシア料理|러시아 요리
food.cuisine_deep.shandong_cuisine|Cocina de Shandong|Cuisine du Shandong|Cozinha de Shandong|山東料理|산둥 요리
food.cuisine_deep.shanghainese_cuisine|Cocina de Shanghái|Cuisine shanghaienne|Cozinha de Xangai|上海料理|상하이 요리
food.cuisine_deep.south_african_cuisine|Cocina sudafricana|Cuisine sud-africaine|Cozinha sul-africana|南アフリカ料理|남아공 요리
food.cuisine_deep.southern_us_food|Cocina del sur de EE. UU.|Cuisine du Sud des États-Unis|Cozinha do sul dos EUA|アメリカ南部料理|미국 남부 요리
food.cuisine_deep.sri_lankan_cuisine|Cocina de Sri Lanka|Cuisine sri-lankaise|Cozinha do Sri Lanka|スリランカ料理|스리랑카 요리
food.cuisine_deep.swiss_food|Cocina suiza|Cuisine suisse|Cozinha suíça|スイス料理|스위스 요리
food.cuisine_deep.temple_food|Comida de templo|Cuisine de temple|Comida de templo|精進料理|사찰음식
food.cuisine_deep.teochew_cuisine|Cocina teochew|Cuisine teochew|Cozinha teochew|潮州料理|차오저우 요리
food.cuisine_deep.tex_mex|Tex-Mex|Tex-Mex|Tex-Mex|テクス・メクス料理|텍스멕스
food.cuisine_deep.turkish_cuisine|Cocina turca|Cuisine turque|Cozinha turca|トルコ料理|튀르키예 요리
food.cuisine_deep.ukrainian_food|Cocina ucraniana|Cuisine ukrainienne|Cozinha ucraniana|ウクライナ料理|우크라이나 요리
food.cuisine_deep.west_african_cuisine|Cocina de África Occidental|Cuisine d'Afrique de l'Ouest|Cozinha da África Ocidental|西アフリカ料理|서아프리카 요리
food.cuisine_deep.xinjiang_cuisine|Cocina de Xinjiang|Cuisine du Xinjiang|Cozinha de Xinjiang|新疆料理|신장 요리
food.cuisine_deep.yakiniku|Yakiniku|Yakiniku|Yakiniku|焼肉|야키니쿠
food.cuisine_deep.yakitori|Yakitori|Yakitori|Yakitori|焼き鳥|야키토리
food.cuisine_deep.yunnan_cuisine|Cocina de Yunnan|Cuisine du Yunnan|Cozinha de Yunnan|雲南料理|윈난 요리
food.cuisine_deep.zhejiang_cuisine|Cocina de Zhejiang|Cuisine du Zhejiang|Cozinha de Zhejiang|浙江料理|저장 요리
food.dai_pai_dong|Dai pai dong|Dai pai dong|Dai pai dong|大牌檔|다이파이동
food.dessert_hunting|Ruta de postres|Chasse aux desserts|Rota de sobremesas|スイーツ巡り|디저트 투어''';
