<?xml version="1.0" encoding="UTF-8"?>
<!--
  XSLT 1.0 transformation for the Serious Games Catalogue.
  It works in two ways:
    1) directly through <?xml-stylesheet?> in games.xml (first page load);
    2) through XSLTProcessor from JavaScript (loadDocument=false) - when sorting, filtering and showing details.
  The state is passed to the stylesheet as parameters.
  Classification of a game: sector (rows) x purpose (columns) - Sawyer & Smith taxonomy.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" encoding="UTF-8" indent="yes" />

    <!-- Parameters (set from JavaScript) -->
    <xsl:param name="loadDocument">true</xsl:param>
    <xsl:param name="showAll">true</xsl:param>
    <xsl:param name="showId"></xsl:param>

    <xsl:param name="sortOn">sector</xsl:param>
    <xsl:param name="sortOrder">ascending</xsl:param>
    <xsl:param name="sortType">text</xsl:param>

    <xsl:param name="filterSector"></xsl:param>
    <xsl:param name="filterPurpose"></xsl:param>

    <!-- Second sort key: sector -> purpose, purpose -> sector, otherwise title -->
    <xsl:variable name="secondary">
        <xsl:choose>
            <xsl:when test="$sortOn = 'sector'">purpose</xsl:when>
            <xsl:when test="$sortOn = 'purpose'">sector</xsl:when>
            <xsl:otherwise>title</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Keys for fast lookup -->
    <xsl:key name="developerById" match="developer" use="@id" />
    <xsl:key name="platformById" match="platform[@id]" use="@id" />
    <xsl:key name="purposeByName" match="purpose" use="@name" />
    <!-- composite key that mirrors classificationKey (sector, purpose) from the XSD -->
    <xsl:key name="classificationByPair" match="classification" use="concat(@sector, '|', @purpose)" />
    <!-- composite key that mirrors gameKey (title, year) from the XSD -->
    <xsl:key name="gameByTitleYear" match="/catalogue/games/game" use="concat(title, '|', year)" />

    <!-- ===================== Entry point ===================== -->
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$loadDocument = 'true'">
                <xsl:call-template name="loadDocument" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="loadContent" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ===================== Full HTML page ===================== -->
    <xsl:template name="loadDocument">
        <html lang="en">
            <head>
                <meta charset="utf-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <title>Serious Games Catalogue</title>
                <link rel="stylesheet" href="styles.css" />
            </head>
            <body>
                <header class="site-header">
                    <h1>Serious Games Catalogue</h1>
                    <p>Games with a purpose beyond entertainment, classified by sector and purpose (Sawyer &amp; Smith taxonomy)</p>
                </header>
                <main id="content">
                    <xsl:call-template name="loadContent" />
                </main>

                <!-- Map "entity name" -> real image address (unparsed-entity-uri) -->
                <script>
                    <xsl:text>var imageUrlsMap = [</xsl:text>
                    <xsl:for-each select="//*[@source]">
                        <xsl:text>["</xsl:text>
                        <xsl:value-of select="@source" />
                        <xsl:text>", "</xsl:text>
                        <xsl:value-of select="unparsed-entity-uri(@source)" />
                        <xsl:text>"],</xsl:text>
                    </xsl:for-each>
                    <xsl:text>];</xsl:text>
                </script>

                <script>
<![CDATA[
var state = {
    loadDocument: "false",
    showAll: "true",
    showId: "",
    sortOn: "sector",
    sortOrder: "ascending",
    sortType: "text",
    filterSector: "",
    filterPurpose: ""
};

var xsltProcessor = null;
var xmlDoc = null;

function updateImageSource() {
    imageUrlsMap.forEach(function (e) {
        if (!e[1]) { return; }
        document.querySelectorAll('img[src="' + e[0] + '"]').forEach(function (el) {
            el.setAttribute("src", e[1]);
        });
    });
}

function updateContent() {
    xsltProcessor.clearParameters();
    Object.keys(state).forEach(function (key) {
        xsltProcessor.setParameter(null, key, state[key]);
    });
    var fragment = xsltProcessor.transformToFragment(xmlDoc, document);
    var content = document.getElementById("content");
    content.textContent = "";
    content.appendChild(fragment);
    updateImageSource();
}

function applyControls() {
    var sort = document.getElementById("sortSelect").value.split("|");
    state.sortOn = sort[0];
    state.sortOrder = sort[1] || "ascending";
    state.sortType = sort[2] || "text";
    state.filterSector = document.getElementById("sectorSelect").value;
    state.filterPurpose = document.getElementById("purposeSelect").value;
    updateContent();
}

function resetControls() {
    state.sortOn = "sector";
    state.sortOrder = "ascending";
    state.sortType = "text";
    state.filterSector = "";
    state.filterPurpose = "";
    updateContent();
}

function showGame(id) {
    state.showAll = "false";
    state.showId = id;
    updateContent();
    window.scrollTo(0, 0);
}

function showAllGames() {
    state.showAll = "true";
    state.showId = "";
    updateContent();
}

function initialize() {
    var parser = new DOMParser();
    Promise.all([fetch("games.xsl"), fetch("games.xml")]).then(function (responses) {
        return Promise.all(responses.map(function (r) { return r.text(); }));
    }).then(function (texts) {
        xsltProcessor = new XSLTProcessor();
        xsltProcessor.importStylesheet(parser.parseFromString(texts[0], "application/xml"));
        xmlDoc = parser.parseFromString(texts[1], "application/xml");
        document.body.classList.add("interactive");
    }).catch(function () {
        document.body.classList.add("static");
    });
    updateImageSource();
}

initialize();
]]>
                </script>
            </body>
        </html>
    </xsl:template>

    <!-- ===================== Content: list or details ===================== -->
    <xsl:template name="loadContent">
        <xsl:choose>
            <xsl:when test="$showAll = 'true'">
                <xsl:call-template name="toolbar" />
                <xsl:call-template name="gameList" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="gameDetails" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ===================== Sort and filter panel ===================== -->
    <xsl:template name="toolbar">
        <section class="toolbar" id="toolbar">
            <label>
                <span>Sort by</span>
                <select id="sortSelect" onchange="applyControls()">
                    <xsl:call-template name="sortOption"><xsl:with-param name="value" select="'sector|ascending|text'" /><xsl:with-param name="label" select="'Sector, then purpose (A&#8211;Z)'" /></xsl:call-template>
                    <xsl:call-template name="sortOption"><xsl:with-param name="value" select="'sector|descending|text'" /><xsl:with-param name="label" select="'Sector, then purpose (Z&#8211;A)'" /></xsl:call-template>
                    <xsl:call-template name="sortOption"><xsl:with-param name="value" select="'purpose|ascending|text'" /><xsl:with-param name="label" select="'Purpose, then sector (A&#8211;Z)'" /></xsl:call-template>
                    <xsl:call-template name="sortOption"><xsl:with-param name="value" select="'purpose|descending|text'" /><xsl:with-param name="label" select="'Purpose, then sector (Z&#8211;A)'" /></xsl:call-template>
                    <xsl:call-template name="sortOption"><xsl:with-param name="value" select="'title|ascending|text'" /><xsl:with-param name="label" select="'Title A&#8211;Z'" /></xsl:call-template>
                    <xsl:call-template name="sortOption"><xsl:with-param name="value" select="'title|descending|text'" /><xsl:with-param name="label" select="'Title Z&#8211;A'" /></xsl:call-template>
                    <xsl:call-template name="sortOption"><xsl:with-param name="value" select="'year|ascending|number'" /><xsl:with-param name="label" select="'Year (oldest first)'" /></xsl:call-template>
                    <xsl:call-template name="sortOption"><xsl:with-param name="value" select="'year|descending|number'" /><xsl:with-param name="label" select="'Year (newest first)'" /></xsl:call-template>
                </select>
            </label>

            <label>
                <span>Sector</span>
                <select id="sectorSelect" onchange="applyControls()">
                    <option value="">All sectors</option>
                    <xsl:for-each select="/catalogue/taxonomy/sectors/sector">
                        <option value="{@name}">
                            <xsl:if test="@name = $filterSector"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
                            <xsl:value-of select="@name" />
                        </option>
                    </xsl:for-each>
                </select>
            </label>

            <label>
                <span>Purpose</span>
                <select id="purposeSelect" onchange="applyControls()">
                    <option value="">All purposes</option>
                    <xsl:for-each select="/catalogue/taxonomy/purposes/purpose">
                        <option value="{@name}">
                            <xsl:if test="@name = $filterPurpose"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
                            <xsl:value-of select="@name" />
                        </option>
                    </xsl:for-each>
                </select>
            </label>

            <button type="button" class="btn btn-ghost" onclick="resetControls()">Reset</button>
        </section>
    </xsl:template>

    <xsl:template name="sortOption">
        <xsl:param name="value" />
        <xsl:param name="label" />
        <option value="{$value}">
            <xsl:if test="$value = concat($sortOn, '|', $sortOrder, '|', $sortType)">
                <xsl:attribute name="selected">selected</xsl:attribute>
            </xsl:if>
            <xsl:value-of select="$label" />
        </option>
    </xsl:template>

    <!-- ===================== List of cards ===================== -->
    <xsl:template name="gameList">
        <xsl:variable name="shown" select="/catalogue/games/game[($filterSector = '' or @sector = $filterSector) and ($filterPurpose = '' or @purpose = $filterPurpose)]" />
        <p class="result-count">
            <xsl:value-of select="count($shown)" />
            <xsl:text> of </xsl:text>
            <xsl:value-of select="count(/catalogue/games/game)" />
            <xsl:text> games</xsl:text>
        </p>

        <xsl:if test="count($shown) = 0">
            <p class="empty">No games match the selected filters.</p>
        </xsl:if>

        <div class="grid">
            <xsl:for-each select="/catalogue/games/game">
                <!-- two-level sort: the selected key (an element OR an attribute with that name), then the second key -->
                <xsl:sort select="@*[name() = $sortOn] | *[name() = $sortOn]" data-type="{$sortType}" order="{$sortOrder}" />
                <xsl:sort select="@*[name() = $secondary] | *[name() = $secondary]" data-type="text" order="ascending" />

                <xsl:if test="($filterSector = '' or @sector = $filterSector) and ($filterPurpose = '' or @purpose = $filterPurpose)">
                    <article class="card" id="{@id}">
                        <img class="card-img" src="{cover/@source}" alt="{cover/@alt}" title="{cover/@credit}" onerror="this.style.visibility='hidden'" />
                        <div class="card-body">
                            <h2>
                                <xsl:value-of select="title" />
                                <small><xsl:text> (</xsl:text><xsl:value-of select="year" /><xsl:text>)</xsl:text></small>
                            </h2>
                            <div class="badges">
                                <span class="badge {concat('purpose-', translate(@purpose, ' ', '-'))}"><xsl:value-of select="@purpose" /></span>
                                <span class="badge badge-sector"><xsl:value-of select="@sector" /></span>
                            </div>
                            <p class="meta"><xsl:value-of select="key('developerById', @developer)/name" /></p>
                            <p><xsl:value-of select="summary" /></p>
                            <button type="button" class="btn showMoreBut" onclick="showGame('{@id}')">Show more info</button>
                        </div>
                    </article>
                </xsl:if>
            </xsl:for-each>
        </div>
    </xsl:template>

    <!-- ===================== Details of one game ===================== -->
    <xsl:template name="gameDetails">
        <xsl:variable name="g" select="/catalogue/games/game[@id = $showId]" />
        <xsl:variable name="cell" select="key('classificationByPair', concat($g/@sector, '|', $g/@purpose))" />
        <xsl:variable name="purpose" select="key('purposeByName', $g/@purpose)" />
        <xsl:variable name="dev" select="key('developerById', $g/@developer)" />

        <button type="button" class="btn btn-ghost back" onclick="showAllGames()">&#8592; Back to all games</button>

        <article class="details">
            <figure class="details-figure">
                <img class="details-img" src="{$g/cover/@source}" alt="{$g/cover/@alt}" onerror="this.style.visibility='hidden'" />
                <figcaption><xsl:value-of select="$g/cover/@alt" /><span class="credit"><xsl:value-of select="$g/cover/@credit" /></span></figcaption>
            </figure>
            <div class="details-body">
                <h1>
                    <xsl:value-of select="$g/title" />
                    <small><xsl:text> (</xsl:text><xsl:value-of select="$g/year" /><xsl:text>)</xsl:text></small>
                </h1>
                <div class="badges">
                    <span class="badge {concat('purpose-', translate($g/@purpose, ' ', '-'))}"><xsl:value-of select="$g/@purpose" /></span>
                    <span class="badge badge-sector"><xsl:value-of select="$g/@sector" /></span>
                </div>

                <p class="lead"><xsl:value-of select="$g/summary" /></p>
                <p><xsl:value-of select="$g/description" /></p>

                <dl class="facts">
                    <dt>Classification</dt>
                    <dd>
                        <strong><xsl:value-of select="$g/@sector" /><xsl:text> &#215; </xsl:text><xsl:value-of select="$g/@purpose" /></strong>
                        <br />
                        <xsl:text>Taxonomy cell: </xsl:text><xsl:value-of select="$cell/label" />
                        <br />
                        <span class="muted"><xsl:value-of select="$purpose/description" /></span>
                    </dd>
                    <dt>Learning goal</dt>
                    <dd><xsl:value-of select="$g/learningGoal" /></dd>
                    <dt>Target audience</dt>
                    <dd><xsl:value-of select="$g/targetAudience" /></dd>
                    <dt>Player mode</dt>
                    <dd><xsl:value-of select="$g/playerMode" /></dd>
                    <dt>Access</dt>
                    <dd><xsl:value-of select="$g/access" /></dd>
                    <dt>Platforms</dt>
                    <dd>
                        <xsl:for-each select="$g/platforms/platform">
                            <xsl:value-of select="key('platformById', @ref)" />
                            <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
                        </xsl:for-each>
                    </dd>
                    <dt>Developer</dt>
                    <dd>
                        <xsl:value-of select="$dev/name" />
                        <xsl:text> (</xsl:text><xsl:value-of select="$dev/country" /><xsl:text>, </xsl:text><xsl:value-of select="$dev/@kind" /><xsl:text>)</xsl:text>
                    </dd>
                    <xsl:if test="$g/link">
                        <dt>Website</dt>
                        <dd><a href="{$g/link}" target="_blank" rel="noopener"><xsl:value-of select="$g/link" /></a></dd>
                    </xsl:if>
                </dl>

                <xsl:if test="$g/related/game">
                    <h3 class="related-title">See also</h3>
                    <ul class="related">
                        <xsl:for-each select="$g/related/game">
                            <!-- composite reference (title, year) to the game -->
                            <xsl:variable name="target" select="key('gameByTitleYear', concat(@title, '|', @year))" />
                            <li>
                                <button type="button" class="link" onclick="showGame('{$target/@id}')">
                                    <xsl:value-of select="@title" /> (<xsl:value-of select="@year" />)
                                </button>
                                <span class="muted"> &#8211; <xsl:value-of select="@reason" /></span>
                            </li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>

                <xsl:if test="$g/gallery/image">
                    <div class="gallery">
                        <xsl:for-each select="$g/gallery/image">
                            <img src="{@source}" alt="{$g/title}" />
                        </xsl:for-each>
                    </div>
                </xsl:if>
            </div>
        </article>
    </xsl:template>
</xsl:stylesheet>
