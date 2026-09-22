/// Learning localization batch B.
/// Languages, campus, history, and knowledge topics.
/// Format: id|es|fr|pt|ja|ko
const String kInterestLocaleLearningBRaw = r'''history.general|Historia|Histoire|História|歴史|역사
learning.academic_competitions|Competiciones académicas|Concours académiques|Competições académicas|学術コンテスト|학술 대회
learning.anthropology|Antropología|Anthropologie|Antropologia|人類学|인류학
learning.archaeology|Arqueología|Archéologie|Arqueologia|考古学|고고학
learning.architecture|Arquitectura|Architecture|Arquitetura|建築|건축
learning.brain_teasers|Acertijos mentales|Casse-têtes|Desafios mentais|脳トレ問題|두뇌 퍼즐
learning.campus_events|Eventos universitarios|Événements sur le campus|Eventos universitários|キャンパスイベント|캠퍼스 행사
learning.campus_radio|Radio universitaria|Radio étudiante|Rádio universitária|学生ラジオ|대학 라디오
learning.cantonese|Cantonés|Cantonais|Cantonês|広東語|광둥어
learning.debating|Debate|Débat|Debate|ディベート|토론
learning.economics|Economía|Économie|Economia|経済学|경제학
learning.english|Inglés|Anglais|Inglês|英語|영어
learning.entrepreneurship|Emprendimiento|Entrepreneuriat|Empreendedorismo|起業|창업
learning.exchange_programs|Programas de intercambio|Programmes d'échange|Programas de intercâmbio|交換留学|교환학생 프로그램
learning.french|Francés|Français|Francês|フランス語|프랑스어
learning.genealogy|Genealogía|Généalogie|Genealogia|系譜学|족보 연구
learning.geography|Geografía|Géographie|Geografia|地理|지리
learning.german|Alemán|Allemand|Alemão|ドイツ語|독일어
learning.investing|Inversión|Investissement|Investimento|投資|투자
learning.italian|Italiano|Italien|Italiano|イタリア語|이탈리아어
learning.japanese|Japonés|Japonais|Japonês|日本語|일본어
learning.jigsaw_puzzles|Puzles|Puzzles|Puzzles|ジグソーパズル|직소 퍼즐
learning.korean|Coreano|Coréen|Coreano|韓国語|한국어
learning.language_exchange|Intercambio de idiomas|Échange linguistique|Intercâmbio linguístico|言語交換|언어 교환
learning.languages|Aprendizaje de idiomas|Apprentissage des langues|Aprendizagem de línguas|語学学習|언어 학습
learning.law|Derecho|Droit|Direito|法律|법률
learning.linguistics|Lingüística|Linguistique|Linguística|言語学|언어학
learning.local_history|Historia local|Histoire locale|História local|地域史|지역사
learning.logic_puzzles|Puzles de lógica|Puzzles logiques|Puzzles de lógica|論理パズル|논리 퍼즐
learning.mandarin|Chino mandarín|Chinois mandarin|Chinês mandarim|中国語（普通話）|중국어 보통화
learning.math_olympiad|Olimpiada de Matemáticas|Olympiades de mathématiques|Olimpíadas de Matemática|数学オリンピック|수학 올림피아드
learning.math_puzzles|Puzles matemáticos|Puzzles mathématiques|Puzzles de matemática|数学パズル|수학 퍼즐
learning.memory_training|Entrenamiento de memoria|Entraînement de la mémoire|Treino de memória|記憶力トレーニング|기억력 훈련
learning.mentoring|Mentoría|Mentorat|Mentoria|メンタリング|멘토링
learning.mock_trial|Juicio simulado|Procès simulé|Julgamento simulado|模擬裁判|모의재판
learning.model_united_nations|Modelo de Naciones Unidas|Modèle des Nations unies|Modelo das Nações Unidas|模擬国連|모의 유엔
learning.moot_court|Moot Court|Concours de plaidoirie|Moot Court|模擬法廷弁論|모의법정
learning.museum_learning|Aprendizaje en museos|Apprentissage au musée|Aprendizagem em museus|博物館学習|박물관 학습
learning.mythology|Mitología|Mythologie|Mitologia|神話学|신화학
learning.note_taking|Toma de apuntes|Prise de notes|Tirar notas|ノート術|노트 필기
learning.peer_learning|Aprendizaje entre pares|Apprentissage entre pairs|Aprendizagem entre pares|ピアラーニング|동료 학습
learning.personal_development|Desarrollo personal|Développement personnel|Desenvolvimento pessoal|自己成長|자기계발
learning.personal_finance|Finanzas personales|Finances personnelles|Finanças pessoais|個人金融|개인 재무
learning.philosophy|Filosofía|Philosophie|Filosofia|哲学|철학
learning.philosophy_discussions|Debates filosóficos|Discussions philosophiques|Discussões filosóficas|哲学対話|철학 토론
learning.politics|Política y actualidad|Politique et actualité|Política e atualidade|政治・時事|정치·시사
learning.puzzle_hunts|Búsquedas de puzles|Chasses aux énigmes|Caças a puzzles|パズルハント|퍼즐 헌트
learning.science_communication|Divulgación científica|Communication scientifique|Comunicação de ciência|科学コミュニケーション|과학 커뮤니케이션
learning.science_olympiad|Olimpiada de Ciencias|Olympiades de sciences|Olimpíadas de Ciências|科学オリンピック|과학 올림피아드
learning.sign_language|Lengua de signos|Langue des signes|Língua gestual|手話|수어
learning.skill_sharing|Intercambio de habilidades|Partage de compétences|Partilha de competências|スキルシェア|기술 공유
learning.sociology|Sociología|Sociologie|Sociologia|社会学|사회학
learning.spanish|Español|Espagnol|Espanhol|スペイン語|스페인어
learning.speed_reading|Lectura rápida|Lecture rapide|Leitura rápida|速読|속독
learning.student_newspaper|Periódico estudiantil|Journal étudiant|Jornal estudantil|学生新聞|학생 신문
learning.student_societies|Asociaciones estudiantiles|Associations étudiantes|Associações estudantis|学生サークル|학생 동아리
learning.student_volunteering|Voluntariado estudiantil|Bénévolat étudiant|Voluntariado estudantil|学生ボランティア|학생 봉사
learning.study_abroad|Estudiar en el extranjero|Études à l'étranger|Estudar no estrangeiro|海外留学|유학
learning.study_groups|Grupos de estudio|Groupes d'étude|Grupos de estudo|勉強会|스터디 그룹
learning.study_skills|Técnicas de estudio|Méthodes d'étude|Técnicas de estudo|学習スキル|학습 기술
learning.urban_planning|Urbanismo|Urbanisme|Planeamento urbano|都市計画|도시계획
learning.yearbook|Anuario escolar|Album de fin d'année|Anuário escolar|卒業アルバム|졸업 앨범''';
