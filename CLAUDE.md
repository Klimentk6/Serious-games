# CLAUDE.md

Курсов проект №46 „Каталог на сериозни видеоигри - 2“ по „XML технологии за семантичен уеб“ (СУ, ФМИ, зимен семестър 2026/2027).
Предишна година е правен подобен проект: `../example_project` (тема 2, „Каталог на хотели“). Използва се като образец за стил и технологии.

## Изискване (тема 46, `../XML_теми за проект_20261004.pdf`)
Каталог на сериозни видеоигри, базиран на XML с текстово и графично съдържание.
- Графиката е чрез **XML entities** (unparsed `ENTITY` + `NDATA`, декларирани в `DOCTYPE`).
- Връзките (игри↔таксономията на Sawyer & Smith, игри↔свързани игри и др.) са чрез **(съставни) ключове и референции**: `xs:key` / `xs:keyref`. НЕ с ID/IDREF (това е тема 45).
- 7–8 игри, валидирани с **XML Schema** (XSD, не DTD).
- Показване в HTML браузър чрез **CSS + XSLT**, със **сортиране по няколко признака** (сектор и цел; заглавие; година).
- Ресурси: Sawyer & Smith serious-games taxonomy; „Serious Games for and as Cultural Heritage“.

## Файлове
| Файл | Роля |
|---|---|
| `games.xml` | Данни. Вътрешен `DOCTYPE` с entities за картинките, `<?xml-stylesheet href="games.xsl"?>`, `xsi:noNamespaceSchemaLocation="games.xsd"` |
| `games.xsd` | Схема + всички ключове и референции (дефинирани върху корена `catalogue`) |
| `games.xsl` | XSLT 1.0 (изисква се от `XSLTProcessor` в браузъра). Генерира HTML и свързва `styles.css` чрез `<link>` |
| `styles.css` | Целият CSS. Темата изисква „CSS и XSLT“, затова стиловете са в отделен файл, а не вградени в XSL |

## Модел на данните
`catalogue` → `taxonomy` (`source`, `sectors`, `purposes`, `classifications`) → `developers` → `platforms` → `games`.
- **Оси на таксономията (по слайда „Taxonomy of Serious Games“, Sawyer & Smith 2008):** редове = **Sector** (Government & NGO, Defense, Healthcare, Marketing & Communications, Education, Corporate, Industry), колони = **Purpose** (Games for Health, Advergames, Games for Training, Games for Education, Games for Science and Research, Production, Games as Work). Потребителят избра имената Sector/Purpose (алтернативи: Industry/Market/Domain и Goal/Application).
- **`classifications` съдържа всичките 49 клетки (7×7)** с текста от слайда в `<label>` (напр. Defense × Advergames = „Recruitment & Propaganda“). XSD изисква точно 49.
- **Съставен ключ** `classificationKey` = `(@sector, @purpose)`. **Съставна референция** `gameClassificationRef`: `game/@sector + game/@purpose` → `classificationKey`.
- **Съставен ключ** `gameKey` = `(title, year)`. **Съставна референция** `relatedGameRef`: `game/related/game/@title + @year` → `gameKey` („See also“).
- Прости ключове: `sectorKey`, `purposeKey` (от `classification/@sector|@purpose`), `developerKey`←`game/@developer`, `platformKey`←`game/platforms/platform/@ref`.
- `game/@id` е `xs:ID` и се ползва само от JS (`showGame(id)`), не за връзките.
- **Няма жанрове и няма „market“ като отделна ос.** Потребителят замени тип+жанр със Sector×Purpose. Идентификаторите на разработчик/платформа са `[a-z][a-z0-9-]*`.

## Игри (8)
| Игра | Sector × Purpose | Клетка от слайда |
|---|---|---|
| Civilization IV | Education × Games for Education | Learning |
| Assassin's Creed II | Education × Games for Education | Learning |
| Brain Age | Healthcare × Games for Health | Cybertherapy / Exergaming |
| Dance Dance Revolution | Healthcare × Games for Health | Cybertherapy / Exergaming |
| America's Army | Defense × Advergames | Recruitment & Propaganda |
| Full Spectrum Warrior | Defense × Games for Training | Soldier/Support Training |
| The Movies | Marketing & Communications × Production | Machinima |
| Foldit | Healthcare × Games for Science and Research | Visualization & Epidemiology (в презентацията там стои Folding@Home) |

