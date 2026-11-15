# Serious Games Catalogue

Catalogue of serious video games built with XML technologies: XML data with image entities, an XML Schema with composite keys and keyrefs, and an XSLT 1.0 + CSS front end with sorting and filtering. Games are classified by sector and purpose using the Sawyer & Smith taxonomy.

Course project No. 46, *Serious Video Games Catalogue – 2*, for **XML Technologies for the Semantic Web** (Sofia University "St. Kliment Ohridski", Faculty of Mathematics and Informatics, 2026).

## What it demonstrates

| Requirement of the assignment | Where it is done |
|---|---|
| Text and graphic content in XML | `src/serious_games.xml` |
| Graphics through **XML entities** | every image is an unparsed entity (`<!ENTITY … SYSTEM "…" NDATA jpeg>`) declared in the `DOCTYPE` and referenced by `source="…"` |
| Relations through **(composite) keys and key references** | `src/serious_games.xsd`: `xs:key` / `xs:keyref` (see below) |
| 7–8 games validated with **XML Schema** | 8 games, validated by `src/serious_games.xsd` |
| Presentation in a browser with **CSS and XSLT** | `src/serious_games.xsl` (XSLT 1.0) and `src/styles.css` |
| **Sorting** by several properties | sector, purpose, title (two-level sort) |

### Taxonomy and keys

The games are classified with the taxonomy of Ben Sawyer and Peter Smith, *Serious Games Taxonomy* (2008): a grid of **7 sectors (rows) × 7 purposes (columns) = 49 cells**. All 49 cells and their labels are stored in `src/serious_games.xml`.

- **Sectors:** Government & NGO, Defense, Healthcare, Marketing & Communications, Education, Corporate, Industry.
- **Purposes:** Games for Health, Advergames, Games for Training, Games for Education, Games for Science and Research, Production, Games as Work.

Composite keys in `src/serious_games.xsd`:

| Key | Fields | Referenced by |
|---|---|---|
| `classificationKey` | `(sector, purpose)` | every game (`gameClassificationRef`) |
| `gameKey` | `(title, year)` | links between related games in the data (`relatedGameRef`) |

Simple keys and references are used for sectors, purposes, developers and platforms.

## The games

| Game | Sector × Purpose |
|---|---|
| America's Army | Defense × Advergames |
| Full Spectrum Warrior | Defense × Games for Training |
| Civilization IV | Education × Games for Education |
| Assassin's Creed II | Education × Games for Education |
| Brain Age | Healthcare × Games for Health |
| Dance Dance Revolution | Healthcare × Games for Health |
| Foldit | Healthcare × Games for Science and Research |
| The Movies | Marketing & Communications × Production |

Most of them are named in the taxonomy presentation or in B. Bontchev, *Serious Games for and as Cultural Heritage* (2015). The descriptions are short summaries based on public information; check them against official sources before relying on them.

## The web page

- A catalogue of game cards with a detail page for every game (classification, learning goal, audience, platforms, developer, year).
- **Sort by** sector then purpose, purpose then sector, title, ascending or descending.
- **Filter by** sector and purpose.

The XML file points to the stylesheet with `<?xml-stylesheet href="serious_games.xsl" type="text/xsl"?>`. The first page is rendered by the browser itself. After that, a small script re-runs the transformation with `XSLTProcessor` and parameters (sorting, filters, selected game), so the page updates without reloading.

## Running it

The browser has to load the XSL and XML over HTTP, so open the project through a local server started in the `src` folder (opening the file directly from disk does not work in Chromium-based browsers):

```bash
cd src
python3 -m http.server 8080
```

Then open <http://localhost:8080/serious_games.xml>. An internet connection is needed to see the images.

Validate the data against the schema (from the `src` folder):

```bash
xmllint --noout --schema serious_games.xsd serious_games.xml
```

Try the transformation without a browser (from the `src` folder):

```bash
xsltproc serious_games.xsl serious_games.xml
xsltproc --stringparam loadDocument false --stringparam sortOn purpose serious_games.xsl serious_games.xml
```

## Project structure

| Path | Purpose |
|---|---|
| `src/serious_games.xml` | Data: taxonomy (49 cells), developers, platforms, 8 games, image entities |
| `src/serious_games.xsd` | XML Schema with all keys and key references |
| `src/serious_games.xsl` | XSLT 1.0 transformation, including the small script for sorting and filtering |
| `src/styles.css` | Styling |
| `CLAUDE.md` | Notes about the project for AI coding assistants |
| `LICENSE` | MIT license |

## Images

Images are **not stored in the repository**. Like in the hotel catalogue example this project is based on, the entities in the `DOCTYPE` point to images hosted on Wikimedia Commons and Wikipedia. If an image cannot be loaded (for example, without internet), it is simply hidden and the rest of the page keeps working.

Every image has a `credit` attribute with its author, source and licence, shown under the picture on the detail page. Several covers are non-free box art used only to identify the game.

## Notes

- Browsers are phasing out XSLT support. Chromium-based browsers already show a warning banner, so use a browser that still supports XSLT.
- The interface and data are in English.

## Sources

- B. Sawyer, P. Smith, *Serious Games Taxonomy*, Serious Games Summit, 2008.
- B. Bontchev, *Serious Games for and as Cultural Heritage*, Digital Presentation and Preservation of Cultural and Scientific Heritage, vol. 5, 2015.

## License

[MIT](LICENSE)
