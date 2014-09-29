
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
          {
            ?c dbo:wikiPageRedirects ?concept .
          } UNION {
            FILTER NOT EXISTS {
              ?c dbo:wikiPageRedirects ?other .
            }
            BIND(?c as ?concept)
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
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX georss: <http://www.georss.org/georss/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    SELECT (MAX(?cimageURL) AS ?simageURL) (MAX(?cllabel) AS ?sllabel) (MAX(?cdlabel) AS ?sdlabel) (MAX(?calabel) AS ?salabel) (MAX(?cgloss) AS ?sgloss) (MAX(?clat) AS ?slat) (MAX(?clng) AS ?slng) (MAX(?cpolygon) AS ?spolygon) WHERE {
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
          {
            ?concept wgs84:lat ?lat .
            ?concept wgs84:long ?lng .
          } UNION {
            ?concept crm:P7_took_place_at ?c2 .
            ?c2 wgs84:lat ?lat .
            ?c2 wgs84:long ?lng .
          }
        }
        BIND(COALESCE(?lat,"") AS ?clat)
        BIND(COALESCE(?lng,"") AS ?clng)
        OPTIONAL {
          ?concept georss:polygon ?polygon .
        }
        BIND(COALESCE(?polygon,"") AS ?cpolygon)
        BIND("" AS ?cimageURL)
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
          OPTIONAL {
            ?concept dbo:thumbnail ?imageURL .
          }
          BIND(COALESCE(STR(?imageURL),"") AS ?cimageURL)
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
  $scope.relatedEntitiesQuery = '''
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    SELECT ?concept {
        VALUES ?originalConcept {
          <CONCEPTS>
        }
        {
          ?originalConcept crm:P11_had_participant ?concept .
        } UNION {
          ?originalConcept crm:P7_took_place_at ?concept .
        }
    }
  '''
  $scope.infoQuery = '''
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX georss: <http://www.georss.org/georss/>
    SELECT ?description ?order ?imageURL ?lat ?lng ?polygon ?bob ?eob ?boe ?eoe {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        OPTIONAL {
          ?concept dc:description ?description .
          BIND(1 AS ?order)
        }
        OPTIONAL {
          ?concept wgs84:lat ?lat .
          ?concept wgs84:long ?lng .
        }
        OPTIONAL {
          ?concept georss:polygon ?polygon .
        }
        OPTIONAL {
          ?concept crm:P4_has_time-span ?ts .
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
          BIND(2 AS ?order)
          FILTER(LANG(?description)="en")
          OPTIONAL {
            ?concept dbo:thumbnail ?imageURL .
          }
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
      ?concept crm:P4_has_time-span ?ts .
      OPTIONAL { ?ts crm:P82a_begin_of_the_begin ?bob }
      OPTIONAL { ?ts crm:P81a_end_of_the_begin ?eob }
      OPTIONAL { ?ts crm:P81b_begin_of_the_end ?boe }
      OPTIONAL { ?ts crm:P82b_end_of_the_end ?eoe }
      OPTIONAL { ?concept dc:description ?description }
    }
  '''
  $scope.locationQuery = '''
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    PREFIX georss: <http://www.georss.org/georss/>
    SELECT ?concept ?label ?description ?imageURL ?lat ?lng ?polygon {
      {
        SELECT ?concept (STRDT(SAMPLE(?lat1),xsd:decimal) AS ?lat) (STRDT(SAMPLE(?lng1),xsd:decimal) AS ?lng) {
          ?concept wgs84:lat ?lat1 .
          ?concept wgs84:long ?lng1 .
        }
        GROUP BY ?concept
        ORDER BY (ABS(<LAT> - ?lat) + ABS(<LNG> - ?lng))
        LIMIT 50
      }
      ?concept skos:prefLabel ?label .
      OPTIONAL {
        ?concept dc:description ?description .
      }
    }
  '''
  $scope.relatedQueries = {
    'Colorado WW1 Collection' :
      endpoint : 'http://ldf.fi/colorado-ww1/sparql'
      query : '''
        PREFIX bf: <http://bibframe.org/vocab/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        PREFIX cww1s: <http://ldf.fi/colorado-ww1-schema#>
        PREFIX mads: <http://www.loc.gov/mads/rdf/v1#>
        SELECT ?group ?group2 ?group2Order ?source ?description ?url ?label ?imageURL {
          {
            VALUES ?concept {
                <CONCEPTS>
            }
            {
              ?s bf:subject ?concept .
              BIND("has subject" AS ?group2)
              BIND(0 AS ?group2Order)
            }
            UNION
            {
              ?s cww1s:possiblyMentions ?concept .
              BIND("mentions" AS ?group2)
              BIND(2 AS ?group2Order)
            }
          }
          UNION
          {
            VALUES ?mlabel {
              <LABELS>
            }
            ?s2 bf:authorizedAccessPoint ?mlabel .
            ?s ?p ?s2 .
            BIND("has actor" AS ?group2)
            BIND(1 AS ?group2Order)
          }
          ?s bf:title ?label .
          ?s bf:contentsNote ?description .
          ?s bf:language/bf:languageOfPartUri*/mads:authoritativeLabel ?group .
          FILTER(LANG(?group)="en")
          ?i bf:instanceOf ?s .
          ?i foaf:page ?url .
          BIND(REPLACE(?url,".pdf$",".jpg") AS ?imageURL)
        }
      '''
    Europeana :
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query: '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX edm: <http://www.europeana.eu/schemas/edm/>
        PREFIX ore: <http://www.openarchives.org/ore/terms/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX luc: <http://www.ontotext.com/owlim/lucene#>
        SELECT ?group ?source ?description ?url ?label ?imageURL {
          {
            VALUES ?mlabel {
              <LABELS>
            }
            SERVICE <http://europeana.ontotext.com/sparql> {
              ?subject luc: ?mlabel .
              ?subject luc:score ?score .
              FILTER(STRDT(?score,<http://www.w3.org/2001/XMLSchema#decimal>)>0.5)
              { SELECT ?label ?description ?type ?url ?provider ?imageURL {
                {
                  ?s dc:subject ?subject .
                } UNION {
                  ?s dc:title ?subject .
                } UNION {
                  ?s dc:description ?subject .
                }
                ?s dc:title ?label .
                ?s dc:description ?description .
                ?s edm:type ?type .
                ?s ore:proxyFor ?edmA .
                ?p edm:aggregatedCHO ?edmA .
                ?p edm:isShownAt ?url .
                ?p edm:provider ?provider .
                ?p2 edm:aggregatedCHO ?edmA .
                ?p2 edm:preview ?imageURL .
                OPTIONAL {
                  ?s2 ore:proxyFor ?edmA .
                  ?s2 edm:year ?year .
                }
              } LIMIT 50
              }
            }
            BIND(REPLACE(REPLACE(REPLACE(?type,"IMAGE","Images"),"TEXT","Texts"),"VIDEO","Videos") AS ?group)
            BIND(CONCAT(?provider," via Europeana") AS ?source)
          }
        }
      '''
  }
  fetchInfo = (scope,concepts) !-->
    if (!scope.loading)
      scope.loading=1
      response <-! sparql.query($scope.sparqlEndpoint,$scope.shortInfoQuery.replace(/<CONCEPTS>/g,concepts.join(" "))).then(_,handleError)
      b = response.data.results.bindings[0]
      if (b.simageURL.value!="") then scope.imageURL=b.simageURL.value
      if (b.sllabel.value!="") then scope.label=b.sllabel.value
      else if (b.sdlabel.value!="") then scope.label=b.sdlabel.value
      else scope.label=b.salabel.value
      if (b.sgloss.value!="") then scope.gloss=b.sgloss.value
      if (b.slat.value!="") then scope.lat=b.slat.value
      if (b.slng.value!="") then scope.lng=b.slng.value
      scope.loading=2
  !function openContext(concepts,label)
    context = {}
    context.concepts=concepts
    context.label=label
    context.descriptions = []
    context.imageURLs = []
    sconcepts = concepts.join(" ")
    cancelers = {}
    for canceler of cancelers then canceler.resolve!
    do
      cancelers.infoQuery = $q.defer!
      response <-! sparql.query($scope.sparqlEndpoint,$scope.infoQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.infoQuery.promise}).then(_,handleError)
      for binding in response.data.results.bindings
        if (binding.description?)
          context.descriptions.push({text:binding.description.value,class:binding.order.value})
        if (binding.imageURL?)
          context.imageURLs.push(binding.imageURL.value)
        if (binding.lat?) then context.lat=binding.lat.value
        if (binding.lng?) then context.lng=binding.lng.value
        if (binding.bob?)
          d = Date.parse(binding.bob.value)
          if (!beg? || beg>d) then beg=d
          if (!end? || end<d) then end=d
        if (binding.eob?)
          d = Date.parse(binding.eob.value)
          if (!beg? || beg>d) then beg=d
          if (!end? || end<d) then end=d
        if (binding.boe?)
          d = Date.parse(binding.boe.value)
          if (!beg? || beg>d) then beg=d
          if (!end? || end<d) then end=d
        if (binding.eoe?)
          d = Date.parse(binding.eoe.value)
          if (!beg? || beg>d) then beg=d
          if (!end? || end<d) then end=d
      if (beg? && end?)
        cancelers.temporalQuery = $q.defer!
        response <-! sparql.query($scope.sparqlEndpoint,$scope.temporalQuery.replace(/<BEG>/g,beg).replace(/<END>/g,end),{timeout: cancelers.temporalQuery.promise}).then(_,handleError)
        console.log("TEMPORAL:",response.data.results.bindings)
      if (context.lat? && context.lng?) then
        cancelers.locationQuery = $q.defer!
        response <-! sparql.query($scope.sparqlEndpoint,$scope.locationQuery.replace(/<LAT>/g,context.lat).replace(/<LNG>/g,context.lng),{timeout: cancelers.locationQuery.promise}).then(_,handleError)
        $scope.context.linkedLocations = []
        for binding in response.data.results.bindings
          console.log(binding)
          $scope.context.linkedLocations.push({concept:sparql.bindingToString(binding.concept),label:binding.label.value,lat:binding.lat.value,lng:binding.lng.value})
    $scope.context=context
    cancelers.labelQuery = $q.defer!
    response <-! sparql.query($scope.sparqlEndpoint,$scope.labelQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.labelQuery.promise}).then(_,handleError)
    labels = []
    for binding in response.data.results.bindings
      labels.push(sparql.bindingToString(binding.label))
    if (beg?) then beg='"'+beg.toISOString! + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>'
    else beg = '"1914-01-01"^^<http://www.w3.org/2001/XMLSchema#date>'
    if (end?) then end='"'+beg.toISOString! + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>'
    else end = '"1919-01-01"^^<http://www.w3.org/2001/XMLSchema#date>'
    linkedResources = {}
    for id1,q of $scope.relatedQueries
      let id = id1
        cancelers['linkedResourcesQuery_' + id] = $q.defer!
        response <-! sparql.query(q.endpoint,q.query.replace(/<CONCEPTS>/g,sconcepts).replace(/<LABELS>/g,labels.join(" ").replace(/<BEG>/g,beg).replace(/<END>/g,end)),{timeout: cancelers['linkedResourcesQuery_' + id].promise}).then(_,handleError)
        if (response.data.results.bindings.length>0)
          linkedResources[id]=[]
          groupOrder={}
          groups=500
          group2Order={}
          group2s=500
          lrmap = {}
          for binding in response.data.results.bindings
            group = if (binding.group?) then binding.group.value else ""
            if (!groupOrder[group]?)
              if (binding.groupOrder?) then groupOrder[group]=binding.groupOrder.value else groupOrder[group]=groups++
            group2 = if (binding.group2?) then binding.group2.value else ""
            if (!group2Order[group2]?)
              if (binding.group2Order?) then group2Order[group2]=binding.group2Order.value else group2Order[group2]=group2s++
            if (!lrmap[group]?) then lrmap[group]={}
            if (!lrmap[group][group2])  then lrmap[group][group2]=[]
            lrmap[group][group2].push({url:binding.url?.value,imageURL:binding.imageURL?.value,description:binding.description?.value,source:binding.source?.value,label:binding.label.value})
          groupOrder2 = []
          for val,ind of groupOrder then groupOrder2[ind]=val
          group2Order2 = []
          for val,ind of group2Order then group2Order2[ind]=val
          for group in groupOrder2 when lrmap[group]
            gr = {group:group,resources:[]}
            for group2 in group2Order2
              if (lrmap[group][group2]?)
                if (group2!='')
                  gr.resources.push({group:group2})
                for ress in lrmap[group][group2]
                  gr.resources.push(ress)
            linkedResources[id].push(gr)
    $scope.context.linkedResources = linkedResources
  $scope.openContext = (event,concept,label) !-> openContext([concept],label)
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
