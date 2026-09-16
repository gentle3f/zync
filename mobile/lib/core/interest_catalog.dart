import 'models.dart';

class InterestCatalog {
  const InterestCatalog._();

  static const List<InterestDefinition> seed = [
    InterestDefinition(id: 'sports.badminton', category: 'sports', labels: {'en':'Badminton','zh-Hant':'羽毛球','zh-Hans':'羽毛球','ja':'バドミントン','ko':'배드민턴','es':'Bádminton','fr':'Badminton','pt':'Badminton'}, aliases: ['shuttlecock']),
    InterestDefinition(id: 'sports.tennis', category: 'sports', labels: {'en':'Tennis','zh-Hant':'網球','zh-Hans':'网球','ja':'テニス','ko':'테니스','es':'Tenis','fr':'Tennis','pt':'Tênis'}),
    InterestDefinition(id: 'sports.running', category: 'sports', labels: {'en':'Running','zh-Hant':'跑步','zh-Hans':'跑步','ja':'ランニング','ko':'러닝','es':'Correr','fr':'Course à pied','pt':'Corrida'}),
    InterestDefinition(id: 'sports.hiking', category: 'sports', labels: {'en':'Hiking','zh-Hant':'行山','zh-Hans':'徒步','ja':'ハイキング','ko':'하이킹','es':'Senderismo','fr':'Randonnée','pt':'Trilha'}),
    InterestDefinition(id: 'sports.football', category: 'sports', labels: {'en':'Football / Soccer','zh-Hant':'足球','zh-Hans':'足球','ja':'サッカー','ko':'축구','es':'Fútbol','fr':'Football','pt':'Futebol'}),
    InterestDefinition(id: 'sports.basketball', category: 'sports', labels: {'en':'Basketball','zh-Hant':'籃球','zh-Hans':'篮球','ja':'バスケットボール','ko':'농구','es':'Baloncesto','fr':'Basket-ball','pt':'Basquete'}),
    InterestDefinition(id: 'sports.gym', category: 'sports', labels: {'en':'Gym & Fitness','zh-Hant':'健身','zh-Hans':'健身','ja':'筋トレ','ko':'피트니스','es':'Fitness','fr':'Fitness','pt':'Academia'}),
    InterestDefinition(id: 'motorsport.formula1', category: 'motorsport', labels: {'en':'Formula 1','zh-Hant':'F1 一級方程式','zh-Hans':'F1 一级方程式','ja':'F1','ko':'포뮬러 1','es':'Fórmula 1','fr':'Formule 1','pt':'Fórmula 1'}, aliases: ['f1','formula one']),
    InterestDefinition(id: 'motorsport.cars', category: 'motorsport', labels: {'en':'Cars','zh-Hant':'汽車','zh-Hans':'汽车','ja':'クルマ','ko':'자동차','es':'Coches','fr':'Automobile','pt':'Carros'}),
    InterestDefinition(id: 'media.anime', category: 'entertainment', labels: {'en':'Anime','zh-Hant':'動畫','zh-Hans':'动漫','ja':'アニメ','ko':'애니메이션','es':'Anime','fr':'Anime','pt':'Anime'}),
    InterestDefinition(id: 'media.manga', category: 'entertainment', labels: {'en':'Manga','zh-Hant':'漫畫','zh-Hans':'漫画','ja':'漫画','ko':'만화','es':'Manga','fr':'Manga','pt':'Mangá'}),
    InterestDefinition(id: 'anime.jojo', category: 'entertainment', labels: {'en':"JoJo's Bizarre Adventure",'zh-Hant':'JoJo的奇妙冒險','zh-Hans':'JoJo的奇妙冒险','ja':'ジョジョの奇妙な冒険','ko':'죠죠의 기묘한 모험','es':"JoJo's Bizarre Adventure",'fr':"JoJo's Bizarre Adventure",'pt':"JoJo's Bizarre Adventure"}, aliases: ['jojo','ジョジョ']),
    InterestDefinition(id: 'media.movies', category: 'entertainment', labels: {'en':'Movies','zh-Hant':'電影','zh-Hans':'电影','ja':'映画','ko':'영화','es':'Cine','fr':'Cinéma','pt':'Filmes'}),
    InterestDefinition(id: 'media.tv', category: 'entertainment', labels: {'en':'TV Series','zh-Hant':'電視劇','zh-Hans':'电视剧','ja':'ドラマ','ko':'드라마','es':'Series','fr':'Séries','pt':'Séries'}),
    InterestDefinition(id: 'gaming.video', category: 'gaming', labels: {'en':'Video Games','zh-Hant':'電子遊戲','zh-Hans':'电子游戏','ja':'ビデオゲーム','ko':'비디오 게임','es':'Videojuegos','fr':'Jeux vidéo','pt':'Videogames'}),
    InterestDefinition(id: 'gaming.board', category: 'gaming', labels: {'en':'Board Games','zh-Hant':'桌上遊戲','zh-Hans':'桌游','ja':'ボードゲーム','ko':'보드게임','es':'Juegos de mesa','fr':'Jeux de société','pt':'Jogos de tabuleiro'}),
    InterestDefinition(id: 'music.pop', category: 'music', labels: {'en':'Pop Music','zh-Hant':'流行音樂','zh-Hans':'流行音乐','ja':'ポップミュージック','ko':'팝 음악','es':'Pop','fr':'Pop','pt':'Pop'}),
    InterestDefinition(id: 'music.rock', category: 'music', labels: {'en':'Rock Music','zh-Hant':'搖滾樂','zh-Hans':'摇滚乐','ja':'ロック','ko':'록 음악','es':'Rock','fr':'Rock','pt':'Rock'}),
    InterestDefinition(id: 'music.classical', category: 'music', labels: {'en':'Classical Music','zh-Hant':'古典音樂','zh-Hans':'古典音乐','ja':'クラシック音楽','ko':'클래식 음악','es':'Música clásica','fr':'Musique classique','pt':'Música clássica'}),
    InterestDefinition(id: 'travel.general', category: 'travel', labels: {'en':'Travel','zh-Hant':'旅行','zh-Hans':'旅行','ja':'旅行','ko':'여행','es':'Viajes','fr':'Voyage','pt':'Viagens'}),
    InterestDefinition(id: 'travel.japan', category: 'travel', labels: {'en':'Japan Travel','zh-Hant':'日本旅行','zh-Hans':'日本旅行','ja':'日本旅行','ko':'일본 여행','es':'Viajar a Japón','fr':'Voyage au Japon','pt':'Viagem ao Japão'}),
    InterestDefinition(id: 'travel.roadtrip', category: 'travel', labels: {'en':'Road Trips','zh-Hant':'自駕遊','zh-Hans':'自驾游','ja':'ロードトリップ','ko':'로드트립','es':'Viajes por carretera','fr':'Road trips','pt':'Viagens de carro'}),
    InterestDefinition(id: 'food.japanese', category: 'food', labels: {'en':'Japanese Food','zh-Hant':'日本料理','zh-Hans':'日本料理','ja':'日本料理','ko':'일식','es':'Comida japonesa','fr':'Cuisine japonaise','pt':'Comida japonesa'}),
    InterestDefinition(id: 'food.coffee', category: 'food', labels: {'en':'Coffee','zh-Hant':'咖啡','zh-Hans':'咖啡','ja':'コーヒー','ko':'커피','es':'Café','fr':'Café','pt':'Café'}),
    InterestDefinition(id: 'food.cooking', category: 'food', labels: {'en':'Cooking','zh-Hant':'烹飪','zh-Hans':'烹饪','ja':'料理','ko':'요리','es':'Cocina','fr':'Cuisine','pt':'Culinária'}),
    InterestDefinition(id: 'technology.ai', category: 'technology', labels: {'en':'Artificial Intelligence','zh-Hant':'人工智能','zh-Hans':'人工智能','ja':'人工知能','ko':'인공지능','es':'Inteligencia artificial','fr':'Intelligence artificielle','pt':'Inteligência artificial'}, aliases: ['ai','a.i.']),
    InterestDefinition(id: 'technology.gadgets', category: 'technology', labels: {'en':'Technology & Gadgets','zh-Hant':'科技與電子產品','zh-Hans':'科技与电子产品','ja':'テクノロジー','ko':'기술과 기기','es':'Tecnología','fr':'Technologie','pt':'Tecnologia'}),
    InterestDefinition(id: 'photography.general', category: 'arts', labels: {'en':'Photography','zh-Hant':'攝影','zh-Hans':'摄影','ja':'写真','ko':'사진','es':'Fotografía','fr':'Photographie','pt':'Fotografia'}),
    InterestDefinition(id: 'photography.street', category: 'arts', labels: {'en':'Street Photography','zh-Hant':'街頭攝影','zh-Hans':'街头摄影','ja':'ストリート写真','ko':'스트리트 사진','es':'Fotografía callejera','fr':'Photo de rue','pt':'Fotografia de rua'}),
    InterestDefinition(id: 'arts.drawing', category: 'arts', labels: {'en':'Drawing','zh-Hant':'繪畫','zh-Hans':'绘画','ja':'絵を描く','ko':'그림','es':'Dibujo','fr':'Dessin','pt':'Desenho'}),
    InterestDefinition(id: 'books.reading', category: 'learning', labels: {'en':'Reading','zh-Hant':'閱讀','zh-Hans':'阅读','ja':'読書','ko':'독서','es':'Lectura','fr':'Lecture','pt':'Leitura'}),
    InterestDefinition(id: 'learning.languages', category: 'learning', labels: {'en':'Language Learning','zh-Hant':'學語言','zh-Hans':'学语言','ja':'語学学習','ko':'언어 학습','es':'Aprender idiomas','fr':'Apprentissage des langues','pt':'Aprender idiomas'}),
    InterestDefinition(id: 'history.general', category: 'learning', labels: {'en':'History','zh-Hant':'歷史','zh-Hans':'历史','ja':'歴史','ko':'역사','es':'Historia','fr':'Histoire','pt':'História'}),
    InterestDefinition(id: 'transport.railways', category: 'transport', labels: {'en':'Railways & Trains','zh-Hant':'鐵路與火車','zh-Hans':'铁路与火车','ja':'鉄道','ko':'철도','es':'Ferrocarriles','fr':'Chemins de fer','pt':'Ferrovias'}, aliases: ['railfan','trains','trainspotting']),
    InterestDefinition(id: 'transport.modelrailways', category: 'transport', labels: {'en':'Model Railways','zh-Hant':'模型鐵路','zh-Hans':'模型铁路','ja':'鉄道模型','ko':'철도 모형','es':'Modelismo ferroviario','fr':'Modélisme ferroviaire','pt':'Ferromodelismo'}),
    InterestDefinition(id: 'outdoors.cycling', category: 'outdoors', labels: {'en':'Cycling','zh-Hant':'踩單車','zh-Hans':'骑行','ja':'サイクリング','ko':'사이클링','es':'Ciclismo','fr':'Cyclisme','pt':'Ciclismo'}),
    InterestDefinition(id: 'outdoors.camping', category: 'outdoors', labels: {'en':'Camping','zh-Hant':'露營','zh-Hans':'露营','ja':'キャンプ','ko':'캠핑','es':'Camping','fr':'Camping','pt':'Camping'}),
    InterestDefinition(id: 'collecting.lego', category: 'collecting', labels: {'en':'LEGO','zh-Hant':'LEGO 樂高','zh-Hans':'LEGO 乐高','ja':'レゴ','ko':'레고','es':'LEGO','fr':'LEGO','pt':'LEGO'}),
    InterestDefinition(id: 'collecting.watches', category: 'collecting', labels: {'en':'Watches','zh-Hant':'手錶','zh-Hans':'手表','ja':'腕時計','ko':'시계','es':'Relojes','fr':'Montres','pt':'Relógios'}),
  ];

  static InterestDefinition? byId(String id) {
    for (final item in seed) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<InterestDefinition> search(String query, String locale) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return seed;
    return seed.where((item) {
      if (item.id.toLowerCase().contains(q)) return true;
      if (item.category.toLowerCase().contains(q)) return true;
      if (item.aliases.any((alias) => alias.toLowerCase().contains(q))) return true;
      return item.labels.values.any((label) => label.toLowerCase().contains(q));
    }).toList();
  }
}
