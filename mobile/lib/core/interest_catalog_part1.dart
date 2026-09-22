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
sports.table_tennis|sports|racket|40|Table Tennis|乒乓球|乒乓球|ping pong;乒乓球
sports.squash|sports|racket|41|Squash|壁球|壁球|
sports.pickleball|sports|racket|42|Pickleball|匹克球|匹克球|
sports.padel|sports|racket|43|Padel|板式網球|板式网球|
sports.racquetball|sports|racket|44|Racquetball|美式壁球|美式壁球|
sports.soft_tennis|sports|racket|45|Soft Tennis|軟式網球|软式网球|
sports.volleyball|sports|team_ball|50|Volleyball|排球|排球|
sports.baseball|sports|team_ball|51|Baseball|棒球|棒球|
sports.softball|sports|team_ball|52|Softball|壘球|垒球|
sports.rugby|sports|team_ball|53|Rugby|欖球|橄榄球|
sports.american_football|sports|team_ball|54|American Football|美式足球|美式足球|
sports.handball|sports|team_ball|55|Handball|手球|手球|
sports.netball|sports|team_ball|56|Netball|投球|无挡板篮球|
sports.dodgeball|sports|team_ball|57|Dodgeball|閃避球|躲避球|
sports.cricket|sports|team_ball|58|Cricket|板球|板球|
sports.field_hockey|sports|team_ball|59|Field Hockey|草地曲棍球|草地曲棍球|
sports.lacrosse|sports|team_ball|60|Lacrosse|長曲棍球|长曲棍球|
sports.futsal|sports|team_ball|61|Futsal|五人足球|五人制足球|
sports.beach_volleyball|sports|team_ball|62|Beach Volleyball|沙灘排球|沙滩排球|
sports.boxing|sports|combat|70|Boxing|拳擊|拳击|拳擊;拳击
sports.muay_thai|sports|combat|71|Muay Thai|泰拳|泰拳|泰拳
sports.mma|sports|combat|72|MMA|綜合格鬥|综合格斗|mixed martial arts
sports.brazilian_jiu_jitsu|sports|combat|73|Brazilian Jiu-Jitsu|巴西柔術|巴西柔术|bjj
sports.judo|sports|combat|74|Judo|柔道|柔道|柔道
sports.karate|sports|combat|75|Karate|空手道|空手道|空手道
sports.taekwondo|sports|combat|76|Taekwondo|跆拳道|跆拳道|跆拳道
sports.wrestling|sports|combat|77|Wrestling|摔跤|摔跤|
sports.fencing|sports|combat|78|Fencing|劍擊|击剑|劍擊;击剑
sports.kendo|sports|combat|79|Kendo|劍道|剑道|劍道;剑道
sports.wing_chun|sports|combat|80|Wing Chun|詠春|咏春|詠春;咏春
sports.kickboxing|sports|combat|81|Kickboxing|踢拳|踢拳|
sports.archery|sports|precision|90|Archery|射箭|射箭|射箭
sports.shooting_sport|sports|precision|91|Sport Shooting|射擊運動|射击运动|
sports.darts|sports|precision|92|Darts|飛鏢|飞镖|
sports.bowling|sports|precision|93|Bowling|保齡球|保龄球|
sports.golf|sports|precision|94|Golf|高爾夫球|高尔夫球|
sports.mini_golf|sports|precision|95|Mini Golf|迷你高爾夫球|迷你高尔夫球|
sports.billiards|sports|precision|96|Billiards|桌球|台球|
sports.snooker|sports|precision|97|Snooker|英式桌球|斯诺克|
sports.pool|sports|precision|98|Pool|美式桌球|美式台球|
sports.trail_running|sports|running|105|Trail Running|越野跑|越野跑|越野跑
sports.marathon|sports|running|106|Marathon|馬拉松|马拉松|馬拉松;马拉松
sports.sprinting|sports|running|107|Sprinting|短跑|短跑|
sports.track_and_field|sports|running|108|Track & Field|田徑|田径|athletics
sports.orienteering|sports|running|109|Orienteering|定向越野|定向越野|
sports.race_walking|sports|running|110|Race Walking|競步|竞走|
gaming.chess|sports|mind_sports|120|Chess|國際象棋|国际象棋|國際象棋;国际象棋
gaming.go|sports|mind_sports|121|Go / Weiqi|圍棋|围棋|圍棋;围棋
gaming.xiangqi|sports|mind_sports|122|Chinese Chess|象棋|象棋|象棋
gaming.mahjong|sports|mind_sports|123|Mahjong|麻雀|麻将|麻雀;麻將;麻将
gaming.poker|sports|mind_sports|124|Poker|撲克|扑克|
gaming.bridge|sports|mind_sports|125|Bridge|橋牌|桥牌|
sports.skateboarding|sports|skating|130|Skateboarding|滑板|滑板|
sports.roller_skating|sports|skating|131|Roller Skating|滾軸溜冰|轮滑|
sports.inline_skating|sports|skating|132|Inline Skating|直排輪|直排轮滑|
outdoors.backpacking|outdoors|hiking|140|Backpacking|背包徒步|背包徒步|
outdoors.mountaineering|outdoors|hiking|141|Mountaineering|登山|登山|
outdoors.rock_climbing|outdoors|hiking|142|Rock Climbing|攀石|攀岩|climbing
outdoors.bouldering|outdoors|hiking|143|Bouldering|抱石|抱石|
outdoors.via_ferrata|outdoors|hiking|144|Via Ferrata|鐵索攀岩|铁索攀岩|
outdoors.canyoning|outdoors|hiking|145|Canyoning|溪降|溪降|
outdoors.geocaching|outdoors|hiking|146|Geocaching|地理藏寶|地理寻宝|
outdoors.nature_walks|outdoors|hiking|147|Nature Walks|自然散步|自然漫步|
outdoors.birdwatching|outdoors|hiking|148|Birdwatching|觀鳥|观鸟|
outdoors.stargazing|outdoors|hiking|149|Stargazing|觀星|观星|
outdoors.glamping|outdoors|camping|155|Glamping|豪華露營|豪华露营|
outdoors.bushcraft|outdoors|camping|156|Bushcraft|荒野技能|荒野技能|
outdoors.van_life|outdoors|camping|157|Van Life|露營車生活|房车生活|
outdoors.campervans|outdoors|camping|158|Campervans|露營車|房车|
outdoors.picnics|outdoors|camping|159|Picnics|野餐|野餐|
outdoors.mountain_biking|outdoors|cycling|165|Mountain Biking|山地單車|山地自行车|
outdoors.road_cycling|outdoors|cycling|166|Road Cycling|公路單車|公路自行车|
outdoors.bmx|outdoors|cycling|167|BMX|BMX 小輪車|BMX 小轮车|
outdoors.bikepacking|outdoors|cycling|168|Bikepacking|單車露營|骑行露营|
outdoors.fixed_gear_cycling|outdoors|cycling|169|Fixed Gear Cycling|固定齒輪單車|固定齿轮自行车|
outdoors.swimming|outdoors|water|175|Swimming|游泳|游泳|游泳
outdoors.surfing|outdoors|water|176|Surfing|滑浪|冲浪|滑浪;衝浪
outdoors.scuba_diving|outdoors|water|177|Scuba Diving|水肺潛水|水肺潜水|潛水;潜水
outdoors.freediving|outdoors|water|178|Freediving|自由潛水|自由潜水|自由潛水;自由潜水
outdoors.snorkeling|outdoors|water|179|Snorkeling|浮潛|浮潜|浮潛;浮潜
outdoors.kayaking|outdoors|water|180|Kayaking|獨木舟|皮划艇|獨木舟;皮划艇
outdoors.canoeing|outdoors|water|181|Canoeing|加拿大式獨木舟|加拿大式划艇|canoe
outdoors.sailing|outdoors|water|182|Sailing|帆船|帆船|帆船
outdoors.stand_up_paddleboarding|outdoors|water|183|Stand-up Paddleboarding|直立板|桨板|sup
outdoors.windsurfing|outdoors|water|184|Windsurfing|滑浪風帆|帆板|
outdoors.kitesurfing|outdoors|water|185|Kitesurfing|風箏滑浪|风筝冲浪|
outdoors.rowing|outdoors|water|186|Rowing|賽艇|赛艇|
outdoors.dragon_boat|outdoors|water|187|Dragon Boat|龍舟|龙舟|龍舟;龙舟
outdoors.wakeboarding|outdoors|water|188|Wakeboarding|花式滑水|尾波滑水|
outdoors.water_skiing|outdoors|water|189|Water Skiing|滑水|滑水|
outdoors.skiing|outdoors|winter|195|Skiing|滑雪|滑雪|滑雪
outdoors.snowboarding|outdoors|winter|196|Snowboarding|單板滑雪|单板滑雪|單板滑雪;单板滑雪
outdoors.ice_skating|outdoors|winter|197|Ice Skating|溜冰|滑冰|溜冰
outdoors.figure_skating|outdoors|winter|198|Figure Skating|花式溜冰|花样滑冰|花式溜冰;花样滑冰
outdoors.ice_hockey|outdoors|winter|199|Ice Hockey|冰球|冰球|冰球
outdoors.snowshoeing|outdoors|winter|200|Snowshoeing|雪鞋健行|雪鞋徒步|
wellness.weightlifting|wellness|fitness|210|Weightlifting|舉重|举重|舉重;举重
wellness.bodybuilding|wellness|fitness|211|Bodybuilding|健美|健美|健美
wellness.calisthenics|wellness|fitness|212|Calisthenics|自重訓練|自重训练|街頭健身;街头健身
wellness.crossfit|wellness|fitness|213|CrossFit|CrossFit|CrossFit|
wellness.hiit|wellness|fitness|214|HIIT|高強度間歇訓練|高强度间歇训练|
wellness.pilates|wellness|fitness|215|Pilates|普拉提|普拉提|普拉提
wellness.yoga|wellness|fitness|216|Yoga|瑜伽|瑜伽|瑜伽
wellness.stretching|wellness|fitness|217|Stretching|拉筋|拉伸|拉筋
wellness.mobility|wellness|fitness|218|Mobility Training|活動度訓練|活动度训练|
wellness.spin_class|wellness|fitness|219|Spin Class|室內單車課|动感单车课|indoor cycling;spinning;stationary bike
wellness.aerobics|wellness|fitness|220|Aerobics|健身操|健身操|
wellness.dance_fitness|wellness|fitness|221|Dance Fitness|舞蹈健身|舞蹈健身|zumba
wellness.jump_rope|wellness|fitness|222|Jump Rope|跳繩|跳绳|跳繩;跳绳
wellness.meditation|wellness|mind_body|230|Meditation|冥想|冥想|冥想
wellness.mindfulness|wellness|mind_body|231|Mindfulness|正念|正念|正念
wellness.breathwork|wellness|mind_body|232|Breathwork|呼吸練習|呼吸练习|呼吸練習;呼吸练习
wellness.sleep|wellness|mind_body|233|Sleep Optimization|睡眠改善|睡眠优化|
wellness.sauna|wellness|mind_body|234|Sauna|桑拿|桑拿|桑拿
wellness.cold_plunge|wellness|mind_body|235|Cold Plunge|冷水浸浴|冷水浸泡|''');
