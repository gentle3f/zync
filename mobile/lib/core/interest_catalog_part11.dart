import 'interest_catalog_parser.dart';
import 'models.dart';

/// Release-readiness additions focused on everyday social/lifestyle/wellness
/// breadth plus a rights-aware car-brand affinity family.
///
/// Brand affinity remains matchable as an interest. It does NOT imply that
/// Zync may generate or ship branded collectible artwork; Cardverse policy is
/// resolved separately by InterestCardPolicyResolver.
final List<InterestDefinition> kInterestCatalogPart11 = List.unmodifiable([
  ...parseInterestCatalogRows(r'''sports.triathlon|sports|endurance|840|Triathlon|三項鐵人|铁人三项|triathlons
crafts.scrapbooking|crafts|crafts|841|Scrapbooking|剪貼簿創作|剪贴簿创作|scrapbook;memory book
arts.creative_writing|arts|writing|842|Creative Writing|創意寫作|创意写作|writing;寫作;写作
arts.journaling|arts|writing|843|Journaling|寫手帳／日誌|写手账／日志|journal;diary;手帳;手账
arts.food_photography|arts|photography|844|Food Photography|美食攝影|美食摄影|food photos;影食物;拍美食
outdoors.foraging|outdoors|hiking|845|Foraging|野外採集|野外采集|wild food foraging
lifestyle.parties|lifestyle|social|846|Parties & Social Gatherings|派對與聚會|派对与聚会|parties;social gatherings;聚會;聚会
lifestyle.cafe_hopping|lifestyle|social|847|Cafe Hopping|Cafe 巡遊|咖啡店探店|café hopping;cafe crawl;咖啡店巡遊;咖啡店巡游
lifestyle.shopping|lifestyle|shopping|848|Shopping|行街購物|逛街购物|shopping;行街;逛街
lifestyle.thrifting|lifestyle|shopping|849|Thrifting|二手尋寶|逛二手店|thrift shopping;second-hand shopping;二手店
lifestyle.flea_markets|lifestyle|shopping|850|Flea Markets|跳蚤市場|跳蚤市场|flea market;二手市集
lifestyle.night_markets|lifestyle|shopping|851|Night Markets|夜市|夜市|night market
lifestyle.farmers_markets|lifestyle|shopping|852|Farmers' Markets|農夫市集|农夫市集|farmers market;farmer market
lifestyle.city_walks|lifestyle|social|853|City Walks|城市漫步|城市漫步|city walk;urban walks;街區散步;街区散步
lifestyle.brunch|lifestyle|social|854|Brunch|早午餐|早午餐|brunching
lifestyle.dinner_parties|lifestyle|social|855|Dinner Parties|晚餐聚會|晚餐聚会|dinner party;home dinner
lifestyle.local_events|lifestyle|social|856|Local Events|本地活動|本地活动|community events;local happenings
learning.personal_development|learning|knowledge|857|Personal Development|個人成長|个人成长|personal growth;self development
learning.debating|learning|knowledge|858|Debating|辯論|辩论|debate;debates
technology.pc_building|technology|hardware|859|PC Building|砌電腦|组装电脑|build a pc;computer building;砌機;装机
fashion.hair_styling|fashion|fashion|860|Hair Styling|髮型造型|发型造型|hairstyling;hair style
fashion.fragrance|fashion|fashion|861|Fragrance|香水與香氛|香水与香氛|perfume;fragrances;scent
transport.driving|transport|cars|862|Driving|駕駛|驾驶|drive;揸車;开车
entertainment.stand_up_comedy|entertainment|live_comedy|863|Stand-up Comedy|棟篤笑／單口喜劇|单口喜剧|standup comedy;stand-up;棟篤笑;脱口秀
entertainment.podcasts|entertainment|audio|864|Podcasts|Podcast／播客|播客|podcast;播客
entertainment.online_video|entertainment|screen|865|Online Video|網上影片|在线视频|online videos;web video
entertainment.youtube|entertainment|platforms/brands|866|YouTube|YouTube|YouTube|youtube videos
wellness.massage|wellness|recovery|867|Massage|按摩|按摩|massage therapy
wellness.nutrition|wellness|nutrition|868|Nutrition|營養|营养|nutrition
wellness.healthy_eating|wellness|nutrition|869|Healthy Eating|健康飲食|健康饮食|eat healthy;balanced eating
wellness.self_care|wellness|mind_body|870|Self-Care|自我照顧|自我关爱|self care;me time
wellness.spa|wellness|recovery|871|Spa & Wellness Days|水療與放鬆日|水疗与放松|spa;spa day;wellness day
wellness.sound_bath|wellness|mind_body|872|Sound Baths|聲音浴|声音浴|sound bath;sound healing
wellness.aromatherapy|wellness|recovery|873|Aromatherapy|芳香療法|芳香疗法|essential oils
wellness.recovery|wellness|recovery|874|Recovery & Relaxation|恢復與放鬆|恢复与放松|recovery;relaxation
wellness.digital_detox|wellness|mind_body|875|Digital Detox|數碼排毒|数字排毒|screen break;phone detox
food.meal_prep|food|cooking|876|Meal Prep|備餐|备餐|meal preparation;batch cooking'''),

  ...parseInterestFamily(
    idPrefix: 'transport.car_brand',
    category: 'transport',
    cluster: 'cars/brands',
    rankStart: 900,
    raw: r'''
Toyota
Lexus
Honda
Acura
Nissan
Infiniti
Mazda
Subaru
Mitsubishi
Suzuki
BMW
Mercedes-Benz|Mercedes;Benz
Audi
Volkswagen|VW
Porsche
MINI|Mini Cooper
smart|Smart
Opel
Škoda|Skoda
SEAT
CUPRA|Cupra
Volvo
Polestar
Ferrari
Lamborghini
Maserati
Alfa Romeo
Fiat
Pagani
McLaren
Aston Martin
Bentley
Rolls-Royce|Rolls Royce
Jaguar
Land Rover
Lotus
Ford
Chevrolet|Chevy
Cadillac
Jeep
Dodge
Ram
GMC
Lincoln
Tesla
Rivian
Lucid
Hyundai
Kia
Genesis
BYD
Geely
Zeekr
NIO
XPeng|Xpeng
Li Auto
Hongqi
Chery
GWM|Great Wall Motor
Xiaomi Auto|Xiaomi EV
Renault
Peugeot
Citroën|Citroen
MG
VinFast
''',
  ),
]);
