import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart10 = List.unmodifiable([
  ...parseInterestFamily(
    idPrefix: 'learning.book_genre',
    category: 'learning',
    cluster: 'books/subgenres',
    rankStart: 4400,
    raw: r'''
Literary Fiction|文學小說|文学小说
Contemporary Fiction|當代小說|当代小说
Historical Fiction|歷史小說|历史小说
Family Saga|家族史詩小說|家族史诗小说
Coming-of-Age Fiction|成長小說|成长小说
Short Stories|短篇小說|短篇小说
Novellas|中篇小說|中篇小说
Classics|經典文學|经典文学
Modern Classics|現代經典文學|现代经典文学
Experimental Fiction|實驗小說|实验小说
Magical Realism|魔幻現實主義小說|魔幻现实主义小说
Satirical Fiction|諷刺小說|讽刺小说
Humorous Fiction|幽默小說|幽默小说
Women's Fiction|女性題材小說|女性题材小说
Domestic Fiction|家庭題材小說|家庭题材小说
Campus Novels|校園小說|校园小说
Epistolary Novels|書信體小說|书信体小说
Adventure Fiction|冒險小說|冒险小说
Sea Fiction|海洋小說|海洋小说
Western Fiction|西部小說|西部小说
War Fiction|戰爭小說|战争小说
Political Fiction|政治小說|政治小说
Legal Fiction|法律小說|法律小说
Medical Fiction|醫療小說|医疗小说
Business Fiction|商業小說|商业小说
Crime Fiction|犯罪小說|犯罪小说
Detective Fiction|偵探小說|侦探小说
Police Procedural Books|警察程序小說|警察程序小说
Cozy Mystery Books|輕鬆推理小說|轻松推理小说
Locked-Room Mystery|密室推理|密室推理
Hard-Boiled Mystery|硬漢派推理|硬汉派推理
Noir Fiction|黑色小說|黑色小说
Spy Fiction|間諜小說|间谍小说
Espionage Thrillers|諜報驚悚小說|谍报惊悚小说
Psychological Thrillers|心理驚悚小說|心理惊悚小说
Domestic Thrillers|家庭驚悚小說|家庭惊悚小说
Legal Thrillers|法律驚悚小說|法律惊悚小说
Techno Thrillers|科技驚悚小說|科技惊悚小说
Historical Mysteries|歷史推理小說|历史推理小说
True Crime Books|真實犯罪書籍|真实犯罪书籍
Horror Fiction|恐怖小說|恐怖小说
Gothic Horror|哥德式恐怖小說|哥特式恐怖小说
Cosmic Horror|宇宙恐怖小說|宇宙恐怖小说
Folk Horror Books|民俗恐怖小說|民俗恐怖小说
Body Horror Books|身體恐怖小說|身体恐怖小说
Ghost Stories|鬼故事|鬼故事
Vampire Fiction|吸血鬼小說|吸血鬼小说
Zombie Fiction|喪屍小說|丧尸小说
Occult Fiction|神秘學小說|神秘学小说
Dark Fantasy Books|黑暗奇幻小說|黑暗奇幻小说
Epic Fantasy|史詩奇幻|史诗奇幻
High Fantasy|高幻想小說|高幻想小说
Low Fantasy|低幻想小說|低幻想小说
Urban Fantasy Books|都市奇幻小說|都市奇幻小说
Romantic Fantasy Books|愛情奇幻小說|爱情奇幻小说
Sword and Sorcery Books|劍與魔法小說|剑与魔法小说
Mythic Fantasy|神話奇幻|神话奇幻
Fairy-Tale Retellings|童話改寫|童话改写
Progression Fantasy|成長型奇幻|成长型奇幻
LitRPG|遊戲化角色扮演小說|游戏化角色扮演小说
Science Fiction Books|科幻小說|科幻小说
Hard Science Fiction|硬科幻|硬科幻
Space Opera Books|太空歌劇小說|太空歌剧小说
Cyberpunk Books|賽博朋克小說|赛博朋克小说
Dystopian Fiction|反烏托邦小說|反乌托邦小说
Post-Apocalyptic Fiction|末日後小說|末日后小说
Time Travel Fiction|時間旅行小說|时间旅行小说
Alternate History Books|架空歷史小說|架空历史小说
First Contact Fiction|初次接觸科幻小說|首次接触科幻小说
Military Science Fiction|軍事科幻小說|军事科幻小说
Climate Fiction|氣候小說|cli-fi|气候小说
Solarpunk|太陽朋克|太阳朋克
Contemporary Romance|當代愛情小說|当代爱情小说
Historical Romance Books|歷史愛情小說|历史爱情小说
Romantic Comedy Books|愛情喜劇小說|爱情喜剧小说
Dark Romance Books|黑暗愛情小說|黑暗爱情小说
Sports Romance|體育愛情小說|体育爱情小说
Fantasy Romance|奇幻愛情小說|romantasy|奇幻爱情小说
Queer Romance|酷兒愛情小說|酷儿爱情小说
Young Adult Fiction|青少年小說|青少年小说
YA Fantasy|青少年奇幻|青少年奇幻
YA Romance|青少年愛情|青少年爱情
Middle Grade Fiction|中年級兒童小說|中年级儿童小说
Children's Classics|兒童經典文學|儿童经典文学
Picture Books|圖畫書|绘本
Graphic Novels|圖像小說|图像小说
Superhero Comics|超級英雄漫畫|超级英雄漫画
Independent Comics|獨立漫畫|独立漫画
European Comics|歐洲漫畫|欧洲漫画
Manga Reading|漫畫閱讀|漫画阅读
Manhwa Reading|韓漫閱讀|韩漫阅读
Webtoon Reading|網漫閱讀|网漫阅读
Memoirs|回憶錄|回忆录
Autobiography|自傳|自传
History Books|歷史書籍|历史书籍
Popular Science Books|科普書籍|科普书籍
Science Writing|科學寫作|科学写作
Nature Writing|自然寫作|自然写作
Travel Writing|旅行寫作|旅行写作
Food Writing|飲食寫作|饮食写作
Music Books|音樂書籍|音乐书籍
Film Books|電影書籍|电影书籍
Art Books|藝術書籍|艺术书籍
Architecture Books|建築書籍|建筑书籍
Philosophy Books|哲學書籍|哲学书籍
Psychology Books|心理學書籍|心理学书籍
Economics Books|經濟學書籍|经济学书籍
Business Books|商業書籍|商业书籍
Management Books|管理書籍|管理书籍
Marketing Books|市場推廣書籍|市场营销书籍
Startup Books|初創企業書籍|创业书籍
Personal Finance Books|個人理財書籍|个人理财书籍
Investing Books|投資書籍|投资书籍
Productivity Books|生產力書籍|效率提升书籍
Leadership Books|領導力書籍|领导力书籍
Technology Books|科技書籍|科技书籍
Programming Books|編程書籍|编程书籍
Design Books|設計書籍|设计书籍
Poetry Collections|詩集|诗集
Essays|散文|散文
Literary Criticism|文學評論|文学评论
Book Collecting|書籍收藏|书籍收藏
Rare Books|珍本書收藏|珍本书收藏
Audiobooks|有聲書|有声书
E-books|電子書|电子书
Book Blogging|書籍部落格創作|图书博客
BookTok|BookTok|BookTok
BookTube|BookTube|BookTube
Bookstagram|Bookstagram|Bookstagram
Library Visits|逛圖書館|逛图书馆
Independent Bookstores|獨立書店|独立书店
Second-Hand Bookstores|二手書店|二手书店
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'learning.book_title',
    category: 'learning',
    cluster: 'books/evergreen_titles',
    rankStart: 4600,
    raw: r'''
Pride and Prejudice
Jane Eyre
Wuthering Heights
Great Expectations
A Tale of Two Cities
Oliver Twist
David Copperfield
Middlemarch
The Picture of Dorian Gray
Dracula
Frankenstein
The Count of Monte Cristo
Les Misérables
The Three Musketeers
Madame Bovary
Anna Karenina
War and Peace
Crime and Punishment
The Brothers Karamazov
Notes from Underground
Don Quixote
The Divine Comedy
The Odyssey
The Iliad
The Great Gatsby
To Kill a Mockingbird
Of Mice and Men
East of Eden
The Grapes of Wrath
The Catcher in the Rye
1984
Animal Farm
Brave New World
Fahrenheit 451
The Handmaid's Tale
Beloved
Invisible Man
Their Eyes Were Watching God
One Hundred Years of Solitude
Love in the Time of Cholera
The Master and Margarita
The Stranger
The Plague
Siddhartha
The Trial
Metamorphosis
The Unbearable Lightness of Being
The Little Prince
The Alchemist
Norwegian Wood|挪威的森林|ノルウェイの森|挪威的森林
Kafka on the Shore|海邊的卡夫卡|海辺のカフカ|海边的卡夫卡
1Q84
The Wind-Up Bird Chronicle
Convenience Store Woman|便利店人間|コンビニ人間|便利店人间
Before the Coffee Gets Cold|在咖啡冷掉之前|コーヒーが冷めないうちに|在咖啡冷掉之前
No Longer Human|人間失格|人間失格|人间失格
Kokoro|心|こころ|心
The Tale of Genji|源氏物語|源氏物語|源氏物语
Dream of the Red Chamber|紅樓夢|红楼梦
Romance of the Three Kingdoms|三國演義|三国演义
Journey to the West|西遊記|西游记
Water Margin|水滸傳|水浒传
The Art of War|孫子兵法|孙子兵法
The Three-Body Problem|三體|三体
The Dark Forest|黑暗森林
Death's End|死神永生
The Wandering Earth|流浪地球
Fortress Besieged|圍城|围城
To Live|活著|活着
Red Sorghum|紅高粱家族|红高粱家族
The Lord of the Rings Books|lotr books
The Hobbit
The Silmarillion
Harry Potter Books
A Song of Ice and Fire
The Wheel of Time
The Stormlight Archive
Mistborn
The Kingkiller Chronicle
The First Law
The Chronicles of Narnia
His Dark Materials
Discworld
Earthsea
The Broken Earth Trilogy
The Poppy War
Babel by R.F. Kuang
Fourth Wing
A Court of Thorns and Roses|acotar
Throne of Glass
The Hunger Games
Divergent
Percy Jackson
Twilight Saga
The Maze Runner
The Mortal Instruments
The Selection
Dune Novels
Foundation Series
Hyperion Cantos
The Expanse Books
Ender's Game
Neuromancer
Snow Crash
Do Androids Dream of Electric Sheep?
The Left Hand of Darkness
The Dispossessed
Project Hail Mary
The Martian Novel
Ready Player One
The Hitchhiker's Guide to the Galaxy
Good Omens
American Gods
The Sandman Comics
Watchmen Comics
V for Vendetta Comic
Maus
Persepolis
Saga Comics
Scott Pilgrim
Heartstopper Graphic Novels
Sherlock Holmes
Hercule Poirot
Miss Marple
The Thursday Murder Club
The Girl with the Dragon Tattoo
Gone Girl
The Silent Patient
The Da Vinci Code
The Name of the Rose
The Shining Novel
It by Stephen King
Misery
Pet Sematary
The Haunting of Hill House
House of Leaves
Sapiens
Homo Deus
A Brief History of Time
Cosmos by Carl Sagan
The Selfish Gene
Thinking, Fast and Slow
Man's Search for Meaning
Atomic Habits
Deep Work
The 7 Habits of Highly Effective People
How to Win Friends and Influence People
The Psychology of Money
Rich Dad Poor Dad
The Intelligent Investor
Zero to One
The Lean Startup
Good to Great
Start with Why
The Design of Everyday Things
Steve Jobs Biography
Shoe Dog
Educated
Becoming
When Breath Becomes Air
Crying in H Mart
Born a Crime
Kitchen Confidential
Into the Wild
Wild by Cheryl Strayed
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'food.cuisine_deep',
    category: 'food',
    cluster: 'food/cuisines',
    rankStart: 4850,
    raw: r'''
Teochew Cuisine|潮州菜|潮州菜|潮州菜
Hakka Cuisine|客家菜|客家菜|客家菜
Shanghainese Cuisine|上海菜|上海菜|上海菜
Beijing Cuisine|京菜|京菜|京菜
Shandong Cuisine|魯菜|鲁菜
Hunan Cuisine|湘菜|湘菜|湘菜
Fujian Cuisine|閩菜|闽菜
Jiangsu Cuisine|蘇菜|苏菜
Zhejiang Cuisine|浙菜|浙菜|浙菜
Yunnan Cuisine|雲南菜|云南菜
Xinjiang Cuisine|新疆菜|新疆菜|新疆菜
Chaoshan Cuisine|潮汕菜|潮汕菜|潮汕菜
Macanese Cuisine|澳門菜|澳门菜
Okinawan Cuisine|沖繩料理|沖縄料理|冲绳料理
Kaiseki|懷石料理|懐石料理|怀石料理
Izakaya Food|居酒屋料理|居酒屋料理|居酒屋料理
Yakitori|燒鳥|焼き鳥|烧鸟
Yakiniku|日式燒肉|焼肉|日式烧肉
Korean BBQ|韓式燒肉|韩式烤肉
Korean Fried Chicken|韓式炸雞|韩式炸鸡
Temple Food|寺院料理|寺院料理
Burmese Cuisine|緬甸菜|缅甸菜
Filipino Cuisine|菲律賓菜|菲律宾菜
Indonesian Cuisine|印尼菜|印尼菜
Balinese Cuisine|峇里島料理|巴厘岛料理
Cambodian Cuisine|柬埔寨菜|柬埔寨菜
Laotian Cuisine|老撾菜|老挝菜
Nepalese Cuisine|尼泊爾菜|尼泊尔菜
Sri Lankan Cuisine|斯里蘭卡菜|斯里兰卡菜
Bangladeshi Cuisine|孟加拉菜|孟加拉菜
Pakistani Cuisine|巴基斯坦菜|巴基斯坦菜
Persian Cuisine|波斯菜|波斯菜
Lebanese Cuisine|黎巴嫩菜|黎巴嫩菜
Turkish Cuisine|土耳其菜|土耳其菜
Greek Cuisine|希臘菜|希腊菜
Israeli Cuisine|以色列菜|以色列菜
Moroccan Cuisine|摩洛哥菜|摩洛哥菜
Ethiopian Cuisine|埃塞俄比亞菜|埃塞俄比亚菜
Egyptian Cuisine|埃及菜|埃及菜
South African Cuisine|南非菜|南非菜
West African Cuisine|西非菜|西非菜
Nigerian Cuisine|尼日利亞菜|尼日利亚菜
Brazilian Cuisine|巴西菜|巴西菜
Argentinian Cuisine|阿根廷菜|阿根廷菜
Peruvian Cuisine|秘魯菜|秘鲁菜
Colombian Cuisine|哥倫比亞菜|哥伦比亚菜
Cuban Cuisine|古巴菜|古巴菜
Caribbean Cuisine|加勒比菜|加勒比菜
Tex-Mex|德州墨西哥菜|德州墨西哥菜
Cajun Cuisine|卡真菜|卡真菜
Creole Cuisine|克里奧爾菜|克里奥尔菜
Southern US Food|美國南方菜|美国南方菜
New York Food|紐約美食|纽约美食
Californian Cuisine|加州料理|加州料理
Nordic Cuisine|北歐料理|北欧料理
British Food|英國菜|英国菜
Irish Food|愛爾蘭菜|爱尔兰菜
German Food|德國菜|德国菜
Austrian Food|奧地利菜|奥地利菜
Swiss Food|瑞士菜|瑞士菜
Portuguese Food|葡萄牙菜|葡萄牙菜
Basque Cuisine|巴斯克料理|巴斯克料理
Catalan Cuisine|加泰隆尼亞料理|加泰罗尼亚料理
Eastern European Food|東歐菜|东欧菜
Polish Food|波蘭菜|波兰菜
Hungarian Food|匈牙利菜|匈牙利菜
Georgian Cuisine|格魯吉亞菜|格鲁吉亚菜
Russian Food|俄羅斯菜|俄罗斯菜
Ukrainian Food|烏克蘭菜|乌克兰菜
Balkan Cuisine|巴爾幹菜|巴尔干菜
Fusion Cuisine|融合料理|融合料理
Farm-to-Table|農場直送餐飲|农场直供餐饮
Plant-Based Cooking|植物性飲食料理|植物性饮食料理
Raw Food|生食飲食|生食饮食
Gluten-Free Food|無麩質飲食|无麸质饮食
Halal Food|清真食品|清真食品
Kosher Food|猶太潔食|犹太洁食
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'food.dish',
    category: 'food',
    cluster: 'food/dishes',
    rankStart: 5000,
    raw: r'''
Cantonese Roast Meat|燒味|烧味
Char Siu|叉燒|叉烧
Roast Goose|燒鵝|烧鹅
Claypot Rice|煲仔飯|煲仔饭
Congee|粥|粥|粥
Wonton Noodles|雲吞麵|云吞面
Beef Brisket Noodles|牛腩麵|牛腩面
Hong Kong Milk Tea|港式奶茶|港式奶茶|港式奶茶
Pineapple Bun|菠蘿包|菠萝包
Egg Tart|蛋撻|蛋挞
French Toast Hong Kong Style|西多士|西多士|西多士
Rice Noodle Rolls|腸粉|肠粉
Sheng Jian Bao|生煎包|生煎包|生煎包
Peking Duck|北京烤鴨|北京烤鸭
Mapo Tofu|麻婆豆腐|麻婆豆腐|麻婆豆腐
Kung Pao Chicken|宮保雞丁|宫保鸡丁
Dan Dan Noodles|擔擔麵|担担面
Sichuan Boiled Fish|水煮魚|水煮鱼
Mala Xiang Guo|麻辣香鍋|麻辣香锅
Xiaolongbao|小籠包|Soup Dumplings|小笼包
Scallion Pancakes|蔥油餅|葱油饼
Taiwanese Beef Noodles|台灣牛肉麵|台湾牛肉面
Lu Rou Fan|滷肉飯|卤肉饭
Gua Bao|刈包|刈包|刈包
Oyster Omelette|蚵仔煎|蚵仔煎|蚵仔煎
Stinky Tofu|臭豆腐|臭豆腐|臭豆腐
Japanese Curry|日式咖喱|日式咖喱|日式咖喱
Tonkatsu|吉列豬扒|とんかつ|炸猪排
Tempura|天婦羅|天ぷら|天妇罗
Udon|烏冬|うどん|乌冬
Soba|蕎麥麵|そば|荞麦面
Okonomiyaki|大阪燒|お好み焼き|大阪烧
Takoyaki|章魚燒|たこ焼き|章鱼烧
Onigiri|飯糰|おにぎり|饭团
Donburi|丼飯|丼饭
Oyakodon|親子丼|親子丼|亲子丼
Gyudon|牛丼|牛丼
Omurice|蛋包飯|オムライス|蛋包饭
Japanese Cheesecake|日式芝士蛋糕|日式芝士蛋糕|日式芝士蛋糕
Mochi|麻糬|餅|麻薯
Bibimbap|韓式拌飯|비빔밥|韩式拌饭
Tteokbokki|辣炒年糕|辣炒年糕
Kimchi|泡菜|泡菜
Kimbap|紫菜包飯|김밥|紫菜包饭
Samgyeopsal|韓式五花肉|삼겹살|韩式五花肉
Bulgogi|韓式燒牛肉|韩式烤牛肉
Sundubu Jjigae|嫩豆腐鍋|순두부찌개|嫩豆腐锅
Japchae|韓式炒粉絲|잡채|韩式炒粉丝
Naengmyeon|冷麵|냉면|冷面
Pho|越南河粉|越南河粉|越南河粉
Banh Mi|越南法包|越南法包|越南法棍
Bun Cha|越南烤肉米線|越南烤肉米线
Pad Thai|泰式炒河|泰式炒河|泰式炒河
Tom Yum|冬蔭功|冬阴功
Green Curry|泰式青咖喱|泰式青咖喱|泰式青咖喱
Mango Sticky Rice|芒果糯米飯|芒果糯米饭
Hainanese Chicken Rice|海南雞飯|海南鸡饭
Laksa|叻沙|叻沙|叻沙
Bak Kut Teh|肉骨茶|肉骨茶|肉骨茶
Nasi Lemak|椰漿飯|椰浆饭
Roti Canai|印度煎餅|印度煎饼
Satay|沙嗲|沙嗲|沙爹
Biryani|印度香飯|印度香饭
Butter Chicken|印度牛油雞|印度黄油鸡
Tandoori Chicken|天都里烤雞|坦都里烤鸡
Masala Dosa|馬薩拉多薩|玛萨拉多萨
Samosa|印度咖喱角|印度咖喱角
Naan|印度烤餅|印度烤饼
Curry Laksa|咖喱叻沙|咖喱叻沙
Pasta|意大利粉|意大利面
Carbonara|卡邦尼意粉|卡邦尼意面
Cacio e Pepe|芝士黑椒意粉|奶酪黑胡椒意面
Bolognese|肉醬意粉|肉酱意面
Lasagna|千層麵|千层面
Risotto|意大利燴飯|意大利烩饭
Neapolitan Pizza|拿坡里薄餅|那不勒斯披萨
Tiramisu|提拉米蘇|提拉米苏
Gelato|意式雪糕|意式冰淇淋
Croissant|牛角包|牛角包
Baguette|法國長棍|法棍
Macarons|馬卡龍|马卡龙
Crêpes|法式薄餅|法式可丽饼
Ratatouille|法式雜菜煲|普罗旺斯炖菜
Beef Bourguignon|勃艮第紅酒燉牛肉|勃艮第红酒炖牛肉
Paella|西班牙海鮮飯|西班牙海鲜饭
Tapas|西班牙小食|西班牙小吃
Tortilla Española|西班牙薯仔蛋餅|西班牙土豆蛋饼
Churros|西班牙油條|西班牙油条
Tacos|墨西哥塔可|墨西哥塔可
Burritos|墨西哥卷餅|墨西哥卷饼
Quesadillas|墨西哥芝士薄餅|墨西哥奶酪薄饼
Guacamole|牛油果醬|牛油果酱
Ceviche|酸橘汁醃魚|酸橘汁腌鱼
Empanadas|拉丁美洲餡餅|拉丁美洲馅饼
Feijoada|巴西黑豆燉肉|巴西黑豆炖肉
Churrasco|巴西烤肉|巴西烤肉
Steak Frites|牛扒薯條|牛排薯条
Fish and Chips|炸魚薯條|炸鱼薯条
Sunday Roast|英式星期日烤肉|英式周日烤肉
Full English Breakfast|英式全早餐|英式全套早餐
Poutine|肉汁芝士薯條|肉汁奶酪薯条
New York Pizza|紐約薄餅|纽约披萨
Bagels|貝果|贝果
Hot Dogs|熱狗|热狗
Fried Chicken|炸雞|炸鸡
Texas BBQ|德州燒烤|德州烧烤
Smoked Brisket|煙燻牛胸肉|烟熏牛胸肉
Lobster Rolls|龍蝦包|龙虾卷
Clam Chowder|蛤蜊周打湯|蛤蜊浓汤
Cheesecake|芝士蛋糕|奶酪蛋糕
Brownies|布朗尼|布朗尼
Cookies|曲奇|饼干
Donuts|甜甜圈|甜甜圈
Pancakes|班戟|美式松饼
Waffles|窩夫|华夫饼
French Toast|法式多士|法式吐司
Basque Cheesecake|巴斯克芝士蛋糕|巴斯克奶酪蛋糕
Soufflé|梳乎厘|舒芙蕾
Panna Cotta|意式奶凍|意式奶冻
Crème Brûlée|法式焦糖燉蛋|法式焦糖布蕾
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'food.drink',
    category: 'food',
    cluster: 'food/drinks',
    rankStart: 5250,
    raw: r'''
Cold Brew Coffee|冷萃咖啡|冷萃咖啡
Flat White|澳白咖啡|澳白咖啡
Cappuccino|卡布奇諾|卡布奇诺
Café Latte|拿鐵咖啡|拿铁咖啡
Americano|美式咖啡|美式咖啡
Mocha|摩卡咖啡|摩卡咖啡
Single-Origin Coffee|單品咖啡|单品咖啡
Coffee Roasting|咖啡烘焙|咖啡烘焙
Home Espresso|家用意式濃縮咖啡|家用意式浓缩咖啡
Coffee Grinders|咖啡磨豆機|咖啡磨豆机
Coffee Gear|咖啡器材|咖啡器材
Tea Ceremony|茶道|茶道
Gongfu Tea|工夫茶|工夫茶|工夫茶
Pu-erh Tea|普洱茶|普洱茶|普洱茶
Oolong Tea|烏龍茶|乌龙茶
Jasmine Tea|茉莉花茶|茉莉花茶|茉莉花茶
Green Tea|綠茶|绿茶
Black Tea|紅茶|红茶
Herbal Tea|花草茶|花草茶|花草茶
Milk Tea|奶茶|奶茶
Thai Milk Tea|泰式奶茶|泰式奶茶
Chai|印度香料茶|印度香料茶
Yerba Mate|馬黛茶|马黛茶
Hot Chocolate|熱朱古力|热巧克力
Fresh Juice|鮮榨果汁|鲜榨果汁
Smoothies|果昔|果昔
Kombucha|康普茶|康普茶
Mocktails|無酒精雞尾酒|无酒精鸡尾酒
Craft Soda|手工汽水|手工汽水
Sparkling Water|氣泡水|气泡水
Wine Appreciation|葡萄酒品鑑|葡萄酒品鉴
Red Wine|紅酒|红酒
White Wine|白葡萄酒|白葡萄酒
Natural Wine|自然酒|自然酒
Champagne|香檳|香槟
Craft Beer|手工啤酒|精酿啤酒
IPA Beer|IPA 啤酒|IPA 啤酒
Stout Beer|世濤啤酒|世涛啤酒
Belgian Beer|比利時啤酒|比利时啤酒
Japanese Sake|日本酒|日本酒|日本酒
Whisky Appreciation|威士忌品鑑|威士忌品鉴
Japanese Whisky|日本威士忌|日本威士忌
Scotch Whisky|蘇格蘭威士忌|苏格兰威士忌
Bourbon|波本威士忌|波本威士忌
Gin|氈酒|金酒
Rum|朗姆酒|朗姆酒
Tequila|龍舌蘭酒|龙舌兰酒
Cocktails|雞尾酒|鸡尾酒
Classic Cocktails|經典雞尾酒|经典鸡尾酒
Tiki Cocktails|Tiki 雞尾酒|Tiki 鸡尾酒
Cocktail Bars|雞尾酒吧|鸡尾酒吧
Home Bartending|家庭調酒|家庭调酒
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'travel.destination_deep',
    category: 'travel',
    cluster: 'travel/destinations',
    rankStart: 5400,
    raw: r'''
Tokyo Travel|東京旅行
Kyoto Travel|京都旅行
Osaka Travel|大阪旅行
Hokkaido Travel|北海道旅行
Okinawa Travel|沖繩旅行|冲绳旅行
Kyushu Travel|九州旅行
Shikoku Travel|四國旅行|四国旅行
Tohoku Travel|東北旅行
Japanese Onsen Trips|日本溫泉旅行|日本温泉旅行
Seoul Travel|首爾旅行|首尔旅行
Busan Travel|釜山旅行
Jeju Travel|濟州旅行|济州旅行
Taipei Travel|台北旅行
Tainan Travel|台南旅行
Kaohsiung Travel|高雄旅行
Hualien Travel|花蓮旅行|花莲旅行
Macau Travel|澳門旅行|澳门旅行
Shenzhen Travel|深圳旅行
Guangzhou Travel|廣州旅行|广州旅行
Shanghai Travel|上海旅行
Beijing Travel|北京旅行
Chengdu Travel|成都旅行
Chongqing Travel|重慶旅行|重庆旅行
Yunnan Travel|雲南旅行|云南旅行
Xinjiang Travel|新疆旅行
Tibet Travel|西藏旅行
Hainan Travel|海南旅行
Bangkok Travel|曼谷旅行
Chiang Mai Travel|清邁旅行|清迈旅行
Phuket Travel|布吉旅行|普吉旅行
Vietnam Travel|越南旅行
Hanoi Travel|河內旅行|河内旅行
Ho Chi Minh City Travel|胡志明市旅行
Da Nang Travel|峴港旅行|岘港旅行
Indonesia Travel|印尼旅行
Bali Travel|峇里旅行|巴厘岛旅行
Philippines Travel|菲律賓旅行|菲律宾旅行
Malaysia Travel|馬來西亞旅行|马来西亚旅行
Kuala Lumpur Travel|吉隆坡旅行
Penang Travel|檳城旅行|槟城旅行
India Travel|印度旅行
Nepal Travel|尼泊爾旅行|尼泊尔旅行
Sri Lanka Travel|斯里蘭卡旅行|斯里兰卡旅行
Dubai Travel|杜拜旅行|迪拜旅行
Turkey Travel|土耳其旅行
Istanbul Travel|伊斯坦堡旅行|伊斯坦布尔旅行
Greece Travel|希臘旅行|希腊旅行
Portugal Travel|葡萄牙旅行
Netherlands Travel|荷蘭旅行|荷兰旅行
Germany Travel|德國旅行|德国旅行
Switzerland Travel|瑞士旅行
Austria Travel|奧地利旅行|奥地利旅行
Nordic Travel|北歐旅行|北欧旅行
Iceland Travel|冰島旅行|冰岛旅行
Norway Travel|挪威旅行
Sweden Travel|瑞典旅行
Finland Travel|芬蘭旅行|芬兰旅行
Denmark Travel|丹麥旅行|丹麦旅行
Eastern Europe Travel|東歐旅行|东欧旅行
Croatia Travel|克羅地亞旅行|克罗地亚旅行
Czech Republic Travel|捷克旅行
Poland Travel|波蘭旅行|波兰旅行
New York Travel|紐約旅行|纽约旅行
California Travel|加州旅行
Hawaii Travel|夏威夷旅行
Alaska Travel|阿拉斯加旅行
Mexico Travel|墨西哥旅行
South America Travel|南美旅行
Peru Travel|秘魯旅行|秘鲁旅行
Argentina Travel|阿根廷旅行
Brazil Travel|巴西旅行
Patagonia Travel|巴塔哥尼亞旅行|巴塔哥尼亚旅行
Africa Travel|非洲旅行
South Africa Travel|南非旅行
Morocco Travel|摩洛哥旅行
Egypt Travel|埃及旅行
Kenya Travel|肯亞旅行|肯尼亚旅行
Tanzania Travel|坦桑尼亞旅行|坦桑尼亚旅行
Safari Travel|Safari 之旅|Safari 旅行
Antarctica Travel|南極旅行|南极旅行
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'travel.style_deep',
    category: 'travel',
    cluster: 'travel/styles',
    rankStart: 5600,
    raw: r'''
Slow Travel|慢旅行|慢旅行
Digital Nomad Travel|數碼遊牧旅行|数字游民旅行
Working Holidays|工作假期|打工度假
Long-Haul Travel|長途旅行|长途旅行
Weekend Getaways|週末短途旅行|周末短途旅行
Island Hopping|跳島旅行|跳岛旅行
Rail Pass Travel|鐵路通票旅行|铁路通票旅行
Night Trains|夜行列車旅行|夜行列车旅行
Scenic Train Journeys|景觀鐵路旅行|景观铁路旅行
Sleeper Trains|臥鋪列車旅行|卧铺列车旅行
Luxury Trains|豪華列車旅行|豪华列车旅行
Campervan Travel|露營車旅行|房车旅行
Motorcycle Touring|電單車旅行|摩托车旅行
Cycling Tours|單車旅行|骑行旅行
Walking Holidays|徒步假期|徒步旅行
Pilgrimage Routes|朝聖路線旅行|朝圣路线旅行
Mountain Travel|山區旅行|山地旅行
Ski Holidays|滑雪假期|滑雪假期
Diving Trips|潛水旅行|潜水旅行
Surf Trips|滑浪旅行|冲浪旅行
Wellness Retreats|身心療癒旅行|康养度假
Spa Travel|水療旅行|水疗旅行
Onsen Travel|溫泉旅行|温泉旅行
Food Tours|美食之旅|美食之旅
Wine Travel|葡萄酒旅行|葡萄酒旅行
Coffee Travel|咖啡旅行|咖啡旅行
Architecture Travel|建築旅行|建筑旅行
Museum Travel|博物館之旅|博物馆之旅
Art Travel|藝術旅行|艺术旅行
Music Festival Travel|音樂節旅行|音乐节旅行
Film Location Travel|電影取景地旅行|电影取景地旅行
Anime Pilgrimage|聖地巡禮|圣地巡礼
Theme Park Travel|主題樂園旅行|主题乐园旅行
Disney Parks Travel|迪士尼樂園旅行|迪士尼乐园旅行
Universal Studios Travel|環球影城旅行|环球影城旅行
National Parks Travel|國家公園旅行|国家公园旅行
Wildlife Travel|野生動物旅行|野生动物旅行
Photography Travel|攝影旅行|摄影旅行
Aurora Hunting|極光旅行|极光旅行
Stargazing Trips|觀星旅行|观星旅行
Volcano Travel|火山旅行|火山旅行
Desert Travel|沙漠旅行|沙漠旅行
Jungle Travel|叢林旅行|丛林旅行
Archaeology Travel|考古旅行|考古旅行
Historical Site Travel|歷史古蹟旅行|历史古迹旅行
UNESCO Heritage Travel|世界遺產旅行|世界遗产旅行
River Cruises|河川郵輪旅行|内河游轮旅行
Expedition Cruises|探險郵輪|探险邮轮
Backpacking Southeast Asia|東南亞背包旅行|东南亚背包旅行
Gap-Year Travel|間隔年旅行|间隔年旅行
Student Travel|學生旅行|学生旅行
Pet-Friendly Travel|寵物友善旅行|宠物友好旅行
Accessible Travel|無障礙旅行|无障碍旅行
Travel Hacking|旅遊省錢技巧|旅行省钱技巧
Airline Miles & Points|航空里數與積分|航空里程与积分
Hotel Loyalty Programs|酒店會員計劃|酒店会员计划
Travel Planning|旅行規劃|旅行规划
Travel Journaling|旅行手帳|旅行日志
Travel Vlogging|旅行影片創作|旅行视频创作
Travel Blogging|旅行部落格|旅行博客
Packing Light|輕裝旅行|轻装旅行
One-Bag Travel|一袋旅行|单包旅行
Carry-On Only Travel|只帶手提行李旅行|只带随身行李旅行
Airport Lounges|機場貴賓室|机场贵宾室
Aviation Travel|航空主題旅行|航空主题旅行
Ferry Travel|渡輪旅行|轮渡旅行
''',
  ),
]);
