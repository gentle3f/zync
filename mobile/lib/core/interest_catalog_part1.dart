import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart1 = parseInterestCatalogRows(r'''sports.badminton|sports|racket|1|Badminton|羽毛球|羽毛球|shuttlecock;羽球
sports.tennis|sports|racket|2|Tennis|網球|网球|
sports.running|sports|running|3|Running|跑步|跑步|jogging;慢跑
sports.hiking|sports|hiking|4|Hiking|行山|徒步|trekking;遠足;远足
sports.football|sports|team_ball|5|Football / Soccer|足球|足球|soccer
sports.basketball|sports|team_ball|6|Basketball|籃球|篮球|
sports.gym|wellness|fitness|7|Gym & Fitness|健身|健身|gym;weight training;重量訓練;重量训练
outdoors.cycling|outdoors|cycling|35|Cycling|踩單車|騎行|biking;單車;自行車;自行车
outdoors.camping|outdoors|camping|36|Camping|露營|露营|
sports.table_tennis|sports|racket|40|Table Tennis|||ping pong;乒乓球
sports.squash|sports|racket|41|Squash|||
sports.pickleball|sports|racket|42|Pickleball|||
sports.padel|sports|racket|43|Padel|||
sports.racquetball|sports|racket|44|Racquetball|||
sports.soft_tennis|sports|racket|45|Soft Tennis|||
sports.volleyball|sports|team_ball|50|Volleyball|||
sports.baseball|sports|team_ball|51|Baseball|||
sports.softball|sports|team_ball|52|Softball|||
sports.rugby|sports|team_ball|53|Rugby|||
sports.american_football|sports|team_ball|54|American Football|||
sports.handball|sports|team_ball|55|Handball|||
sports.netball|sports|team_ball|56|Netball|||
sports.dodgeball|sports|team_ball|57|Dodgeball|||
sports.cricket|sports|team_ball|58|Cricket|||
sports.field_hockey|sports|team_ball|59|Field Hockey|||
sports.lacrosse|sports|team_ball|60|Lacrosse|||
sports.futsal|sports|team_ball|61|Futsal|||
sports.beach_volleyball|sports|team_ball|62|Beach Volleyball|||
sports.boxing|sports|combat|70|Boxing|||拳擊;拳击
sports.muay_thai|sports|combat|71|Muay Thai|||泰拳
sports.mma|sports|combat|72|MMA|||mixed martial arts
sports.brazilian_jiu_jitsu|sports|combat|73|Brazilian Jiu-Jitsu|||bjj
sports.judo|sports|combat|74|Judo|||柔道
sports.karate|sports|combat|75|Karate|||空手道
sports.taekwondo|sports|combat|76|Taekwondo|||跆拳道
sports.wrestling|sports|combat|77|Wrestling|||
sports.fencing|sports|combat|78|Fencing|||劍擊;击剑
sports.kendo|sports|combat|79|Kendo|||劍道;剑道
sports.wing_chun|sports|combat|80|Wing Chun|||詠春;咏春
sports.kickboxing|sports|combat|81|Kickboxing|||
sports.archery|sports|precision|90|Archery|||射箭
sports.shooting_sport|sports|precision|91|Sport Shooting|||
sports.darts|sports|precision|92|Darts|||
sports.bowling|sports|precision|93|Bowling|||
sports.golf|sports|precision|94|Golf|||
sports.mini_golf|sports|precision|95|Mini Golf|||
sports.billiards|sports|precision|96|Billiards|||
sports.snooker|sports|precision|97|Snooker|||
sports.pool|sports|precision|98|Pool|||
sports.trail_running|sports|running|105|Trail Running|||越野跑
sports.marathon|sports|running|106|Marathon|||馬拉松;马拉松
sports.sprinting|sports|running|107|Sprinting|||
sports.track_and_field|sports|running|108|Track & Field|||athletics
sports.orienteering|sports|running|109|Orienteering|||
sports.race_walking|sports|running|110|Race Walking|||
gaming.chess|sports|mind_sports|120|Chess|||國際象棋;国际象棋
gaming.go|sports|mind_sports|121|Go / Weiqi|||圍棋;围棋
gaming.xiangqi|sports|mind_sports|122|Chinese Chess|||象棋
gaming.mahjong|sports|mind_sports|123|Mahjong|||麻雀;麻將;麻将
gaming.poker|sports|mind_sports|124|Poker|||
gaming.bridge|sports|mind_sports|125|Bridge|||
sports.skateboarding|sports|skating|130|Skateboarding|||
sports.roller_skating|sports|skating|131|Roller Skating|||
sports.inline_skating|sports|skating|132|Inline Skating|||
outdoors.backpacking|outdoors|hiking|140|Backpacking|||
outdoors.mountaineering|outdoors|hiking|141|Mountaineering|||
outdoors.rock_climbing|outdoors|hiking|142|Rock Climbing|||
outdoors.bouldering|outdoors|hiking|143|Bouldering|||
outdoors.via_ferrata|outdoors|hiking|144|Via Ferrata|||
outdoors.canyoning|outdoors|hiking|145|Canyoning|||
outdoors.geocaching|outdoors|hiking|146|Geocaching|||
outdoors.nature_walks|outdoors|hiking|147|Nature Walks|||
outdoors.birdwatching|outdoors|hiking|148|Birdwatching|||
outdoors.stargazing|outdoors|hiking|149|Stargazing|||
outdoors.glamping|outdoors|camping|155|Glamping|||
outdoors.bushcraft|outdoors|camping|156|Bushcraft|||
outdoors.van_life|outdoors|camping|157|Van Life|||
outdoors.campervans|outdoors|camping|158|Campervans|||
outdoors.picnics|outdoors|camping|159|Picnics|||
outdoors.mountain_biking|outdoors|cycling|165|Mountain Biking|||
outdoors.road_cycling|outdoors|cycling|166|Road Cycling|||
outdoors.bmx|outdoors|cycling|167|BMX|||
outdoors.bikepacking|outdoors|cycling|168|Bikepacking|||
outdoors.fixed_gear_cycling|outdoors|cycling|169|Fixed Gear Cycling|||
outdoors.swimming|outdoors|water|175|Swimming|||游泳
outdoors.surfing|outdoors|water|176|Surfing|||滑浪;衝浪
outdoors.scuba_diving|outdoors|water|177|Scuba Diving|||潛水;潜水
outdoors.freediving|outdoors|water|178|Freediving|||自由潛水;自由潜水
outdoors.snorkeling|outdoors|water|179|Snorkeling|||浮潛;浮潜
outdoors.kayaking|outdoors|water|180|Kayaking|||獨木舟;皮划艇
outdoors.canoeing|outdoors|water|181|Canoeing|||
outdoors.sailing|outdoors|water|182|Sailing|||帆船
outdoors.stand_up_paddleboarding|outdoors|water|183|Stand-up Paddleboarding|||sup
outdoors.windsurfing|outdoors|water|184|Windsurfing|||
outdoors.kitesurfing|outdoors|water|185|Kitesurfing|||
outdoors.rowing|outdoors|water|186|Rowing|||划艇
outdoors.dragon_boat|outdoors|water|187|Dragon Boat|||龍舟;龙舟
outdoors.wakeboarding|outdoors|water|188|Wakeboarding|||
outdoors.water_skiing|outdoors|water|189|Water Skiing|||
outdoors.skiing|outdoors|winter|195|Skiing|||滑雪
outdoors.snowboarding|outdoors|winter|196|Snowboarding|||單板滑雪;单板滑雪
outdoors.ice_skating|outdoors|winter|197|Ice Skating|||溜冰
outdoors.figure_skating|outdoors|winter|198|Figure Skating|||花式溜冰;花样滑冰
outdoors.ice_hockey|outdoors|winter|199|Ice Hockey|||冰球
outdoors.snowshoeing|outdoors|winter|200|Snowshoeing|||
wellness.weightlifting|wellness|fitness|210|Weightlifting|||舉重;举重
wellness.bodybuilding|wellness|fitness|211|Bodybuilding|||健美
wellness.calisthenics|wellness|fitness|212|Calisthenics|||街頭健身;街头健身
wellness.crossfit|wellness|fitness|213|CrossFit|||
wellness.hiit|wellness|fitness|214|HIIT|||
wellness.pilates|wellness|fitness|215|Pilates|||普拉提
wellness.yoga|wellness|fitness|216|Yoga|||瑜伽
wellness.stretching|wellness|fitness|217|Stretching|||拉筋
wellness.mobility|wellness|fitness|218|Mobility Training|||
wellness.spin_class|wellness|fitness|219|Spin Class|||
wellness.aerobics|wellness|fitness|220|Aerobics|||
wellness.dance_fitness|wellness|fitness|221|Dance Fitness|||zumba
wellness.jump_rope|wellness|fitness|222|Jump Rope|||跳繩;跳绳
wellness.meditation|wellness|mind_body|230|Meditation|||冥想
wellness.mindfulness|wellness|mind_body|231|Mindfulness|||正念
wellness.breathwork|wellness|mind_body|232|Breathwork|||呼吸練習;呼吸练习
wellness.sleep|wellness|mind_body|233|Sleep Optimization|||
wellness.sauna|wellness|mind_body|234|Sauna|||桑拿
wellness.cold_plunge|wellness|mind_body|235|Cold Plunge|||''');
