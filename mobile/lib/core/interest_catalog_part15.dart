import 'interest_catalog_parser.dart';
import 'models.dart';

/// Asia/local-life, campus, animal, professional-community, maker and outdoor
/// breadth. New concepts are identity-level affinities; obvious synonyms are
/// kept as aliases on older stable canonicals instead of creating duplicates.
final List<InterestDefinition> kInterestCatalogPart15 = parseInterestCatalogRows(r'''
food.yum_cha|food|food/dining|1720|Yum Cha|飲茶|饮茶|dim sum tea;yumcha;飲茶;饮茶
food.cha_chaan_teng|food|food/dining|1721|Cha Chaan Teng|茶餐廳|茶餐厅|hong kong cafe;茶記;茶餐厅
food.dai_pai_dong|food|food/dining|1722|Dai Pai Dong|大牌檔|大排档|open-air food stalls;大牌檔;大排档
food.tea_house_hopping|food|food/dining|1723|Tea House Hopping|茶館探店|茶馆探店|tea houses;tea house visits
food.night_markets|food|food/dining|1724|Night Markets|夜市|夜市|night market food;逛夜市
wellness.hot_springs|wellness|recovery|1725|Hot Springs|浸溫泉|泡温泉|hot spring bathing;onsen;溫泉;温泉
outdoors.river_tracing|outdoors|water|1726|River Tracing|溯溪|溯溪|stream trekking;river trekking
sports.dragon_boat_racing|sports|water|1727|Dragon Boat Racing|龍舟競渡|龙舟竞渡|dragon boating;dragon boat
arts.lion_dance|arts|performance|1728|Lion Dance|舞獅|舞狮|lion dancing;舞獅;舞狮
arts.chinese_dance|arts|dance|1729|Chinese Dance|中國舞|中国舞|traditional chinese dance
gaming.claw_machines|gaming|gaming_general|1730|Claw Machines|夾公仔機|抓娃娃机|crane games;claw machine;夾公仔;抓娃娃
collecting.capsule_toys|collecting|collecting|1731|Capsule Toys|扭蛋收藏|扭蛋收藏|gachapon;gashapon;capsule toy collecting
lifestyle.temple_fairs|lifestyle|local_culture|1732|Temple Fairs|廟會|庙会|temple fair;廟會;庙会
lifestyle.lantern_festivals|lifestyle|local_culture|1733|Lantern Festivals|燈會|灯会|lantern festival;燈會;灯会
lifestyle.flower_markets|lifestyle|local_culture|1734|Flower Markets|花市|花市|flower market;年宵花市
lifestyle.wet_markets|lifestyle|local_culture|1735|Wet Markets|街市|菜市场|wet market;傳統市場;传统市场
lifestyle.boat_parties|lifestyle|social|1736|Boat Parties|船上派對|船上派对|junk boat party;boat party
outdoors.squid_fishing|outdoors|water|1737|Squid Fishing|釣墨魚|钓鱿鱼|squid jigging;night squid fishing
outdoors.city_cycling|outdoors|cycling|1738|City Cycling|城市踩單車|城市骑行|urban cycling;city biking
transport.scooter_touring|transport|cars|1739|Scooter Touring|綿羊仔／電單車旅行|踏板摩托旅行|scooter trips;scooter road trips
learning.model_united_nations|learning|campus|1750|Model United Nations|模擬聯合國|模拟联合国|MUN;model UN
learning.student_newspaper|learning|campus|1751|Student Newspaper|學生報|学生报|campus newspaper;school newspaper
learning.campus_radio|learning|campus|1752|Campus Radio|校園電台|校园电台|student radio;college radio
learning.yearbook|learning|campus|1753|Yearbook|畢業年刊|毕业年刊|school yearbook;yearbook club
music.school_orchestra|music|music_making|1754|School Orchestra|校園管弦樂團|校园管弦乐团|student orchestra;school orchestra
music.school_band|music|music_making|1755|School Band|校園樂隊|校园乐队|student band;school music band
music.marching_band|music|music_making|1756|Marching Band|步操樂隊|行进乐队|marching bands
technology.hackathons|technology|software|1757|Hackathons|黑客松|黑客松|hackathon;hack day
business.case_competitions|business|business|1758|Case Competitions|商業個案比賽|商业案例比赛|business case competition;case challenge
business.startup_competitions|business|business|1759|Startup Competitions|創業比賽|创业比赛|startup competition;pitch competition
learning.math_olympiad|learning|campus|1760|Math Olympiad|數學奧林匹克|数学奥林匹克|math olympics;mathematics olympiad
learning.science_olympiad|learning|campus|1761|Science Olympiad|科學奧林匹克|科学奥林匹克|science olympics
learning.academic_competitions|learning|campus|1762|Academic Competitions|學術比賽|学术比赛|academic contest;school competition
learning.mock_trial|learning|campus|1763|Mock Trial|模擬法庭|模拟法庭|mock trials
learning.moot_court|learning|campus|1764|Moot Court|模擬法庭辯論|模拟法庭辩论|mooting;moot competition
learning.exchange_programs|learning|campus|1765|Exchange Programs|交換生計劃|交换生项目|student exchange;exchange student
learning.study_abroad|learning|campus|1766|Study Abroad|海外留學|海外留学|studying abroad;overseas study
learning.student_volunteering|learning|campus|1767|Student Volunteering|學生義工|学生志愿服务|campus volunteering;school volunteering
learning.student_societies|learning|campus|1768|Student Societies|學生社團|学生社团|student clubs;campus clubs
learning.campus_events|learning|campus|1769|Campus Events|校園活動|校园活动|college events;university events
business.alumni_networking|business|business|1770|Alumni Networking|校友交流|校友交流|alumni events;alumni network
lifestyle.bonsai|lifestyle|home|1780|Bonsai|盆景|盆景|bonsai gardening;盆栽
crafts.flower_arranging|crafts|crafts|1781|Flower Arranging|花藝|花艺|floral design;flower arrangement
crafts.ikebana|crafts|crafts|1782|Ikebana|日本花道|日本花道|Japanese flower arranging;生け花
sports.lawn_bowls|sports|precision|1783|Lawn Bowls|草地滾球|草地滚球|bowls;lawn bowling
arts.square_dancing|arts|dance|1784|Square Dancing|方塊舞|广场舞|square dance;廣場舞;广场舞
arts.chinese_painting|arts|visual_art|1785|Chinese Painting|中國畫|中国画|chinese ink painting;國畫;国画
pets.bird_keeping|pets|pets|1800|Bird Keeping|養鳥|养鸟|bird care;pet birds
pets.parrots|pets|pets|1801|Parrots|鸚鵡|鹦鹉|parrot keeping;pet parrots
pets.aquarium_keeping|pets|pets|1802|Aquarium Keeping|水族飼養|水族饲养|fishkeeping;aquarium hobby;tropical fish
pets.reptile_keeping|pets|pets|1803|Reptile Keeping|爬蟲飼養|爬虫饲养|pet reptiles;reptile care
pets.snakes|pets|pets|1804|Snakes|蛇類飼養|蛇类饲养|pet snakes;snake keeping
pets.lizards|pets|pets|1805|Lizards|蜥蜴飼養|蜥蜴饲养|pet lizards;lizard keeping
pets.guinea_pigs|pets|pets|1806|Guinea Pigs|天竺鼠|豚鼠|guinea pig care;cavies
pets.dog_agility|pets|pets|1807|Dog Agility|狗狗敏捷運動|犬敏捷运动|canine agility;agility dogs
pets.dog_grooming|pets|pets|1808|Dog Grooming|狗狗美容|狗狗美容|pet grooming;grooming dogs
lifestyle.cat_cafes|lifestyle|social|1809|Cat Cafes|貓 Cafe|猫咖|cat cafe;cat cafés
pets.wildlife_rescue|pets|pets|1810|Wildlife Rescue|野生動物救援|野生动物救助|wildlife rehabilitation;animal rescue wildlife
pets.horse_care|pets|pets|1811|Horse Care|馬匹照顧|马匹照顾|horse grooming;equine care
arts.bird_photography|arts|photography|1812|Bird Photography|鳥攝|鸟类摄影|bird photography;avian photography
arts.macro_wildlife_photography|arts|photography|1813|Macro Wildlife Photography|微距生態攝影|微距生态摄影|macro nature photography;insect photography
career.legal_profession|career|legal|1830|Legal Profession|法律專業|法律职业|law career;lawyers;legal careers
career.legal_tech|career|legal|1831|Legal Tech|法律科技|法律科技|legal technology;lawtech
career.healthcare|career|healthcare|1832|Healthcare Careers|醫療健康專業|医疗健康职业|healthcare profession;health careers
career.nursing|career|healthcare|1833|Nursing|護理專業|护理专业|nurse;nursing career
career.dentistry|career|healthcare|1834|Dentistry|牙科專業|牙科专业|dentist;dental career
career.pharmacy|career|healthcare|1835|Pharmacy|藥劑專業|药剂专业|pharmacist;pharmacy career
career.counselling|career|healthcare|1836|Counselling|輔導專業|辅导专业|counseling;professional counsellor
career.teaching|career|education|1837|Teaching|教學專業|教学职业|teacher;teaching career
career.engineering|career|engineering|1838|Engineering|工程專業|工程职业|engineer;engineering career
career.architecture|career|engineering|1839|Architecture Profession|建築專業|建筑职业|architect;architecture career
career.accounting|career|finance|1840|Accounting|會計|会计|accountant;accounting career
career.audit|career|finance|1841|Audit|審計|审计|auditing;auditor
career.banking|career|finance|1842|Banking|銀行業|银行业|banker;banking career
career.insurance|career|finance|1843|Insurance|保險業|保险业|insurance career;insurance professional
career.fintech|career|finance|1844|Fintech|金融科技|金融科技|financial technology;fintech career
career.digital_marketing|career|marketing|1845|Digital Marketing|數碼營銷|数字营销|online marketing;digital marketer
career.human_resources|career|people|1846|Human Resources|人力資源|人力资源|HR;human resources career
career.recruiting|career|people|1847|Recruiting|招聘|招聘|recruiter;talent acquisition
career.operations|career|operations|1848|Operations|營運管理|运营管理|operations management;ops
career.supply_chain|career|operations|1849|Supply Chain|供應鏈|供应链|supply chain management
career.logistics|career|operations|1850|Logistics|物流|物流|logistics management
career.procurement|career|operations|1851|Procurement|採購|采购|purchasing;sourcing
career.cloud_engineering|career|technology_careers|1852|Cloud Engineering|雲端工程|云计算工程|cloud engineer;cloud infrastructure
career.data_engineering|career|technology_careers|1853|Data Engineering|數據工程|数据工程|data engineer;data pipelines
career.biotechnology|career|science_careers|1854|Biotechnology|生物科技|生物技术|biotech;biotechnology career
career.climate_tech|career|science_careers|1855|Climate Tech|氣候科技|气候科技|climate technology;climatetech
career.sustainability|career|science_careers|1856|Sustainability|可持續發展|可持续发展|sustainability professional;ESG
career.research|career|research|1857|Research|研究工作|研究工作|researcher;research career
career.academia|career|research|1858|Academia|學術界|学术界|academic career;university research
crafts.metalworking|crafts|crafts|1880|Metalworking|金工|金工|metal craft;metal work
crafts.silversmithing|crafts|crafts|1881|Silversmithing|銀器製作|银器制作|silver work;silver jewellery making
crafts.pottery_wheel|crafts|crafts|1882|Pottery Wheel|拉坯|拉坯|wheel throwing;pottery throwing
crafts.handbuilding_pottery|crafts|crafts|1883|Handbuilding Pottery|手捏陶|手捏陶|hand-built pottery;handbuilding ceramics
crafts.ceramic_glazing|crafts|crafts|1884|Ceramic Glazing|陶瓷上釉|陶瓷施釉|glazing pottery;ceramic glaze
crafts.glassblowing|crafts|crafts|1885|Glassblowing|吹玻璃|吹玻璃|glass blowing
crafts.stained_glass|crafts|crafts|1886|Stained Glass|彩繪玻璃|彩色玻璃|stained-glass craft
crafts.mosaics|crafts|crafts|1887|Mosaics|馬賽克藝術|马赛克艺术|mosaic art;mosaic making
crafts.dollhouse_miniatures|crafts|crafts|1888|Dollhouse Miniatures|娃娃屋微縮|娃娃屋微缩|dollhouse making;miniature houses
technology.rc_cars|technology|gadgets|1889|RC Cars|遙控車|遥控车|radio controlled cars;remote control cars
technology.rc_planes|technology|gadgets|1890|RC Planes|遙控飛機|遥控飞机|radio controlled planes;remote control aircraft
technology.rc_boats|technology|gadgets|1891|RC Boats|遙控船|遥控船|radio controlled boats;remote control boats
technology.drone_building|technology|hardware|1892|Drone Building|無人機製作|无人机制作|building drones;DIY drones
technology.keyboard_building|technology|hardware|1893|Keyboard Building|機械鍵盤組裝|机械键盘组装|custom keyboards;keyboard modding
crafts.watch_repair|crafts|crafts|1894|Watch Repair|手錶維修|手表维修|watchmaking;watch servicing
crafts.clock_repair|crafts|crafts|1895|Clock Repair|鐘錶維修|钟表维修|clockmaking;clock restoration
crafts.bicycle_repair|crafts|crafts|1896|Bicycle Repair|單車維修|自行车维修|bike repair;bicycle maintenance
crafts.bike_building|crafts|crafts|1897|Bike Building|單車組裝|自行车组装|building bikes;custom bicycles
crafts.blacksmithing|crafts|crafts|1898|Blacksmithing|鍛造工藝|锻造工艺|forge work;smithing
crafts.book_arts|crafts|crafts|1899|Book Arts|書籍藝術|书籍艺术|artist books;book craft
outdoors.coasteering|outdoors|water|1910|Coasteering|海岸攀游|海岸穿越|coastal scrambling;coasteer
outdoors.sport_climbing|outdoors|hiking|1911|Sport Climbing|運動攀登|运动攀岩|sport climbing outdoors
outdoors.trad_climbing|outdoors|hiking|1912|Trad Climbing|傳統攀登|传统攀岩|traditional climbing;trad climbing
outdoors.peak_bagging|outdoors|hiking|1913|Peak Bagging|登峰集郵|登峰打卡|summit collecting;peak collecting
outdoors.sunrise_hiking|outdoors|hiking|1914|Sunrise Hiking|日出行山|日出徒步|sunrise hike
outdoors.night_hiking|outdoors|hiking|1915|Night Hiking|夜行山|夜间徒步|night hike
outdoors.urban_hiking|outdoors|hiking|1916|Urban Hiking|城市遠足|城市徒步|city hiking;urban walks
outdoors.kayak_touring|outdoors|water|1917|Kayak Touring|獨木舟旅行|皮划艇旅行|sea kayak touring;kayaking trips
''');
