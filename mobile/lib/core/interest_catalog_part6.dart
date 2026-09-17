import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart6 = parseInterestCatalogRows(r'''motorsport.formula1|motorsport|motorsport|8|Formula 1|F1 一級方程式|F1 一级方程式|f1;formula one
motorsport.cars|transport|cars|9|Cars|汽車|汽车|automobiles;車;车
books.reading|learning|books|30|Reading|閱讀|阅读|books;讀書;读书
learning.languages|learning|languages|31|Language Learning|學語言|学语言|languages;語言學習;语言学习
history.general|learning|history|32|History|歷史|历史|
transport.railways|transport|railways|33|Railways & Trains|鐵路與火車|铁路与火车|railfan;trains;trainspotting;火車;火车
transport.modelrailways|collecting|railways|34|Model Railways|模型鐵路|模型铁路|model trains;火車模型
collecting.lego|collecting|building_toys|37|LEGO|LEGO 樂高|LEGO 乐高|lego;樂高;乐高
collecting.watches|collecting|watches|38|Watches|手錶|手表|watch collecting;腕錶
learning.fiction|learning|books|660|Fiction|||小說;小说
learning.nonfiction|learning|books|661|Non-fiction|||非虛構;非虚构
learning.science_fiction_books|learning|books|662|Science Fiction Books|||科幻小說;科幻小说
learning.fantasy_books|learning|books|663|Fantasy Books|||奇幻小說;奇幻小说
learning.mystery_books|learning|books|664|Mystery & Crime Books|||推理小說;推理小说
learning.romance_books|learning|books|665|Romance Books|||愛情小說;爱情小说
learning.biographies|learning|books|666|Biographies|||傳記;传记
learning.business_books|learning|books|667|Business Books|||商業書;商业书
learning.self_improvement|learning|books|668|Self-improvement Books|||自我提升
learning.poetry|learning|books|669|Poetry|||詩;诗
learning.book_clubs|learning|books|670|Book Clubs|||讀書會;读书会
learning.english|learning|languages|675|English|||英語;英语
learning.cantonese|learning|languages|676|Cantonese|||廣東話;粤语
learning.mandarin|learning|languages|677|Mandarin Chinese|||普通話;普通话;國語;国语
learning.japanese|learning|languages|678|Japanese|||日語;日语
learning.korean|learning|languages|679|Korean|||韓語;韩语
learning.spanish|learning|languages|680|Spanish|||西班牙語;西班牙语
learning.french|learning|languages|681|French|||法語;法语
learning.german|learning|languages|682|German|||德語;德语
learning.italian|learning|languages|683|Italian|||意大利語
learning.sign_language|learning|languages|684|Sign Language|||手語;手语
learning.philosophy|learning|knowledge|690|Philosophy|||哲學;哲学
learning.economics|learning|knowledge|691|Economics|||經濟學;经济学
learning.politics|learning|knowledge|692|Politics & Current Affairs|||時事;时事
learning.geography|learning|knowledge|693|Geography|||地理
learning.law|learning|knowledge|694|Law|||法律
learning.architecture|learning|knowledge|695|Architecture|||建築;建筑
learning.urban_planning|learning|knowledge|696|Urban Planning|||城市規劃;城市规划
learning.personal_finance|learning|knowledge|697|Personal Finance|||個人理財;个人理财
learning.investing|learning|knowledge|698|Investing|||投資;投资
learning.entrepreneurship|learning|knowledge|699|Entrepreneurship|||創業;创业
transport.classic_cars|transport|cars|705|Classic Cars|||古董車;老爷车
transport.sports_cars|transport|cars|706|Sports Cars|||跑車;跑车
transport.supercars|transport|cars|707|Supercars|||超跑
transport.electric_cars|transport|cars|708|Electric Cars|||電動車;电动车
transport.car_modification|transport|cars|709|Car Modification|||改車;改装车
transport.car_detailing|transport|cars|710|Car Detailing|||汽車美容;汽车美容
transport.off_roading|transport|cars|711|Off-roading|||越野車;越野车
transport.motorcycles|transport|cars|712|Motorcycles|||電單車;摩托车
transport.scooters|transport|cars|713|Scooters|||綿羊仔;踏板摩托
transport.aviation|transport|cars|714|Aviation|||航空
transport.planespotting|transport|cars|715|Planespotting|||睇飛機;观机
transport.public_transport|transport|cars|716|Public Transport|||公共交通
transport.metros|transport|cars|717|Metro Systems|||地鐵;地铁
transport.buses|transport|cars|718|Buses|||巴士;公交
transport.ferries|transport|cars|719|Ferries|||渡輪;轮渡
motorsport.motogp|motorsport|motorsport|725|MotoGP|||
motorsport.formula_e|motorsport|motorsport|726|Formula E|||
motorsport.wec|motorsport|motorsport|727|World Endurance Championship|||wec
motorsport.le_mans|motorsport|motorsport|728|Le Mans|||
motorsport.rally|motorsport|motorsport|729|Rallying|||拉力賽;拉力赛
motorsport.drifting|motorsport|motorsport|730|Drifting|||飄移;漂移
motorsport.karting|motorsport|motorsport|731|Karting|||高卡車;卡丁车
motorsport.sim_racing|motorsport|motorsport|732|Sim Racing|||模擬賽車;模拟赛车
collecting.stamps|collecting|collecting|740|Stamp Collecting|||集郵;集邮
collecting.coins|collecting|collecting|741|Coin Collecting|||錢幣收藏;钱币收藏
collecting.trading_cards|collecting|collecting|742|Trading Cards|||卡牌收藏
collecting.sneakers|collecting|collecting|743|Sneaker Collecting|||波鞋收藏;球鞋收藏
collecting.toys|collecting|collecting|744|Toy Collecting|||玩具收藏
collecting.action_figures|collecting|collecting|745|Action Figures|||人偶;手办
collecting.diecast_cars|collecting|collecting|746|Die-cast Cars|||車仔;合金车模
collecting.antiques|collecting|collecting|747|Antiques|||古董
collecting.art_collecting|collecting|collecting|748|Art Collecting|||藝術收藏;艺术收藏
collecting.perfume|collecting|collecting|749|Perfume Collecting|||香水
collecting.fountain_pens|collecting|collecting|750|Fountain Pens|||鋼筆;钢笔
collecting.stationery|collecting|collecting|751|Stationery|||文具
collecting.postcards|collecting|collecting|752|Postcards|||明信片
fashion.streetwear|fashion|fashion|760|Streetwear|||街頭服飾;街头穿搭
fashion.menswear|fashion|fashion|761|Menswear|||男裝;男装
fashion.womenswear|fashion|fashion|762|Womenswear|||女裝;女装
fashion.vintage_fashion|fashion|fashion|763|Vintage Fashion|||復古服裝;复古穿搭
fashion.luxury_fashion|fashion|fashion|764|Luxury Fashion|||奢侈品時裝;奢侈时尚
fashion.sneakers|fashion|fashion|765|Sneakers|||波鞋;球鞋
fashion.jewelry|fashion|fashion|766|Jewelry|||首飾;首饰
fashion.handbags|fashion|fashion|767|Handbags|||手袋;包包
fashion.makeup|fashion|fashion|768|Makeup|||化妝;化妆
fashion.skincare|fashion|fashion|769|Skincare|||護膚;护肤
fashion.haircare|fashion|fashion|770|Haircare|||護髮;护发
fashion.nail_art|fashion|fashion|771|Nail Art|||美甲
lifestyle.interior_design|lifestyle|home|775|Interior Design|||室內設計;室内设计
lifestyle.home_decor|lifestyle|home|776|Home Decor|||家居佈置;家居布置
lifestyle.houseplants|lifestyle|home|777|Houseplants|||室內植物;室内植物
lifestyle.gardening|lifestyle|home|778|Gardening|||園藝;园艺
lifestyle.aquariums|lifestyle|home|779|Aquariums|||水族
lifestyle.minimalism|lifestyle|home|780|Minimalism|||極簡生活;极简生活
lifestyle.organization|lifestyle|home|781|Home Organization|||收納;收纳
lifestyle.nightlife|lifestyle|social|790|Nightlife|||夜生活
lifestyle.bars|lifestyle|social|791|Bars|||酒吧
lifestyle.pub_quizzes|lifestyle|social|792|Pub Quizzes|||quiz night
lifestyle.escape_rooms|lifestyle|social|793|Escape Rooms|||密室逃脫;密室逃脱
lifestyle.theme_parks|lifestyle|social|794|Theme Parks|||主題樂園;主题乐园
lifestyle.museums|lifestyle|social|795|Museums|||博物館;博物馆
lifestyle.art_galleries|lifestyle|social|796|Art Galleries|||畫廊;画廊
lifestyle.festivals|lifestyle|social|797|Festivals|||節慶;节庆
lifestyle.volunteering|lifestyle|social|798|Volunteering|||義工;志愿服务
pets.dogs|pets|pets|805|Dogs|||狗
pets.cats|pets|pets|806|Cats|||貓;猫
pets.birds|pets|pets|807|Birds|||雀鳥;鸟
pets.fish|pets|pets|808|Fishkeeping|||養魚;养鱼
pets.reptiles|pets|pets|809|Reptiles|||爬蟲類;爬宠
pets.rabbits|pets|pets|810|Rabbits|||兔
pets.hamsters|pets|pets|811|Hamsters|||倉鼠;仓鼠
pets.pet_training|pets|pets|812|Pet Training|||寵物訓練;宠物训练
pets.animal_rescue|pets|pets|813|Animal Rescue|||動物救援;动物救助
business.startups|business|business|820|Startups|||初創;创业公司
business.marketing|business|business|821|Marketing|||市場推廣;市场营销
business.branding|business|business|822|Branding|||品牌
business.sales|business|business|823|Sales|||銷售;销售
business.ecommerce|business|business|824|E-commerce|||電商;电商
business.real_estate|business|business|825|Real Estate|||地產;房地产
business.finance|business|business|826|Finance|||金融
business.stock_market|business|business|827|Stock Market|||股票
business.crypto|business|business|828|Cryptocurrency|||加密貨幣;加密货币
business.product_management|business|business|829|Product Management|||產品管理;产品管理
business.design_thinking|business|business|830|Design Thinking|||設計思維;设计思维
business.networking|business|business|831|Professional Networking|||商務交流;商务社交
business.public_speaking|business|business|832|Public Speaking|||演講;演讲''');
