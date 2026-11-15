# CLAUDE.md

Course project No. 46, "Serious Video Games Catalogue – 2", for the course "XML Technologies for the Semantic Web" (Sofia University, Faculty of Mathematics and Informatics, 2026).

All source files are in `src/`. Everything in this repository (code, comments, documentation) must be written in English.

## Requirements of the assignment
A catalogue of serious video games based on XML with text and graphic content.
- Graphics are represented with **XML entities** (unparsed `ENTITY` + `NDATA`, declared in the `DOCTYPE`).
- Relations (games <-> the Sawyer & Smith taxonomy, games <-> related games, etc.) are described with **(composite) keys and references to them**: `xs:key` / `xs:keyref`. Not with ID/IDREF (that is the other variant of the assignment).
- 7–8 games, validated with an **XML Schema** (XSD, not DTD).
- Shown in an HTML browser with **CSS + XSLT**, with **sorting by several properties** (sector and purpose, title).
- Resources: the Sawyer & Smith serious games taxonomy; "Serious Games for and as Cultural Heritage" (B. Bontchev, 2015).

## Files
| File | Role |
|---|---|
| `src/serious_games.xml` | Data. Internal `DOCTYPE` with the image entities, `<?xml-stylesheet href="serious_games.xsl"?>`, `xsi:noNamespaceSchemaLocation="serious_games.xsd"` |
| `src/serious_games.xsd` | Schema with all keys and references (declared on the root element `catalogue`) |
| `src/serious_games.xsl` | XSLT 1.0 (required by `XSLTProcessor` in browsers). Generates the HTML and links `styles.css` with `<link>` |
| `src/styles.css` | All the CSS. The assignment asks for "CSS and XSLT", so styles are in a separate file and not embedded in the XSL |
| `README.md` | Description of the project and how to run it |

## Data model
`catalogue` -> `taxonomy` (`source`, `sectors`, `purposes`, `classifications`) -> `developers` -> `platforms` -> `games`.
- **Taxonomy axes (from the slide "Taxonomy of Serious Games", Sawyer & Smith 2008):** rows = **Sector** (Government & NGO, Defense, Healthcare, Marketing & Communications, Education, Corporate, Industry), columns = **Purpose** (Games for Health, Advergames, Games for Training, Games for Education, Games for Science and Research, Production, Games as Work). The names Sector/Purpose were chosen by the project owner (alternatives: Industry/Market/Domain and Goal/Application).
- **`classifications` contains all 49 cells (7x7)** with the text of the slide in `<label>` (for example Defense x Advergames = "Recruitment & Propaganda"). The XSD requires exactly 49.
- **Composite key** `classificationKey` = `(@sector, @purpose)`. **Composite reference** `gameClassificationRef`: `game/@sector + game/@purpose` -> `classificationKey`.
- **Composite key** `gameKey` = `(title, year)`. **Composite reference** `relatedGameRef`: `game/related/game/@title + @year` -> `gameKey`. The data and schema keep the references, but the page no longer shows a "See also" list.
- Simple keys: `sectorKey`, `purposeKey` (referenced by `classification/@sector|@purpose`), `developerKey` <- `game/@developer`, `platformKey` <- `game/platforms/platform/@ref`.
- `game/@id` is an `xs:ID` used only by the JavaScript (`showGame(id)`), not for relations.
- There are no genres. Developer and platform identifiers match `[a-z][a-z0-9-]*`.

## Games (8)
| Game | Sector x Purpose | Cell of the slide |
|---|---|---|
| Civilization IV | Education x Games for Education | Learning |
| Assassin's Creed II | Education x Games for Education | Learning |
| Brain Age | Healthcare x Games for Health | Cybertherapy / Exergaming |
| Dance Dance Revolution | Healthcare x Games for Health | Cybertherapy / Exergaming |
| America's Army | Defense x Advergames | Recruitment & Propaganda |
| Full Spectrum Warrior | Defense x Games for Training | Soldier/Support Training |
| The Movies | Marketing & Communications x Production | Machinima |
| Foldit | Healthcare x Games for Science and Research | Visualization & Epidemiology (the presentation has Folding@Home in that cell) |

