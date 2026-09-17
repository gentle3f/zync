import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart4 = parseInterestCatalogRows(r'''travel.general|travel|travel_general|19|Travel|旅行|旅行|travelling;旅遊;旅游
travel.japan|travel|travel_destinations|20|Japan Travel|日本旅行|日本旅行|japan;日本旅遊;日本旅游
travel.roadtrip|travel|travel_styles|21|Road Trips|自駕遊|自驾游|road trip
food.japanese|food|cuisines|22|Japanese Food|日本料理|日本料理|japanese cuisine;日餐
food.coffee|food|coffee|23|Coffee|咖啡|咖啡|specialty coffee
food.cooking|food|cooking|24|Cooking|烹飪|烹饪|cook;煮食;下廚
food.chinese|food|cuisines|440|Chinese Food|||中菜;中餐
food.cantonese|food|cuisines|441|Cantonese Food|||廣東菜;粤菜
food.sichuan|food|cuisines|442|Sichuan Food|||川菜
food.dim_sum|food|cuisines|443|Dim Sum|||點心;点心
food.hot_pot|food|cuisines|444|Hot Pot|||火鍋;火锅
food.korean|food|cuisines|445|Korean Food|||韓國料理;韩国料理
food.thai|food|cuisines|446|Thai Food|||泰國菜;泰国菜
food.vietnamese|food|cuisines|447|Vietnamese Food|||越南菜
food.indian|food|cuisines|448|Indian Food|||印度菜
food.italian|food|cuisines|449|Italian Food|||意大利菜
food.french|food|cuisines|450|French Food|||法國菜;法国菜
food.mexican|food|cuisines|451|Mexican Food|||墨西哥菜
food.mediterranean|food|cuisines|452|Mediterranean Food|||地中海菜
food.middle_eastern|food|cuisines|453|Middle Eastern Food|||中東菜;中东菜
food.spanish|food|cuisines|454|Spanish Food|||西班牙菜
food.taiwanese|food|cuisines|455|Taiwanese Food|||台灣菜;台湾菜
food.hong_kong|food|cuisines|456|Hong Kong Food|||港式美食;茶餐廳
food.singaporean|food|cuisines|457|Singaporean Food|||新加坡菜
food.malaysian|food|cuisines|458|Malaysian Food|||馬來西亞菜;马来西亚菜
food.vegetarian|food|cuisines|459|Vegetarian Food|||素食
food.vegan|food|cuisines|460|Vegan Food|||純素;纯素
food.sushi|food|food_types|465|Sushi|||壽司;寿司
food.ramen|food|food_types|466|Ramen|||拉麵;拉面
food.bbq|food|food_types|467|BBQ & Grilling|||燒烤;烧烤
food.steak|food|food_types|468|Steak|||牛扒;牛排
food.seafood|food|food_types|469|Seafood|||海鮮;海鲜
food.noodles|food|food_types|470|Noodles|||麵;面
food.pizza|food|food_types|471|Pizza|||薄餅;披萨
food.burgers|food|food_types|472|Burgers|||漢堡;汉堡
food.desserts|food|food_types|473|Desserts|||甜品;甜点
food.chocolate|food|food_types|474|Chocolate|||朱古力;巧克力
food.ice_cream|food|food_types|475|Ice Cream|||雪糕;冰淇淋
food.baking|food|food_types|476|Baking|||烘焙
food.bread|food|food_types|477|Bread|||麵包;面包
food.cheese|food|food_types|478|Cheese|||芝士;奶酪
food.street_food|food|food_types|479|Street Food|||街頭小食;街头小吃
food.brunch|food|food_types|480|Brunch|||早午餐
food.fine_dining|food|food_types|481|Fine Dining|||高級餐飲;高级餐饮
food.food_hunting|food|food_types|482|Food Hunting|||搵食;美食探店
food.specialty_coffee|food|coffee|490|Specialty Coffee|||精品咖啡
food.espresso|food|coffee|491|Espresso|||濃縮咖啡;浓缩咖啡
food.pour_over|food|coffee|492|Pour-over Coffee|||手沖咖啡;手冲咖啡
food.latte_art|food|coffee|493|Latte Art|||拉花
food.cafe_hopping|food|coffee|494|Cafe Hopping|||咖啡店巡遊;咖啡店探店
food.tea|food|coffee|495|Tea|||茶
food.chinese_tea|food|coffee|496|Chinese Tea|||中國茶;中国茶
food.matcha|food|coffee|497|Matcha|||抹茶
food.bubble_tea|food|coffee|498|Bubble Tea|||珍珠奶茶;珍奶
travel.solo|travel|travel_styles|510|Solo Travel|||獨遊;独自旅行
travel.family|travel|travel_styles|511|Family Travel|||親子旅行;亲子旅行
travel.luxury|travel|travel_styles|512|Luxury Travel|||
travel.budget|travel|travel_styles|513|Budget Travel|||窮遊;穷游
travel.backpacking|travel|travel_styles|514|Backpacking Travel|||背包旅行
travel.city_breaks|travel|travel_styles|515|City Breaks|||
travel.beach|travel|travel_styles|516|Beach Holidays|||海灘假期;海滩度假
travel.cruises|travel|travel_styles|517|Cruises|||郵輪;邮轮
travel.staycations|travel|travel_styles|518|Staycations|||宅度假
travel.food_travel|travel|travel_styles|519|Food Travel|||美食旅行
travel.cultural_travel|travel|travel_styles|520|Cultural Travel|||文化旅行
travel.train_travel|travel|travel_styles|521|Train Travel|||鐵路旅行;铁路旅行
travel.hong_kong|travel|travel_destinations|530|Hong Kong Travel|||香港旅遊;香港旅游
travel.taiwan|travel|travel_destinations|531|Taiwan Travel|||台灣旅行;台湾旅行
travel.korea|travel|travel_destinations|532|South Korea Travel|||韓國旅行;韩国旅行
travel.china|travel|travel_destinations|533|Mainland China Travel|||中國內地旅行;中国大陆旅行
travel.thailand|travel|travel_destinations|534|Thailand Travel|||泰國旅行;泰国旅行
travel.singapore|travel|travel_destinations|535|Singapore Travel|||新加坡旅行
travel.europe|travel|travel_destinations|536|Europe Travel|||歐洲旅行;欧洲旅行
travel.uk|travel|travel_destinations|537|UK Travel|||英國旅行;英国旅行
travel.france|travel|travel_destinations|538|France Travel|||法國旅行;法国旅行
travel.italy|travel|travel_destinations|539|Italy Travel|||意大利旅行
travel.spain|travel|travel_destinations|540|Spain Travel|||西班牙旅行
travel.usa|travel|travel_destinations|541|USA Travel|||美國旅行;美国旅行
travel.australia|travel|travel_destinations|542|Australia Travel|||澳洲旅行
travel.new_zealand|travel|travel_destinations|543|New Zealand Travel|||紐西蘭旅行;新西兰旅行
travel.canada|travel|travel_destinations|544|Canada Travel|||加拿大旅行''');
