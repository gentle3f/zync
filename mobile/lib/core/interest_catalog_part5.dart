import 'interest_catalog_parser.dart';
import 'models.dart';

final List<InterestDefinition> kInterestCatalogPart5 = parseInterestCatalogRows(r'''technology.ai|technology|ai|25|Artificial Intelligence|人工智能|人工智能|ai;a.i.;人工智慧
technology.gadgets|technology|gadgets|26|Technology & Gadgets|科技與電子產品|科技与电子产品|gadgets;tech
photography.general|arts|photography|27|Photography|攝影|摄影|photo;拍照
photography.street|arts|photography|28|Street Photography|街頭攝影|街头摄影|street photo
arts.drawing|arts|visual_art|29|Drawing|繪畫|绘画|sketching;畫畫;画画
arts.portrait_photography|arts|photography|550|Portrait Photography|||人像攝影;人像摄影
arts.landscape_photography|arts|photography|551|Landscape Photography|||風景攝影;风景摄影
arts.travel_photography|arts|photography|552|Travel Photography|||旅行攝影;旅行摄影
arts.film_photography|arts|photography|553|Film Photography|||菲林攝影;胶片摄影
arts.wildlife_photography|arts|photography|554|Wildlife Photography|||野生動物攝影;野生动物摄影
arts.architecture_photography|arts|photography|555|Architecture Photography|||建築攝影;建筑摄影
arts.mobile_photography|arts|photography|556|Mobile Photography|||手機攝影;手机摄影
arts.drone_photography|arts|photography|557|Drone Photography|||航拍
arts.photo_editing|arts|photography|558|Photo Editing|||修圖;修图
arts.painting|arts|visual_art|565|Painting|||畫畫;绘画
arts.watercolor|arts|visual_art|566|Watercolor|||水彩
arts.oil_painting|arts|visual_art|567|Oil Painting|||油畫;油画
arts.digital_art|arts|visual_art|568|Digital Art|||數碼藝術;数字艺术
arts.illustration|arts|visual_art|569|Illustration|||插畫;插画
arts.graphic_design|arts|visual_art|570|Graphic Design|||平面設計;平面设计
arts.calligraphy|arts|visual_art|571|Calligraphy|||書法;书法
arts.chinese_calligraphy|arts|visual_art|572|Chinese Calligraphy|||中國書法;中国书法
arts.urban_sketching|arts|visual_art|573|Urban Sketching|||城市速寫;城市速写
arts.street_art|arts|visual_art|574|Street Art|||街頭藝術;街头艺术
arts.sculpture|arts|visual_art|575|Sculpture|||雕塑
arts.ceramics|arts|visual_art|576|Ceramics|||陶瓷
arts.printmaking|arts|visual_art|577|Printmaking|||版畫;版画
crafts.knitting|crafts|crafts|585|Knitting|||編織;编织
crafts.crochet|crafts|crafts|586|Crochet|||鉤針;钩针
crafts.sewing|crafts|crafts|587|Sewing|||縫紉;缝纫
crafts.embroidery|crafts|crafts|588|Embroidery|||刺繡;刺绣
crafts.leathercraft|crafts|crafts|589|Leathercraft|||皮革工藝;皮具制作
crafts.woodworking|crafts|crafts|590|Woodworking|||木工
crafts.jewelry_making|crafts|crafts|591|Jewelry Making|||首飾製作;首饰制作
crafts.candle_making|crafts|crafts|592|Candle Making|||蠟燭製作;蜡烛制作
crafts.soap_making|crafts|crafts|593|Soap Making|||手工皂
crafts.origami|crafts|crafts|594|Origami|||摺紙;折纸
crafts.model_building|crafts|crafts|595|Model Building|||模型製作;模型制作
crafts.miniatures|crafts|crafts|596|Miniatures|||微縮模型;微缩模型
crafts.diy|crafts|crafts|597|DIY Projects|||手作;手工
technology.generative_ai|technology|ai|605|Generative AI|||生成式AI
technology.chatgpt|technology|ai|606|ChatGPT|||
technology.machine_learning|technology|ai|607|Machine Learning|||機器學習;机器学习
technology.robotics|technology|ai|608|Robotics|||機械人;机器人
technology.computer_vision|technology|ai|609|Computer Vision|||電腦視覺;计算机视觉
technology.programming|technology|software|615|Programming|||coding;編程;编程
technology.web_development|technology|software|616|Web Development|||網站開發;网站开发
technology.app_development|technology|software|617|App Development|||app開發;应用开发
technology.python|technology|software|618|Python|||
technology.javascript|technology|software|619|JavaScript|||js
technology.open_source|technology|software|620|Open Source|||開源;开源
technology.cybersecurity|technology|software|621|Cybersecurity|||網絡安全;网络安全
technology.linux|technology|software|622|Linux|||
technology.cloud_computing|technology|software|623|Cloud Computing|||雲端運算;云计算
technology.data_science|technology|software|624|Data Science|||數據科學;数据科学
technology.smartphones|technology|gadgets|630|Smartphones|||手機;手机
technology.android|technology|gadgets|631|Android|||
technology.apple|technology|gadgets|632|Apple Products|||蘋果產品;苹果产品
technology.smart_home|technology|gadgets|633|Smart Home|||智能家居
technology.drones|technology|gadgets|634|Drones|||無人機;无人机
technology.3d_printing|technology|gadgets|635|3D Printing|||3d打印
technology.mechanical_keyboards|technology|gadgets|636|Mechanical Keyboards|||機械鍵盤;机械键盘
technology.headphones|technology|gadgets|637|Headphones & Audio Gear|||耳機;耳机
technology.cameras|technology|gadgets|638|Cameras|||相機;相机
technology.wearables|technology|gadgets|639|Wearable Tech|||穿戴裝置;可穿戴设备
science.astronomy|science|science|645|Astronomy|||天文
science.space|science|science|646|Space Exploration|||太空探索
science.physics|science|science|647|Physics|||物理
science.chemistry|science|science|648|Chemistry|||化學;化学
science.biology|science|science|649|Biology|||生物
science.psychology|science|science|650|Psychology|||心理學;心理学
science.neuroscience|science|science|651|Neuroscience|||神經科學;神经科学
science.geology|science|science|652|Geology|||地質;地质
science.environment|science|science|653|Environmental Science|||環境科學;环境科学
science.medicine|science|science|654|Medicine|||醫學;医学''');
