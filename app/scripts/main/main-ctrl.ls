
angular.module('app').controller 'MainCtrl', ($window,$scope, $stateParams, $q, sparql, prefixService, $compile, $templateCache) !->
  $window.PDFJS.workerSrc = 'bower_components/pdfjs-bower/dist/pdf.worker.js'
  $window.DEFAULT_URL = 'i71780828.pdf'
  $scope.findQuery = '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    SELECT DISTINCT ?ngram ?concept ?order WHERE {
      {
        VALUES ?text {
          <TEXTS>
        }
        VALUES ?word_index {
          <WORD_INDICES>
        }
        VALUES ?ngram_words {
          1 2 3 4 5 6
        }
        BIND(REPLACE(?text, CONCAT('(?U)^(?:\\\\s*(?:\\\\S*\\\\s+){', STR(?word_index) ,'}((?:\\\\w+\\\\s+){', STR(?ngram_words-1), '}\\\\w+).*|.*)'), '$1') as ?ngram)
        FILTER(STRLEN(?ngram)>2)
        {
          BIND(?ngram AS ?mngram)
          ?c skos:prefLabel|skos:altLabel ?mngram .
        } UNION {
          BIND(LCASE(?ngram) AS ?mngram)
          ?c skos:prefLabel|skos:altLabel ?mngram .
        } UNION {
          BIND(CONCAT(UCASE(SUBSTR(?ngram,1,1)),LCASE(SUBSTR(?ngram,2))) AS ?mngram)
          ?c skos:prefLabel|skos:altLabel ?mngram .
        } UNION {
          BIND(STRLANG(?ngram,"en") AS ?mngram)
          ?c skos:prefLabel|skos:altLabel ?mngram .
        } UNION {
          BIND(STRLANG(LCASE(?ngram),"en") AS ?mngram)
          ?c skos:prefLabel|skos:altLabel ?mngram .
        } UNION {
          BIND(STRLANG(CONCAT(UCASE(SUBSTR(?ngram,1,1)),LCASE(SUBSTR(?ngram,2))),"en") AS ?mngram)
          ?c skos:prefLabel|skos:altLabel ?mngram .
        }
        ?c (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch)* ?concept .
        BIND(1 AS ?order)
      } UNION {
        SERVICE <http://ldf.fi/dbpedia/sparql> {
          VALUES ?text {
            <TEXTS>
          }
          VALUES ?word_index {
            <WORD_INDICES>
          }
          VALUES ?ngram_words {
            1 2 3 4 5 6
          }
          BIND(REPLACE(?text, CONCAT('(?U)^(?:\\\\s*(?:\\\\S*\\\\s+){', STR(?word_index) ,'}((?:\\\\w+\\\\s+){', STR(?ngram_words-1), '}\\\\w+).*|.*)'), '$1') as ?ngram)
          FILTER(STRLEN(?ngram)>2 && UCASE(SUBSTR(?ngram,1,1))=SUBSTR(?ngram,1,1))
          BIND(STRLANG(?ngram,"en") AS ?mngram)
          ?c rdfs:label ?mngram .
          FILTER(STRSTARTS(STR(?c),'http://dbpedia.org/resource/'))
          FILTER(!STRSTARTS(STR(?c),'http://dbpedia.org/resource/Category:'))
          FILTER EXISTS { ?c a ?type }
          FILTER NOT EXISTS {
            ?c dbo:wikiPageDisambiguates ?other .
          }
          BIND(?c as ?concept)
          FILTER NOT EXISTS {
            ?concept dbo:wikiPageRedirects|dbo:wikiPageDisambiguates ?other .
          }
        }
        BIND(2 AS ?order)
      }
    }
    ORDER BY DESC(STRLEN(?ngram)) ?order
  '''
  $scope.shortInfoQuery = '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX georss: <http://www.georss.org/georss/>
    SELECT (MAX(?cllabel) as ?sllabel) (MAX(?cdlabel) AS ?sdlabel) (MAX(?calabel) AS ?salabel) (MAX(?cgloss) AS ?sgloss) (MAX(?clat) AS ?slat) (MAX(?clng) AS ?slng) (MAX(?cpolygon) AS ?spolygon) WHERE {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        OPTIONAL {
          ?concept skos:prefLabel ?llabel .
          FILTER(LANG(?llabel)="en")
        }
        BIND(COALESCE(?llabel,"") AS ?cllabel)
        OPTIONAL {
          ?concept skos:prefLabel ?dlabel .
          FILTER(LANG(?dlabel)="")
        }
        BIND(COALESCE(?dlabel,"") AS ?cdlabel)
        OPTIONAL {
          ?concept skos:prefLabel ?alabel .
        }
        BIND(COALESCE(?alabel,"") AS ?calabel)
        OPTIONAL {
          ?concept dc:description ?gloss .
          FILTER(LANG(?gloss)="en")
        }
        BIND(COALESCE(?gloss,"") AS ?cgloss)
        OPTIONAL {
          ?concept wgs84:lat ?lat .
          ?concept wgs84:long ?lng .
        }
        BIND(COALESCE(?lat,"") AS ?clat)
        BIND(COALESCE(?lng,"") AS ?clng)
        OPTIONAL {
          ?concept georss:polygon ?polygon .
        }
        BIND(COALESCE(?polygon,"") AS ?cpolygon)
        BIND(1 AS ?order)
      } UNION {
        SERVICE <http://ldf.fi/dbpedia/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          ?concept rdfs:label ?cllabel .
          FILTER(LANG(?cllabel)="en")
          ?concept rdfs:comment ?cgloss .
          FILTER(LANG(?cgloss)="en")
          OPTIONAL {
            ?concept wgs84:lat ?lat .
            ?concept wgs84:long ?lng .
          }
          BIND(COALESCE(?lat,"") AS ?clat)
          BIND(COALESCE(?lng,"") AS ?clng)
          BIND("" AS ?cdlabel)
          BIND("" AS ?calabel)
          BIND("" AS ?cpolygon)
          BIND(2 AS ?order)
        }
      }
    }
    ORDER BY ?order
  '''
  $scope.labelQuery = '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    SELECT DISTINCT ?label {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        ?concept skos:prefLabel|skos:altLabel ?label .
      } UNION {
        SERVICE <http://ldf.fi/dbpedia/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
        ?concept rdfs:label ?label .
        }
      }
    }
  '''
  $scope.infoQuery = '''
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX georss: <http://www.georss.org/georss/>
    SELECT ?description ?lat ?lng ?polygon ?bob ?eob ?boe ?eoe {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        OPTIONAL {
          ?concept dc:description ?description .
        }
        OPTIONAL {
          ?concept wgs84:lat ?lat .
          ?concept wgs84:long ?lng .
        }
        OPTIONAL {
          ?concept georss:polygon ?polygon .
        }
        OPTIONAL {
          ?concept crm:P4_has_time_span ?ts .
          OPTIONAL { ?ts crm:P82a_begin_of_the_begin ?bob }
          OPTIONAL { ?ts crm:P81a_end_of_the_begin ?eob }
          OPTIONAL { ?ts crm:P81b_begin_of_the_end ?boe }
          OPTIONAL { ?ts crm:P82b_end_of_the_end ?eoe }
        }
      } UNION {
        SERVICE <http://ldf.fi/dbpedia/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          ?concept dbo:abstract ?description .
          FILTER(LANG(?description)="en")
          OPTIONAL {
            ?concept wgs84:lat ?lat .
            ?concept wgs84:long ?lng .
          }
        }
      }
    }
  '''
  $scope.temporalQuery = '''
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concept ?label ?description ?imageURL ?bob ?eob ?boe ?eoe {
      {
        SELECT ?concept {
          SELECT ?concept (MAX(?tp) AS ?end) (MIN(?tp) AS ?beg) {
            ?concept crm:P4_has_time_span/(crm:P82a_begin_of_the_begin|crm:P81a_end_of_the_begin|crm:P81b_begin_of_the_end|crm:P82b_end_of_the_end) ?tp .
          }
          GROUP BY ?concept
        }
        ORDER BY (ABS(<BEG>+<END>-?beg-?end))
        LIMIT 100
      }
      ?concept skos:prefLabel ?label .
      ?concept crm:P4_has_time_span ?ts .
      OPTIONAL { ?ts crm:P82a_begin_of_the_begin ?bob }
      OPTIONAL { ?ts crm:P81a_end_of_the_begin ?eob }
      OPTIONAL { ?ts crm:P81b_begin_of_the_end ?boe }
      OPTIONAL { ?ts crm:P82b_end_of_the_end ?eoe }
      OPTIONAL { ?concept dc:description ?description }
    }
  '''
  $scope.locationQuery = '''
  '''
  $scope.relatedQuery = '''
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX edm: <http://www.europeana.eu/schemas/edm/>
    PREFIX ore: <http://www.openarchives.org/ore/terms/>
    SELECT ?group ?source ?description ?url ?label ?imageURL {
      {
        VALUES ?mlabel2 {
          <LABELS>
        }
        BIND(STR(?mlabel2) AS ?mlabel)
        SERVICE <http://europeana.ontotext.com/sparql> {
          ?s dc:subject ?mlabel .
          ?s dc:title ?label .
          ?s dc:description ?description .
          ?s edm:type ?type .
          ?s ore:proxyFor ?edmA .
          ?p edm:aggregatedCHO ?edmA .
          ?p edm:isShownAt ?url .
          ?p edm:isShownBy ?imageURL .
          ?p edm:provider ?provider .
        }
        BIND(REPLACE(?type,"IMAGE","images") AS ?group)
        BIND(CONCAT(?provider," via Europeana") AS ?source)
      }
    }
  '''
  fetchInfo = (scope,concepts) !-->
    if (!scope.loading)
      scope.loading=1
      response <-! sparql.query($scope.sparqlEndpoint,$scope.shortInfoQuery.replace(/<CONCEPTS>/g,concepts.join(" "))).then(_,handleError)
      b = response.data.results.bindings[0]
      if (b.sllabel.value!="") then scope.label=b.sllabel.value
      else if (b.sdlabel.value!="") then scope.label=b.sdlabel.value
      else scope.label=b.salabel.value
      if (b.sgloss.value!="") then scope.gloss=b.sgloss.value
      if (b.slat.value!="") then scope.lat=b.slat.value
      if (b.slng.value!="") then scope.lng=b.slng.value
      scope.loading=2
  !function openContext(concepts,label)
    $scope.concepts=concepts
    $scope.label=label
    $scope.context=true
    $scope.descriptions = []
    sconcepts = concepts.join(" ")
    do
      response <-! sparql.query($scope.sparqlEndpoint,$scope.infoQuery.replace(/<CONCEPTS>/g,sconcepts)).then(_,handleError)
      for binding in response.data.results.bindings
        if (binding.description?) then $scope.descriptions.push(binding.description.value)
        if (binding.lat?) then $scope.lat=binding.lat.value
        if (binding.lng?) then $scope.lng=binding.lng.value
        if (binding.bob? || binding.eob? || binding.boe? || binding.eoe?) then do
          if (binding.bob?.value<beg) then beg=binding.bob.value
          if (binding.bob?.value>end) then end=binding.bob.value
          if (binding.eob?.value<beg) then beg=binding.eob.value
          if (binding.eob?.value>end) then end=binding.eob.value
          if (binding.boe?.value<beg) then beg=binding.boe.value
          if (binding.boe?.value>end) then end=binding.boe.value
          if (binding.eoe?.value<beg) then beg=binding.eoe.value
          if (binding.eoe?.value>end) then end=binding.eoe.value
      console.log("T:",beg,end)
      if (beg? && end?)
        response <-! sparql.query($scope.sparqlEndpoint,$scope.temporalQuery.replace(/<BEG>/g,beg).REPLACE(/<END>/g,end)).then(_,handleError)
        console.log(response)
      if ($scope.lat? && $scope.lng?) then
        response <-! sparql.query($scope.sparqlEndpoint,$scope.locationQuery.replace(/<CONCEPTS>/g,sconcepts)).then(_,handleError)
        console.log(response)
    response <-! sparql.query($scope.sparqlEndpoint,$scope.labelQuery.replace(/<CONCEPTS>/g,sconcepts)).then(_,handleError)
    labels = []
    for binding in response.data.results.bindings
      labels.push(sparql.bindingToString(binding.label))
    response <-! sparql.query($scope.sparqlEndpoint,$scope.relatedQuery.replace(/<CONCEPTS>/g,sconcepts).replace(/<LABELS>/g,labels.join(" "))).then(_,handleError)
    console.log("L:",response)
  $scope.sparqlEndpoint = 'http://ldf.fi/ww1lod/sparql'
  !function handleError(response)
    console.log(response)
  !function runAnalysis(textDivs)
    texts = [textDiv.textContent for textDiv in textDivs]
    lastIndex = 0
    escapedTexts = ""
    for text in texts
      escapedTexts+= '"' + sparql.sanitize(text) + '" '
      cLastIndex = text.match(/\s+/g)?.length ? 0
      if (cLastIndex>lastIndex) then lastIndex=cLastIndex
    query = $scope.findQuery.replace(/<WORD_INDICES>/g,[0 to lastIndex].join(" ")).replace(/<TEXTS>/g,escapedTexts)
    response <-! sparql.query($scope.sparqlEndpoint,query).then(_,handleError)
    ngramsToConcepts = {}
    for binding in response.data.results.bindings
      if (!ngramsToConcepts[binding.ngram.value]?) then ngramsToConcepts[binding.ngram.value]=[]
      ngramsToConcepts[binding.ngram.value].push(binding)
    texts2 = [[text] for text in texts]
    for ngram, bindings of ngramsToConcepts
#      ngram = ( bfrmap[baseform] for baseform in label.split(' ') ).join(' ')
      re = new XRegExp('(^|.*?[\\p{P}\\p{Z}])('+ngram+')(?=[\\p{P}\\p{Z}]|$)','g')
      for ntexts in texts2
        i = 0
        while (i<ntexts.length)
          if (typeof ntexts[i] is "string" && ntexts[i].indexOf(ngram)>=0)
            nntexts = XRegExp.split(ntexts[i],re)
            ntexts.splice(i,1)
            for text in nntexts
              if (text==ngram)
                nscope = $scope.$new(true)
                nscope.class = bindings[0].order.value
                nscope.concepts = [sparql.bindingToString(binding.concept) for binding in bindings]
                nscope.openContext=openContext
                nscope.fetchInfo=fetchInfo(nscope)
                nscope.ngram=ngram
                ntexts.splice(i,0,$compile($templateCache.get('partials/concept.html'))(nscope))
                i++
              else if text!=''
                ntexts.splice(i,0,text)
                i++
          else i++
    for ntexts,index in texts2
      e = angular.element(textDivs[index])
      e.empty!
      for text in ntexts
        e.append(text)
  function asInt(value)
    parseInt(value.replace(/\.\d+p?x?$/,""))
  TextLayerBuilder.prototype.renderLayer = !->
    textLayerFrag = document.createDocumentFragment!
    textDivs = @textDivs
    textDivsLength = textDivs.length
    canvas = document.createElement("canvas")
    ctx = canvas.getContext("2d")

    # No point in rendering many divs as it would make the browser
    # unusable even after the divs are rendered.
    return  if textDivsLength > MAX_TEXT_DIVS_TO_RENDER
    lastFontSize = void
    lastFontFamily = void
    i = 0
    textDivsToAnalyze = []
    while i < textDivsLength
      textDiv = textDivs[i++]
      continue if textDiv.dataset.isWhitespace isnt void
      fontSize = textDiv.style.fontSize
      fontFamily = textDiv.style.fontFamily
      # Only build font string and set to context if different from last.
      if fontSize isnt lastFontSize or fontFamily isnt lastFontFamily
        ctx.font = fontSize + " " + fontFamily
        lastFontSize = fontSize
        lastFontFamily = fontFamily
      width = ctx.measureText(textDiv.textContent).width
      if width > 0
        canvasWidth = parseFloat(textDiv.dataset.canvasWidth)
        pTop = asInt(textDiv.style.top)
        while i<textDivsLength
          pTopN = asInt(textDivs[i].style.top)
          if not (pTop - 5 < pTopN < pTop + 5) then break
          fontSize = textDivs[i].style.fontSize
          fontFamily = textDivs[i].style.fontFamily
          if fontSize isnt lastFontSize or fontFamily isnt lastFontFamily
            ctx.font = fontSize + " " + fontFamily
            lastFontSize = fontSize
            lastFontFamily = fontFamily
          width += ctx.measureText(textDivs[i].textContent).width
          canvasWidth += parseFloat(textDivs[i].dataset.canvasWidth)
          pTop = pTopN
          textDiv.textContent+=textDivs[i++].textContent
        textLayerFrag.appendChild textDiv
        textDivsToAnalyze.push(textDiv)
        # Dataset values come of type string.
        textScale = canvasWidth / width
        rotation = textDiv.dataset.angle
        transform = "scale(" + textScale + ", 1)"
        transform = "rotate(" + rotation + "deg) " + transform  if rotation
        CustomStyle.setProp "transform", textDiv, transform
        CustomStyle.setProp "transformOrigin", textDiv, "0% 0%"
    @textLayerDiv.appendChild textLayerFrag
    @renderingDone = true
    @updateMatches!
    if textDivsToAnalyze.length!=0 then runAnalysis(textDivsToAnalyze)
  $window.webViewerLoad!