Източници: Civilization IV, Brain Age, DDR, America's Army, The Movies са в презентацията на Sawyer & Smith (слайдове 32, 34, 38, 40, 43); Assassin's Creed II е в статията на Бончев (3.1); Full Spectrum Warrior и Foldit са извън двата източника. Заети са 4 от 7 сектора и 6 от 7 цели (няма игри за Government & NGO, Corporate, Industry и Games as Work).

## Как работи XSLT-ът
- Параметри: `loadDocument`, `showAll`, `showId`, `sortOn`, `sortOrder`, `sortType`, `filterSector`, `filterPurpose`. Два изгледа: списък с карти и детайли за игра. (Изгледът „Taxonomy matrix“ е премахнат по искане на потребителя; 49-те клетки остават в XML-а и се ползват за текста „Taxonomy cell“ в детайлите.)
- Първото зареждане е директно от браузъра през PI (`loadDocument=true`) и излъчва цялата страница. После вграденият JS взема `games.xsl` и `games.xml` чрез `fetch`, пуска `XSLTProcessor` с `loadDocument=false` и подменя само `#content`.
- Сортирането е по **два ключа**: избраният (`<xsl:sort select="@*[name()=$sortOn] | *[name()=$sortOn]">`, работи за елементи и атрибути: `sector`, `purpose`, `title`, `year`) и втори (`$secondary`: sector→purpose, purpose→sector, иначе title). Стойностите на `sector`/`purpose` са самите имена, затова редът е азбучен.
- XSL ключовете `classificationByPair` (`concat(@sector,'|',@purpose)`) и `gameByTitleYear` огледално повтарят съставните ключове от XSD.
- Картинки: шаблонът пише `src="{@source}"` (името на entity). Скриптът `imageUrlsMap` (генериран с `unparsed-entity-uri`) подменя името с реалния път. След `DOMParser` информацията за entities се губи, затова този трик е необходим.
- JS в XSL е в `CDATA`, за да няма проблем със символите `<` и `&`.

## Команди
```bash
# Валидация
xmllint --noout --schema games.xsd games.xml

# Стартиране (fetch и XSL не работят през file://, нужен е сървър)
python3 -m http.server 8080      # после http://localhost:8080/games.xml

# Бърз тест на трансформацията без браузър
xsltproc games.xsl games.xml
xsltproc --stringparam loadDocument false --stringparam sortOn purpose games.xsl games.xml
```
Chrome/Opera не зареждат XSL от `file://`, затова се ползва dev сървър (както в `example_project`).

## Конвенции и бележки
- Съдържанието и интерфейсът са на **английски** (както в образеца); документацията е на **български**.
- Данните за игрите са кратко описание по обществено известна информация. Преди предаване ги сверете с официалните сайтове (особено години и платформи).
- **Снимки: само външни адреси, нищо не е изтеглено локално** (няма папка `images/`). Всеки `<!ENTITY име SYSTEM "https://…" NDATA jpeg|png>` в `DOCTYPE` сочи към Wikimedia Commons или Wikipedia, точно както `example_project` сочи към `cf.bstatic.com`. Нужен е интернет; без него `onerror` скрива счупената картинка, а останалото работи.
- Всеки `cover` има `alt` и `credit` (автор · източник · лиценз), който се показва под снимката в детайлния изглед и като `title` в картата.
- Бележки за конкретни снимки: Civilization IV, Assassin's Creed II, Brain Age, Full Spectrum Warrior и The Movies са non-free кутии от Wikipedia (ползвани за идентификация); America's Army е public domain, Dance Dance Revolution е CC0 (снимка на аркаден автомат, не кутия), Foldit е CC BY-SA 3.0 de.
- Нова снимка: `<!ENTITY име SYSTEM "url" NDATA jpeg>` + `<cover source="име" alt="…" credit="…"/>` (за `gallery/image` важи същото).
- Не е проверявано в Firefox/Safari. Firefox няма `unparsed-entity-uri` при някои режими, затова се ползва `imageUrlsMap`.

## Остава
- Документация (PDF) по структурата на `../example_project/Документация.pdf`: въведение, анализ, дизайн (XSD/XML/XSL), тестване, заключение, разпределение на работата, литература.
- Име на предаването по шаблона `XML2026_projectNo_studentNames_facNos` (`../XML2026_projectNo_studentNames_facNos-template.doc`). Имената и факултетните номера трябва да се попълнят от авторите.
