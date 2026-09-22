/// Learning localization batch A.
/// Reading, books, and book subgenres.
/// Format: id|es|fr|pt|ja|ko
const String kInterestLocaleLearningARaw = r'''books.reading|Lectura|Lecture|Leitura|読書|독서
learning.biographies|Biografías|Biographies|Biografias|伝記|전기
learning.book_clubs|Clubes de lectura|Clubs de lecture|Clubes de leitura|読書会|독서 모임
learning.book_genre.adventure_fiction|Ficción de aventuras|Romans d'aventure|Ficção de aventura|冒険小説|모험 소설
learning.book_genre.alternate_history_books|Historia alternativa|Uchronie|História alternativa|架空歴史小説|대체역사 소설
learning.book_genre.architecture_books|Libros de arquitectura|Livres d'architecture|Livros de arquitetura|建築書|건축 서적
learning.book_genre.art_books|Libros de arte|Livres d'art|Livros de arte|美術書|예술 서적
learning.book_genre.audiobooks|Audiolibros|Livres audio|Audiolivros|オーディオブック|오디오북
learning.book_genre.autobiography|Autobiografía|Autobiographie|Autobiografia|自伝|자서전
learning.book_genre.body_horror_books|Terror corporal|Horreur corporelle|Terror corporal|ボディホラー小説|바디 호러 소설
learning.book_genre.book_blogging|Blogs de libros|Blogs littéraires|Blogs de livros|書評ブログ|책 블로그
learning.book_genre.book_collecting|Coleccionismo de libros|Collection de livres|Coleção de livros|書籍収集|책 수집
learning.book_genre.bookstagram|Bookstagram|Bookstagram|Bookstagram|Bookstagram|북스타그램
learning.book_genre.booktok|BookTok|BookTok|BookTok|BookTok|북톡
learning.book_genre.booktube|BookTube|BookTube|BookTube|BookTube|북튜브
learning.book_genre.business_fiction|Ficción empresarial|Fiction d'entreprise|Ficção empresarial|ビジネス小説|비즈니스 소설
learning.book_genre.campus_novels|Novelas de campus|Romans de campus|Romances de campus|学園小説|캠퍼스 소설
learning.book_genre.childrens_classics|Clásicos infantiles|Classiques jeunesse|Clássicos infantis|児童文学の名作|아동 고전
learning.book_genre.classics|Clásicos|Classiques|Clássicos|古典文学|고전 문학
learning.book_genre.climate_fiction|Ficción climática|Fiction climatique|Ficção climática|気候フィクション|기후 소설
learning.book_genre.coming_of_age_fiction|Novelas de formación|Romans d'apprentissage|Romances de formação|成長小説|성장 소설
learning.book_genre.contemporary_fiction|Ficción contemporánea|Fiction contemporaine|Ficção contemporânea|現代小説|현대 소설
learning.book_genre.contemporary_romance|Romance contemporáneo|Romance contemporaine|Romance contemporâneo|現代恋愛小説|현대 로맨스
learning.book_genre.cosmic_horror|Terror cósmico|Horreur cosmique|Terror cósmico|コズミックホラー|코스믹 호러
learning.book_genre.cozy_mystery_books|Misterio acogedor|Cosy mystery|Mistério aconchegante|コージーミステリー|코지 미스터리
learning.book_genre.crime_fiction|Novela criminal|Roman policier|Ficção criminal|犯罪小説|범죄 소설
learning.book_genre.cyberpunk_books|Libros cyberpunk|Livres cyberpunk|Livros cyberpunk|サイバーパンク小説|사이버펑크 소설
learning.book_genre.dark_fantasy_books|Fantasía oscura|Dark fantasy|Fantasia sombria|ダークファンタジー|다크 판타지
learning.book_genre.dark_romance_books|Romance oscuro|Dark romance|Romance sombrio|ダークロマンス|다크 로맨스
learning.book_genre.design_books|Libros de diseño|Livres de design|Livros de design|デザイン書|디자인 서적
learning.book_genre.detective_fiction|Ficción detectivesca|Roman de détective|Ficção de detetive|探偵小説|탐정 소설
learning.book_genre.domestic_fiction|Ficción doméstica|Fiction domestique|Ficção doméstica|家庭小説|가정 소설
learning.book_genre.domestic_thrillers|Thrillers domésticos|Thrillers domestiques|Thrillers domésticos|家庭サスペンス|가정 스릴러
learning.book_genre.dystopian_fiction|Ficción distópica|Fiction dystopique|Ficção distópica|ディストピア小説|디스토피아 소설
learning.book_genre.e_books|Libros electrónicos|Livres numériques|E-books|電子書籍|전자책
learning.book_genre.economics_books|Libros de economía|Livres d'économie|Livros de economia|経済学書|경제학 서적
learning.book_genre.epic_fantasy|Fantasía épica|Fantasy épique|Fantasia épica|エピックファンタジー|에픽 판타지
learning.book_genre.epistolary_novels|Novelas epistolares|Romans épistolaires|Romances epistolares|書簡体小説|서간체 소설
learning.book_genre.espionage_thrillers|Thrillers de espionaje|Thrillers d'espionnage|Thrillers de espionagem|スパイスリラー|첩보 스릴러
learning.book_genre.essays|Ensayos|Essais|Ensaios|エッセイ|에세이
learning.book_genre.european_comics|Cómics europeos|Bandes dessinées européennes|Banda desenhada europeia|ヨーロッパ漫画|유럽 만화
learning.book_genre.experimental_fiction|Ficción experimental|Fiction expérimentale|Ficção experimental|実験小説|실험 소설
learning.book_genre.fairy_tale_retellings|Reescrituras de cuentos de hadas|Réécritures de contes|Releituras de contos de fadas|童話リテリング|동화 재해석
learning.book_genre.family_saga|Saga familiar|Saga familiale|Saga familiar|家族サーガ|가족 대하소설
learning.book_genre.fantasy_romance|Romance fantástico|Romantasy|Romance de fantasia|ファンタジーロマンス|판타지 로맨스
learning.book_genre.film_books|Libros de cine|Livres sur le cinéma|Livros de cinema|映画書|영화 서적
learning.book_genre.first_contact_fiction|Ficción de primer contacto|Fiction de premier contact|Ficção de primeiro contacto|ファーストコンタクトSF|퍼스트 콘택트 소설
learning.book_genre.folk_horror_books|Terror folclórico|Folk horror|Terror folclórico|フォークホラー小説|포크 호러 소설
learning.book_genre.food_writing|Escritura gastronómica|Écriture culinaire|Escrita gastronómica|食文化エッセイ|음식 글쓰기
learning.book_genre.ghost_stories|Historias de fantasmas|Histoires de fantômes|Histórias de fantasmas|怪談|유령 이야기
learning.book_genre.gothic_horror|Terror gótico|Horreur gothique|Terror gótico|ゴシックホラー|고딕 호러
learning.book_genre.graphic_novels|Novelas gráficas|Romans graphiques|Romances gráficos|グラフィックノベル|그래픽 노블
learning.book_genre.hard_boiled_mystery|Misterio hard-boiled|Polar hard-boiled|Mistério hard-boiled|ハードボイルド・ミステリー|하드보일드 미스터리
learning.book_genre.hard_science_fiction|Ciencia ficción dura|Science-fiction dure|Ficção científica hard|ハードSF|하드 SF
learning.book_genre.high_fantasy|Alta fantasía|High fantasy|Alta fantasia|ハイファンタジー|하이 판타지
learning.book_genre.historical_fiction|Ficción histórica|Fiction historique|Ficção histórica|歴史小説|역사 소설
learning.book_genre.historical_mysteries|Misterios históricos|Mystères historiques|Mistérios históricos|歴史ミステリー|역사 미스터리
learning.book_genre.historical_romance_books|Romance histórico|Romance historique|Romance histórico|歴史ロマンス|역사 로맨스
learning.book_genre.history_books|Libros de historia|Livres d'histoire|Livros de história|歴史書|역사 서적
learning.book_genre.horror_fiction|Ficción de terror|Fiction d'horreur|Ficção de terror|ホラー小説|공포 소설
learning.book_genre.humorous_fiction|Ficción humorística|Fiction humoristique|Ficção humorística|ユーモア小説|유머 소설
learning.book_genre.independent_bookstores|Librerías independientes|Librairies indépendantes|Livrarias independentes|独立系書店|독립서점
learning.book_genre.independent_comics|Cómics independientes|BD indépendantes|Banda desenhada independente|インディーコミック|인디 만화
learning.book_genre.investing_books|Libros de inversión|Livres d'investissement|Livros de investimento|投資書|투자 서적
learning.book_genre.leadership_books|Libros de liderazgo|Livres sur le leadership|Livros de liderança|リーダーシップ書|리더십 서적
learning.book_genre.legal_fiction|Ficción jurídica|Fiction juridique|Ficção jurídica|法律小説|법률 소설
learning.book_genre.legal_thrillers|Thrillers jurídicos|Thrillers juridiques|Thrillers jurídicos|リーガルスリラー|법정 스릴러
learning.book_genre.library_visits|Visitas a bibliotecas|Visites de bibliothèques|Visitas a bibliotecas|図書館巡り|도서관 방문
learning.book_genre.literary_criticism|Crítica literaria|Critique littéraire|Crítica literária|文芸批評|문학 비평
learning.book_genre.literary_fiction|Ficción literaria|Fiction littéraire|Ficção literária|純文学・文芸小説|문학 소설
learning.book_genre.litrpg|LitRPG|LitRPG|LitRPG|LitRPG|LitRPG
learning.book_genre.locked_room_mystery|Misterio de habitación cerrada|Mystère en chambre close|Mistério de quarto fechado|密室ミステリー|밀실 미스터리
learning.book_genre.low_fantasy|Baja fantasía|Low fantasy|Baixa fantasia|ローファンタジー|로우 판타지
learning.book_genre.magical_realism|Realismo mágico|Réalisme magique|Realismo mágico|マジックリアリズム|마술적 사실주의
learning.book_genre.management_books|Libros de gestión|Livres de management|Livros de gestão|経営書|경영 서적
learning.book_genre.manga_reading|Lectura de manga|Lecture de manga|Leitura de manga|漫画読書|만화 읽기
learning.book_genre.manhwa_reading|Lectura de manhwa|Lecture de manhwa|Leitura de manhwa|韓国漫画を読む|한국 만화 읽기
learning.book_genre.marketing_books|Libros de marketing|Livres de marketing|Livros de marketing|マーケティング書|마케팅 서적
learning.book_genre.medical_fiction|Ficción médica|Fiction médicale|Ficção médica|医療小説|의학 소설
learning.book_genre.memoirs|Memorias|Mémoires|Memórias|回想録|회고록
learning.book_genre.middle_grade_fiction|Ficción middle grade|Romans jeunesse middle grade|Ficção middle grade|児童向けミドルグレード小説|미들그레이드 소설
learning.book_genre.military_science_fiction|Ciencia ficción militar|Science-fiction militaire|Ficção científica militar|ミリタリーSF|밀리터리 SF
learning.book_genre.modern_classics|Clásicos modernos|Classiques modernes|Clássicos modernos|近現代の名作|현대 고전
learning.book_genre.music_books|Libros de música|Livres sur la musique|Livros de música|音楽書|음악 서적
learning.book_genre.mythic_fantasy|Fantasía mitológica|Fantasy mythique|Fantasia mitológica|神話ファンタジー|신화 판타지
learning.book_genre.nature_writing|Escritura sobre naturaleza|Écriture de la nature|Escrita sobre natureza|ネイチャーライティング|자연 글쓰기
learning.book_genre.noir_fiction|Novela negra|Roman noir|Ficção noir|ノワール小説|누아르 소설
learning.book_genre.novellas|Novelas cortas|Novellas|Novelas curtas|中編小説|중편소설
learning.book_genre.occult_fiction|Ficción ocultista|Fiction occulte|Ficção ocultista|オカルト小説|오컬트 소설
learning.book_genre.personal_finance_books|Libros de finanzas personales|Livres de finances personnelles|Livros de finanças pessoais|個人金融書|개인 재무 서적
learning.book_genre.philosophy_books|Libros de filosofía|Livres de philosophie|Livros de filosofia|哲学書|철학 서적
learning.book_genre.picture_books|Libros ilustrados|Albums jeunesse|Livros ilustrados|絵本|그림책
learning.book_genre.poetry_collections|Poemarios|Recueils de poésie|Coletâneas de poesia|詩集|시집
learning.book_genre.police_procedural_books|Novelas de procedimiento policial|Romans de procédure policière|Romances policiais processuais|警察小説|경찰 수사 소설
learning.book_genre.political_fiction|Ficción política|Fiction politique|Ficção política|政治小説|정치 소설
learning.book_genre.popular_science_books|Libros de divulgación científica|Livres de vulgarisation scientifique|Livros de divulgação científica|科学読み物|과학 교양서
learning.book_genre.post_apocalyptic_fiction|Ficción posapocalíptica|Fiction post-apocalyptique|Ficção pós-apocalíptica|ポストアポカリプス小説|포스트아포칼립스 소설
learning.book_genre.productivity_books|Libros de productividad|Livres de productivité|Livros de produtividade|生産性向上書|생산성 서적
learning.book_genre.programming_books|Libros de programación|Livres de programmation|Livros de programação|プログラミング書|프로그래밍 서적
learning.book_genre.progression_fantasy|Fantasía de progresión|Progression fantasy|Fantasia de progressão|成長型ファンタジー|성장형 판타지
learning.book_genre.psychological_thrillers|Thrillers psicológicos|Thrillers psychologiques|Thrillers psicológicos|心理スリラー|심리 스릴러
learning.book_genre.psychology_books|Libros de psicología|Livres de psychologie|Livros de psicologia|心理学書|심리학 서적
learning.book_genre.queer_romance|Romance queer|Romance queer|Romance queer|クィア・ロマンス|퀴어 로맨스
learning.book_genre.rare_books|Libros raros|Livres rares|Livros raros|希少本|희귀 서적
learning.book_genre.romantic_comedy_books|Comedia romántica|Comédie romantique|Comédia romântica|ラブコメ小説|로맨틱 코미디 소설
learning.book_genre.romantic_fantasy_books|Fantasía romántica|Fantasy romantique|Fantasia romântica|ロマンティックファンタジー|로맨틱 판타지
learning.book_genre.satirical_fiction|Ficción satírica|Fiction satirique|Ficção satírica|風刺小説|풍자 소설
learning.book_genre.science_writing|Escritura científica|Écriture scientifique|Escrita científica|科学ライティング|과학 글쓰기
learning.book_genre.sea_fiction|Ficción marítima|Fiction maritime|Ficção marítima|海洋小説|해양 소설
learning.book_genre.second_hand_bookstores|Librerías de segunda mano|Librairies d'occasion|Livrarias em segunda mão|古書店|헌책방
learning.book_genre.short_stories|Cuentos|Nouvelles|Contos|短編小説|단편소설
learning.book_genre.solarpunk|Solarpunk|Solarpunk|Solarpunk|ソーラーパンク|솔라펑크
learning.book_genre.space_opera_books|Ópera espacial|Space opera|Ópera espacial|スペースオペラ|스페이스 오페라
learning.book_genre.sports_romance|Romance deportivo|Romance sportive|Romance desportivo|スポーツロマンス|스포츠 로맨스
learning.book_genre.spy_fiction|Ficción de espías|Roman d'espionnage|Ficção de espionagem|スパイ小説|스파이 소설
learning.book_genre.startup_books|Libros sobre startups|Livres sur les start-up|Livros sobre startups|スタートアップ書|스타트업 서적
learning.book_genre.superhero_comics|Cómics de superhéroes|Comics de super-héros|Banda desenhada de super-heróis|スーパーヒーローコミック|슈퍼히어로 만화
learning.book_genre.sword_and_sorcery_books|Espada y brujería|Sword and sorcery|Espada e feitiçaria|剣と魔法小説|검과 마법 소설
learning.book_genre.techno_thrillers|Tecno-thrillers|Techno-thrillers|Techno-thrillers|テクノスリラー|테크노 스릴러
learning.book_genre.technology_books|Libros de tecnología|Livres de technologie|Livros de tecnologia|テクノロジー書|기술 서적
learning.book_genre.time_travel_fiction|Ficción de viajes en el tiempo|Fiction de voyage dans le temps|Ficção de viagem no tempo|タイムトラベル小説|시간여행 소설
learning.book_genre.travel_writing|Literatura de viajes|Récits de voyage|Literatura de viagem|紀行文|여행 글쓰기
learning.book_genre.true_crime_books|Libros de crímenes reales|Livres de true crime|Livros de true crime|実録犯罪本|실화 범죄 서적
learning.book_genre.urban_fantasy_books|Fantasía urbana|Fantasy urbaine|Fantasia urbana|アーバンファンタジー|어반 판타지
learning.book_genre.vampire_fiction|Ficción de vampiros|Fiction de vampires|Ficção de vampiros|吸血鬼小説|뱀파이어 소설
learning.book_genre.war_fiction|Ficción bélica|Fiction de guerre|Ficção de guerra|戦争小説|전쟁 소설
learning.book_genre.webtoon_reading|Lectura de webtoons|Lecture de webtoons|Leitura de webtoons|ウェブトゥーン読書|웹툰 읽기
learning.book_genre.western_fiction|Ficción del Oeste|Western|Ficção de faroeste|西部劇小説|서부 소설
learning.book_genre.womens_fiction|Ficción femenina|Fiction féminine|Ficção feminina|女性向け文芸|여성 소설
learning.book_genre.ya_fantasy|Fantasía juvenil|Fantasy young adult|Fantasia jovem adulta|YAファンタジー|YA 판타지
learning.book_genre.ya_romance|Romance juvenil|Romance young adult|Romance jovem adulto|YAロマンス|YA 로맨스
learning.book_genre.young_adult_fiction|Ficción juvenil|Fiction young adult|Ficção jovem adulta|ヤングアダルト小説|청소년 소설
learning.book_genre.zombie_fiction|Ficción de zombis|Fiction de zombies|Ficção de zombies|ゾンビ小説|좀비 소설
learning.business_books|Libros de negocios|Livres de business|Livros de negócios|ビジネス書|비즈니스 서적
learning.fantasy_books|Libros de fantasía|Livres de fantasy|Livros de fantasia|ファンタジー小説|판타지 소설
learning.fiction|Ficción|Fiction|Ficção|小説|소설
learning.mystery_books|Libros de misterio y crimen|Polars et romans criminels|Livros de mistério e crime|ミステリー・犯罪小説|미스터리·범죄 소설
learning.nonfiction|No ficción|Non-fiction|Não ficção|ノンフィクション|논픽션
learning.poetry|Poesía|Poésie|Poesia|詩|시
learning.romance_books|Novelas románticas|Romans d'amour|Romances|恋愛小説|로맨스 소설
learning.science_fiction_books|Libros de ciencia ficción|Livres de science-fiction|Livros de ficção científica|SF小説|SF 소설
learning.self_improvement|Libros de superación personal|Livres de développement personnel|Livros de desenvolvimento pessoal|自己啓発書|자기계발서''';