Sources: Civilization IV, Brain Age, DDR, America's Army and The Movies appear in the Sawyer & Smith presentation (slides 32, 34, 38, 40, 43); Assassin's Creed II appears in Bontchev's article (section 3.1); Full Spectrum Warrior and Foldit are not in either source. 4 of 7 sectors and 6 of 7 purposes are used (there are no games for Government & NGO, Corporate, Industry and Games as Work).

## How the XSLT works
- Parameters: `loadDocument`, `showAll`, `showId`, `sortOn`, `sortOrder`, `sortType`, `filterSector`, `filterPurpose`. Two views: a list of cards and the details of one game. The 49 cells stay in the XML and are used for the "Taxonomy cell" text in the details.
- The first load is done directly by the browser through the processing instruction (`loadDocument=true`) and produces the whole page. After that, the embedded JavaScript fetches `serious_games.xsl` and `serious_games.xml`, runs `XSLTProcessor` with `loadDocument=false` and replaces only `#content`.
- Sorting uses **two keys**: the selected one (`<xsl:sort select="@*[name()=$sortOn] | *[name()=$sortOn]">`, works for elements and attributes: `sector`, `purpose`, `title`) and a second one (`$secondary`: sector -> purpose, purpose -> sector, otherwise title). The values of `sector`/`purpose` are the names themselves, so the order is alphabetical.
- The XSL key `classificationByPair` (`concat(@sector,'|',@purpose)`) mirrors the composite key `classificationKey` of the XSD.
- Images: the template writes `src="{@source}"` (the name of the entity). The `imageUrlsMap` script (generated with `unparsed-entity-uri`) replaces the name with the real address. After `DOMParser` the information about entities is lost, which is why this trick is needed.
- The JavaScript inside the XSL is wrapped in `CDATA` to avoid problems with the characters `<` and `&`.

## Commands
```bash
cd src

# Validation
xmllint --noout --schema serious_games.xsd serious_games.xml

# Run (fetch and XSL do not work over file://, a server is needed)
python3 -m http.server 8080      # then http://localhost:8080/serious_games.xml

# Quick test of the transformation without a browser
xsltproc serious_games.xsl serious_games.xml
xsltproc --stringparam loadDocument false --stringparam sortOn purpose serious_games.xsl serious_games.xml
```
Chromium-based browsers do not load the XSL over `file://`, so a development server is used.

## Conventions and notes
- Content, interface, comments and documentation are in **English**.
- The data about the games is a short description based on public information. Check it against official sources (especially years and platforms) before relying on it.
- **Images: web addresses only, nothing is stored locally** (there is no `images/` folder). Every `<!ENTITY name SYSTEM "https://..." NDATA jpeg|png>` in the `DOCTYPE` points to Wikimedia Commons or Wikipedia. An internet connection is needed; without it `onerror` hides the broken image and the rest keeps working.
- Every `cover` has `alt` and `credit` (author, source, licence), which is shown under the image on the details page and as the `title` on the card.
- Notes about specific images: Civilization IV, Assassin's Creed II, Brain Age, Full Spectrum Warrior and The Movies are non-free box art from Wikipedia (used to identify the game); America's Army is public domain, Dance Dance Revolution is CC0 (a photo of an arcade cabinet, not box art), Foldit is CC BY-SA 3.0 de.
- New image: `<!ENTITY name SYSTEM "url" NDATA jpeg>` + `<cover source="name" alt="..." credit="..."/>` (the same applies to `gallery/image`).
- Not verified in Firefox or Safari. Firefox has no `unparsed-entity-uri` in some modes, which is why `imageUrlsMap` is used.
- Browsers are phasing out XSLT support. Chromium-based browsers already show a warning banner.
