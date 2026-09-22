import 'interest_catalog_parser.dart';
import 'models.dart';

/// Everyday breadth expansion for food, maker tech, collecting, knowledge,
/// work communities, pets and media creation. These are generic concepts meant
/// to improve identity, icebreaking and future community/marketplace matching.
final List<InterestDefinition> kInterestCatalogPart13 = parseInterestCatalogRows(r'''
food.bread_baking|food|cooking|1230|Bread Baking|麵包烘焙|面包烘焙|bread making
food.sourdough_baking|food|cooking|1231|Sourdough Baking|酸種麵包烘焙|酸种面包烘焙|sourdough;sourdough bread
food.pastry_making|food|cooking|1232|Pastry Making|西點製作|西点制作|pastry baking;pastries
food.cake_decorating|food|cooking|1233|Cake Decorating|蛋糕裝飾|蛋糕装饰|cake decoration
food.cookie_decorating|food|cooking|1234|Cookie Decorating|曲奇裝飾|饼干装饰|biscuit decorating
food.chocolate_making|food|cooking|1235|Chocolate Making|朱古力製作|巧克力制作|chocolate crafting
food.cheese_making|food|cooking|1236|Cheese Making|芝士製作|奶酪制作|cheesemaking
food.fermentation|food|cooking|1237|Fermentation|發酵食品|发酵食品|fermented foods;fermenting
food.pickling|food|cooking|1238|Pickling|醃製食品|腌制食品|pickles;food pickling
food.canning|food|cooking|1239|Canning|食品罐藏|食品罐藏|home canning
food.food_preserving|food|cooking|1240|Food Preserving|食品保存|食品保存|food preservation;preserving food
food.tea_tasting|food|coffee|1241|Tea Tasting|品茶|品茶|tea appreciation;tea tasting
food.coffee_tasting|food|coffee|1242|Coffee Tasting|咖啡品鑑|咖啡品鉴|coffee cupping;coffee appreciation
food.restaurant_hopping|food|food/dining|1243|Restaurant Hopping|餐廳探店|餐厅探店|restaurant crawl;trying restaurants
food.dessert_hunting|food|food/dining|1244|Dessert Hunting|甜品探店|甜品探店|dessert hopping;dessert crawl
food.food_markets|food|food/dining|1245|Food Markets|美食市集|美食市集|food market;food halls
food.home_brewing|food|food/drinks|1246|Home Brewing|家庭釀造|家庭酿造|homebrew;brewing
food.healthy_cooking|food|cooking|1248|Healthy Cooking|健康烹飪|健康烹饪|healthy recipes
food.meal_planning|food|cooking|1249|Meal Planning|膳食規劃|膳食规划|menu planning;weekly meals
technology.electronics|technology|hardware|1260|Electronics|電子製作|电子制作|electronics projects
technology.soldering|technology|hardware|1261|Soldering|焊接電子製作|焊接电子制作|electronics soldering
technology.microcontrollers|technology|hardware|1262|Microcontrollers|微控制器|微控制器|microcontroller projects
technology.home_automation|technology|gadgets|1263|Home Automation|家居自動化|家居自动化|automated home
technology.internet_of_things|technology|hardware|1264|Internet of Things|物聯網|物联网|iot
technology.homelab|technology|hardware|1265|Homelab|家庭 IT 實驗室|家庭 IT 实验室|home lab;homelabbing
technology.self_hosting|technology|software|1266|Self Hosting|自架服務|自托管|self-hosting;self hosted
technology.devops|technology|software|1267|DevOps|DevOps|DevOps|dev ops
technology.data_visualization|technology|software|1268|Data Visualization|數據視覺化|数据可视化|data viz
technology.databases|technology|software|1269|Databases|數據庫|数据库|database systems
technology.sql|technology|software|1270|SQL|SQL|SQL|structured query language
technology.ux_design|technology|software|1271|UX Design|使用者體驗設計|用户体验设计|user experience design
technology.ui_design|technology|software|1272|UI Design|介面設計|界面设计|user interface design
technology.3d_modeling|technology|software|1273|3D Modeling|3D 建模|3D 建模|3d modelling;three dimensional modeling
technology.laser_cutting|technology|hardware|1274|Laser Cutting|激光切割|激光切割|laser cutter
technology.cnc_machining|technology|hardware|1275|CNC Machining|CNC 加工|CNC 加工|cnc;computer numerical control
technology.fpv_drones|technology|gadgets|1276|FPV Drones|FPV 穿越機|FPV 穿越机|fpv drone;drone racing
technology.amateur_radio|technology|hardware|1277|Amateur Radio|業餘無線電|业余无线电|ham radio
technology.software_defined_radio|technology|hardware|1278|Software Defined Radio|軟件定義無線電|软件定义无线电|sdr;software-defined radio
technology.retro_computing|technology|hardware|1279|Retro Computing|復古電腦|复古电脑|vintage computing;retro computers
collecting.cd_collecting|collecting|collecting|1290|CD Collecting|CD 收藏|CD 收藏|compact disc collecting;cds
collecting.comic_collecting|collecting|collecting|1291|Comic Collecting|漫畫收藏|漫画收藏|comic books collecting
collecting.manga_collecting|collecting|collecting|1292|Manga Collecting|日本漫畫收藏|日本漫画收藏|manga collection
collecting.camera_collecting|collecting|collecting|1293|Camera Collecting|相機收藏|相机收藏|vintage camera collecting
collecting.rocks_minerals|collecting|collecting|1294|Rocks & Minerals Collecting|岩石與礦物收藏|岩石与矿物收藏|mineral collecting;rock collecting
collecting.fossil_collecting|collecting|collecting|1295|Fossil Collecting|化石收藏|化石收藏|fossils
collecting.pin_collecting|collecting|collecting|1296|Pin Collecting|徽章收藏|徽章收藏|pins;badge collecting
collecting.patch_collecting|collecting|collecting|1297|Patch Collecting|布章收藏|布章收藏|patches;embroidered patches
collecting.keychain_collecting|collecting|collecting|1298|Keychain Collecting|鎖匙扣收藏|钥匙扣收藏|keyrings;keychains
collecting.autographs|collecting|collecting|1299|Autograph Collecting|簽名收藏|签名收藏|autographs;signed memorabilia
collecting.sports_memorabilia|collecting|collecting|1300|Sports Memorabilia|體育紀念品收藏|体育纪念品收藏|sports collectibles
collecting.movie_memorabilia|collecting|collecting|1301|Movie Memorabilia|電影紀念品收藏|电影纪念品收藏|film memorabilia;movie collectibles
collecting.plush_toys|collecting|collecting|1302|Plush Toy Collecting|毛公仔收藏|毛绒玩具收藏|plushies;stuffed toys collecting
collecting.dolls|collecting|collecting|1303|Doll Collecting|玩偶收藏|玩偶收藏|dolls
collecting.ceramics|collecting|collecting|1304|Ceramics Collecting|陶瓷收藏|陶瓷收藏|pottery collecting
collecting.teaware|collecting|collecting|1305|Teaware Collecting|茶具收藏|茶具收藏|tea ware;teapot collecting
collecting.retro_games|collecting|collecting|1306|Retro Game Collecting|復古遊戲收藏|复古游戏收藏|vintage games collecting;retro games
sports.crosswords|sports|mind_sports|1320|Crosswords|填字遊戲|填字游戏|crossword puzzles;crossword
sports.sudoku|sports|mind_sports|1321|Sudoku|數獨|数独|number puzzles
sports.speedcubing|sports|mind_sports|1322|Speedcubing|速解魔方|速拧魔方|rubik's cube speedsolving;speed cube
learning.genealogy|learning|knowledge|1323|Genealogy|家族史研究|家谱研究|family history;genealogy research
learning.local_history|learning|history|1324|Local History|本地歷史|地方历史|community history
learning.linguistics|learning|knowledge|1325|Linguistics|語言學|语言学|language science
learning.anthropology|learning|knowledge|1326|Anthropology|人類學|人类学|cultural anthropology
learning.sociology|learning|knowledge|1327|Sociology|社會學|社会学|social science
science.botany|science|science|1328|Botany|植物學|植物学|plant science
science.entomology|science|science|1329|Entomology|昆蟲學|昆虫学|insect science
science.marine_biology|science|science|1330|Marine Biology|海洋生物學|海洋生物学|marine science
science.paleontology|science|science|1331|Paleontology|古生物學|古生物学|palaeontology;fossil science
science.meteorology|science|science|1332|Meteorology|氣象學|气象学|weather science
science.ecology|science|science|1333|Ecology|生態學|生态学|ecosystems
science.conservation|science|science|1334|Conservation|自然保育|自然保护|nature conservation;conservation science
science.citizen_science|science|science|1335|Citizen Science|公民科學|公民科学|community science
arts.gratitude_journaling|arts|writing|1336|Gratitude Journaling|感恩日記|感恩日记|gratitude journal
business.freelancing|business|business|1350|Freelancing|自由工作|自由职业|freelance;freelancer
business.remote_work|business|business|1351|Remote Work|遙距工作|远程工作|working remotely;work from home
business.side_hustles|business|business|1352|Side Hustles|副業|副业|side hustle;second income
business.creator_economy|business|business|1353|Creator Economy|創作者經濟|创作者经济|creator business
business.personal_branding|business|business|1354|Personal Branding|個人品牌|个人品牌|personal brand
business.career_development|business|business|1355|Career Development|職涯發展|职业发展|career growth
business.career_switching|business|business|1356|Career Switching|轉行|转行|career change;changing careers
business.consulting|business|business|1357|Consulting|顧問工作|咨询顾问|consultant;consultancy
business.project_management|business|business|1358|Project Management|項目管理|项目管理|project manager
business.no_code|business|business|1359|No-Code|無代碼|无代码|no code;nocode
business.small_business|business|business|1360|Small Business|小型生意|小型企业|small business owner
business.family_business|business|business|1361|Family Business|家族生意|家族企业|family enterprise
pets.dog_walking|pets|pets|1370|Dog Walking|遛狗|遛狗|walking dogs
pets.cat_care|pets|pets|1371|Cat Care|貓咪照顧|猫咪照顾|caring for cats
pets.pet_photography|pets|pets|1372|Pet Photography|寵物攝影|宠物摄影|animal photography;pets photos
pets.pet_fostering|pets|pets|1373|Pet Fostering|動物暫養|动物暂养|fostering pets;foster animals
pets.aquascaping|pets|pets|1374|Aquascaping|水草造景|水草造景|planted aquariums;aquarium landscaping
pets.terrariums|pets|pets|1375|Terrariums|生態缸|生态缸|terrarium;vivarium;terrarium making
arts.podcasting|arts|media_creation|1390|Podcasting|Podcast 製作|播客制作|podcast production;making podcasts
arts.video_editing|arts|media_creation|1391|Video Editing|影片剪輯|视频剪辑|video editor;film editing
arts.vlogging|arts|media_creation|1392|Vlogging|Vlog 製作|Vlog 制作|video blogging;vlogger
arts.content_creation|arts|media_creation|1393|Content Creation|內容創作|内容创作|content creator;creating content
arts.livestreaming|arts|media_creation|1394|Livestreaming|直播創作|直播创作|live streaming;streaming creator
arts.blogging|arts|writing|1395|Blogging|寫 Blog／網誌|博客写作|blog writing;blogger
arts.newsletter_writing|arts|writing|1396|Newsletter Writing|電子報寫作|电子通讯写作|newsletter creation;email newsletter
music.composing|music|music_making|1397|Composing|作曲|作曲|music composition;composer
music.choir|music|music_making|1398|Choir|合唱團|合唱|choral singing;chorus;community choir
music.a_cappella|music|music_making|1399|A Cappella|無伴奏合唱|无伴奏合唱|acapella;a cappella singing
music.beat_making|music|music_making|1400|Beat Making|Beat 製作|节拍制作|beatmaking;making beats
''');
