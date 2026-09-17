import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart10 = List.unmodifiable([
  ...parseInterestFamily(
    idPrefix: 'learning.book_genre',
    category: 'learning',
    cluster: 'books/subgenres',
    rankStart: 4400,
    raw: r'''
Literary Fiction
Contemporary Fiction
Historical Fiction
Family Saga
Coming-of-Age Fiction
Short Stories
Novellas
Classics
Modern Classics
Experimental Fiction
Magical Realism
Satirical Fiction
Humorous Fiction
Women's Fiction
Domestic Fiction
Campus Novels
Epistolary Novels
Adventure Fiction
Sea Fiction
Western Fiction
War Fiction
Political Fiction
Legal Fiction
Medical Fiction
Business Fiction
Crime Fiction
Detective Fiction
Police Procedural Books
Cozy Mystery Books
Locked-Room Mystery
Hard-Boiled Mystery
Noir Fiction
Spy Fiction
Espionage Thrillers
Psychological Thrillers
Domestic Thrillers
Legal Thrillers
Techno Thrillers
Historical Mysteries
True Crime Books
Horror Fiction
Gothic Horror
Cosmic Horror
Folk Horror Books
Body Horror Books
Ghost Stories
Vampire Fiction
Zombie Fiction
Occult Fiction
Dark Fantasy Books
Epic Fantasy
High Fantasy
Low Fantasy
Urban Fantasy Books
Romantic Fantasy Books
Sword and Sorcery Books
Mythic Fantasy
Fairy-Tale Retellings
Progression Fantasy
LitRPG
Science Fiction Books
Hard Science Fiction
Space Opera Books
Cyberpunk Books
Dystopian Fiction
Post-Apocalyptic Fiction
Time Travel Fiction
Alternate History Books
First Contact Fiction
Military Science Fiction
Climate Fiction|cli-fi
Solarpunk
Romance Novels
Contemporary Romance
Historical Romance Books
Romantic Comedy Books
Dark Romance Books
Sports Romance
Fantasy Romance|romantasy
Queer Romance
Young Adult Fiction
YA Fantasy
YA Romance
Middle Grade Fiction
Children's Classics
Picture Books
Graphic Novels
Superhero Comics
Independent Comics
European Comics
Manga Reading
Manhwa Reading
Webtoon Reading
Memoirs
Autobiography
Biography
History Books
Popular Science Books
Science Writing
Nature Writing
Travel Writing
Food Writing
Music Books
Film Books
Art Books
Architecture Books
Philosophy Books
Psychology Books
Economics Books
Business Books
Management Books
Marketing Books
Startup Books
Personal Finance Books
Investing Books
Self-Help Books
Productivity Books
Leadership Books
Technology Books
Programming Books
Design Books
Poetry Collections
Essays
Literary Criticism
Book Collecting
Rare Books
Audiobooks
E-books
Book Blogging
BookTok
BookTube
Bookstagram
Library Visits
Independent Bookstores
Second-Hand Bookstores
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
Teochew Cuisine|潮州菜
Hakka Cuisine|客家菜
Shanghainese Cuisine|上海菜
Beijing Cuisine|京菜
Shandong Cuisine|魯菜|鲁菜
Hunan Cuisine|湘菜
Fujian Cuisine|閩菜|闽菜
Jiangsu Cuisine|蘇菜|苏菜
Zhejiang Cuisine|浙菜
Yunnan Cuisine|雲南菜|云南菜
Xinjiang Cuisine|新疆菜
Chaoshan Cuisine|潮汕菜
Macanese Cuisine|澳門菜|澳门菜
Okinawan Cuisine|沖繩料理|沖縄料理|冲绳料理
Kaiseki|懷石料理|懐石料理|怀石料理
Izakaya Food|居酒屋料理
Yakitori|燒鳥|焼き鳥|烧鸟
Yakiniku|日式燒肉|焼肉|日式烧肉
Korean BBQ|韓式燒肉|韩式烤肉
Korean Fried Chicken|韓式炸雞|韩式炸鸡
Temple Food
Burmese Cuisine
Filipino Cuisine
Indonesian Cuisine
Balinese Cuisine
Cambodian Cuisine
Laotian Cuisine
Nepalese Cuisine
Sri Lankan Cuisine
Bangladeshi Cuisine
Pakistani Cuisine
Persian Cuisine
Lebanese Cuisine
Turkish Cuisine
Greek Cuisine
Israeli Cuisine
Moroccan Cuisine
Ethiopian Cuisine
Egyptian Cuisine
South African Cuisine
West African Cuisine
Nigerian Cuisine
Brazilian Cuisine
Argentinian Cuisine
Peruvian Cuisine
Colombian Cuisine
Cuban Cuisine
Caribbean Cuisine
Tex-Mex
Cajun Cuisine
Creole Cuisine
Southern US Food
New York Food
Californian Cuisine
Nordic Cuisine
British Food
Irish Food
German Food
Austrian Food
Swiss Food
Portuguese Food
Basque Cuisine
Catalan Cuisine
Eastern European Food
Polish Food
Hungarian Food
Georgian Cuisine
Russian Food
Ukrainian Food
Balkan Cuisine
Fusion Cuisine
Farm-to-Table
Plant-Based Cooking
Raw Food
Gluten-Free Food
Halal Food
Kosher Food
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
Congee|粥
Wonton Noodles|雲吞麵|云吞面
Beef Brisket Noodles|牛腩麵|牛腩面
Hong Kong Milk Tea|港式奶茶
Pineapple Bun|菠蘿包|菠萝包
Egg Tart|蛋撻|蛋挞
French Toast Hong Kong Style|西多士
Rice Noodle Rolls|腸粉|肠粉
Soup Dumplings|小籠包|小笼包
Sheng Jian Bao|生煎包
Peking Duck|北京烤鴨|北京烤鸭
Mapo Tofu|麻婆豆腐
Kung Pao Chicken|宮保雞丁|宫保鸡丁
Dan Dan Noodles|擔擔麵|担担面
Sichuan Boiled Fish|水煮魚|水煮鱼
Mala Xiang Guo|麻辣香鍋|麻辣香锅
Xiaolongbao|小籠包|小笼包
Scallion Pancakes|蔥油餅|葱油饼
Taiwanese Beef Noodles|台灣牛肉麵|台湾牛肉面
Lu Rou Fan|滷肉飯|卤肉饭
Gua Bao|刈包
Oyster Omelette|蚵仔煎
Stinky Tofu|臭豆腐
Japanese Curry|日式咖喱
Tonkatsu|吉列豬扒|とんかつ|炸猪排
Tempura|天婦羅|天ぷら|天妇罗
Udon|烏冬|うどん|乌冬
Soba|蕎麥麵|そば|荞麦面
Okonomiyaki|大阪燒|お好み焼き|大阪烧
Takoyaki|章魚燒|たこ焼き|章鱼烧
Onigiri|飯糰|おにぎり|饭团
Donburi|丼飯|丼
Oyakodon|親子丼|親子丼|亲子丼
Gyudon|牛丼|牛丼
Omurice|蛋包飯|オムライス|蛋包饭
Japanese Cheesecake|日式芝士蛋糕
Mochi|麻糬|餅|麻薯
Bibimbap|韓式拌飯|비빔밥|韩式拌饭
Tteokbokki|辣炒年糕|떡볶이
Kimchi|泡菜|김치
Kimbap|紫菜包飯|김밥|紫菜包饭
Samgyeopsal|韓式五花肉|삼겹살|韩式五花肉
Bulgogi|韓式烤肉|불고기
Sundubu Jjigae|嫩豆腐鍋|순두부찌개|嫩豆腐锅
Japchae|韓式炒粉絲|잡채|韩式炒粉丝
Naengmyeon|冷麵|냉면|冷面
Pho|越南河粉
Banh Mi|越南法包
Bun Cha|越南烤肉米線|越南烤肉米线
Pad Thai|泰式炒河
Tom Yum|冬蔭功|冬阴功
Green Curry|泰式青咖喱
Mango Sticky Rice|芒果糯米飯|芒果糯米饭
Hainanese Chicken Rice|海南雞飯|海南鸡饭
Laksa|叻沙
Bak Kut Teh|肉骨茶
Nasi Lemak|椰漿飯|椰浆饭
Roti Canai|印度煎餅|印度煎饼
Satay|沙嗲
Biryani|印度香飯|印度香饭
Butter Chicken
Tandoori Chicken
Masala Dosa
Samosa
Naan
Curry Laksa
Pasta
Carbonara
Cacio e Pepe
Bolognese
Lasagna
Risotto
Neapolitan Pizza
Tiramisu
Gelato
Croissant
Baguette
Macarons
Crêpes
Ratatouille
Beef Bourguignon
Paella
Tapas
Tortilla Española
Churros
Tacos
Burritos
Quesadillas
Guacamole
Ceviche
Empanadas
Feijoada
Churrasco
Steak Frites
Fish and Chips
Sunday Roast
Full English Breakfast
Poutine
New York Pizza
Bagels
Hot Dogs
Fried Chicken
Texas BBQ
Smoked Brisket
Lobster Rolls
Clam Chowder
Cheesecake
Brownies
Cookies
Donuts
Pancakes
Waffles
French Toast
Basque Cheesecake
Soufflé
Panna Cotta
Crème Brûlée
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'food.drink',
    category: 'food',
    cluster: 'food/drinks',
    rankStart: 5250,
    raw: r'''
Cold Brew Coffee
Flat White
Cappuccino
Café Latte
Americano
Mocha
Single-Origin Coffee
Coffee Roasting
Home Espresso
Coffee Grinders
Coffee Gear
Tea Ceremony
Gongfu Tea|工夫茶
Pu-erh Tea|普洱茶
Oolong Tea|烏龍茶|乌龙茶
Jasmine Tea|茉莉花茶
Green Tea|綠茶|绿茶
Black Tea|紅茶|红茶
Herbal Tea|花草茶
Milk Tea
Thai Milk Tea
Chai
Yerba Mate
Hot Chocolate
Fresh Juice
Smoothies
Kombucha
Mocktails
Craft Soda
Sparkling Water
Wine Appreciation
Red Wine
White Wine
Natural Wine
Champagne
Craft Beer
IPA Beer
Stout Beer
Belgian Beer
Japanese Sake|日本酒
Whisky Appreciation
Japanese Whisky
Scotch Whisky
Bourbon
Gin
Rum
Tequila
Cocktails
Classic Cocktails
Tiki Cocktails
Cocktail Bars
Home Bartending
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
Safari Travel|野生動物旅行|野生动物旅行
Antarctica Travel|南極旅行|南极旅行
''',
  ),
  ...parseInterestFamily(
    idPrefix: 'travel.style_deep',
    category: 'travel',
    cluster: 'travel/styles',
    rankStart: 5600,
    raw: r'''
Slow Travel
Digital Nomad Travel
Working Holidays
Long-Haul Travel
Weekend Getaways
Island Hopping
Rail Pass Travel
Night Trains
Scenic Train Journeys
Sleeper Trains
Luxury Trains
Road Tripping
Campervan Travel
Motorcycle Touring
Cycling Tours
Walking Holidays
Pilgrimage Routes
Mountain Travel
Ski Holidays
Diving Trips
Surf Trips
Wellness Retreats
Spa Travel
Onsen Travel
Food Tours
Wine Travel
Coffee Travel
Architecture Travel
Museum Travel
Art Travel
Music Festival Travel
Film Location Travel
Anime Pilgrimage|聖地巡禮|圣地巡礼
Theme Park Travel
Disney Parks Travel
Universal Studios Travel
National Parks Travel
Wildlife Travel
Photography Travel
Aurora Hunting|極光旅行|极光旅行
Stargazing Trips
Volcano Travel
Desert Travel
Jungle Travel
Archaeology Travel
Historical Site Travel
UNESCO Heritage Travel
Cruise Travel
River Cruises
Expedition Cruises
Backpacking Southeast Asia
Gap-Year Travel
Student Travel
Pet-Friendly Travel
Accessible Travel
Travel Hacking
Airline Miles & Points
Hotel Loyalty Programs
Travel Planning
Travel Journaling
Travel Vlogging
Travel Blogging
Packing Light
One-Bag Travel
Carry-On Only Travel
Airport Lounges
Aviation Travel
Ferry Travel
''',
  ),
]);
