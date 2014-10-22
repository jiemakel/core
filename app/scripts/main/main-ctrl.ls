angular.module('app').controller 'MainCtrl', ($window,$scope, $location, $stateParams, $q, $http, sparql, prefixService, $compile, $templateCache) !->
  $window.PDFJS.workerSrc = 'bower_components/pdfjs-bower/dist/pdf.worker.js'
  $window.document.getElementById("htmlviewer").contentWindow.onclick = ->
    $scope.context=false
    $scope.$apply!
  if ($stateParams.url?)
    if $stateParams.url == /.pdf$/i
      $scope.view='pdf'
      $window.DEFAULT_URL = $stateParams.url
    else
      $scope.view='html'
      response <-! $http.get($stateParams.url).then(_,handleError)
      cd = $window.document.getElementById("htmlviewer").contentDocument
      base = cd.createElement('base')
      base.setAttribute('href',$stateParams.url.substring(0,$stateParams.url.lastIndexOf('/')+1).replace('://ldf.fi/corsproxy/','://'))
      loc = $window.location.protocol + '//' + $window.location.host + $window.location.pathname
      console.log($window.location,loc)
      cd.head.appendChild(base)
      css = cd.createElement('link')
      css.setAttribute('href',loc + 'styles/main.css')
      css.setAttribute('rel','stylesheet')
      cd.head.appendChild(css)
      css = cd.createElement('link')
      css.setAttribute('href',loc + 'bower_components/semantic/build/packaged/css/semantic.css')
      css.setAttribute('rel','stylesheet')
      cd.head.appendChild(css)
      cd.body.innerHTML = response.data
      runAnalysis(angular.element(cd.body).find('a,p,div').contents().filter(-> this.nodeType == 3 && this.parentNode.childNodes.length==1).parent())
  else
    $scope.view='pdf'
    $window.DEFAULT_URL = 'i71780828.pdf'
  $scope.findQuery = '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    SELECT ?ngram ?concept ?order {
      {
        {
          SELECT DISTINCT ?ngram {
            VALUES ?text {
              <TEXTS>
            }
            VALUES ?word_index {
              <WORD_INDICES>
            }
            VALUES ?ngram_words {
              1 2 3 4 5 6
            }
            BIND(CONCAT('(?U)^(?:\\\\s*(?:\\\\S*\\\\s+){', STR(?word_index) ,'}((?:\\\\w+\\\\s+){', STR(?ngram_words-1), '}\\\\w+).*|.*)') AS ?regex)
            BIND(REPLACE(?text,'\\\\s+',' ','s') AS ?text2)
            BIND(REPLACE(?text2, ?regex, '$1','s') AS ?ngram)
            FILTER(STRLEN(?ngram)>2)
          }
        }
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
          SELECT ?ngram ?concept {
            {
              SELECT DISTINCT ?ngram {
                VALUES ?text {
                  <TEXTS>
                }
                VALUES ?word_index {
                  <WORD_INDICES>
                }
                VALUES ?ngram_words {
                  1 2 3 4 5 6
                }
                BIND(CONCAT('(?U)^(?:\\\\s*(?:\\\\S*\\\\s+){', STR(?word_index) ,'}((?:\\\\w+\\\\s+){', STR(?ngram_words-1), '}\\\\w+).*|.*)') AS ?regex)
                BIND(REPLACE(?text,'\\\\s+',' ','s') AS ?text2)
                BIND(REPLACE(?text2, ?regex, '$1','s') AS ?ngram)
                FILTER(STRLEN(?ngram)>2)
              }
            }
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
        ?originalConcept crm:P7_took_place_at|crm:P11_had_participant|crm:P14_carried_out_by ?concept .
    }
  '''
  $scope.infoQuery = '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX georss: <http://www.georss.org/georss/>
    SELECT (COALESCE(?llabel,?dlabel,?alabel) AS ?label) ?description ?order ?imageURL ?lat ?lng ?polygon ?bob ?eob ?boe ?eoe {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        OPTIONAL {
          ?concept skos:prefLabel ?llabel .
          FILTER(LANG(?llabel)="en")
        }
        OPTIONAL {
          ?concept skos:prefLabel ?dlabel .
          FILTER(LANG(?dlabel)="")
        }
        OPTIONAL {
          ?concept skos:prefLabel ?alabel .
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
          ?concept crm:P7_took_place_at ?place .
          ?place wgs84:lat ?lat .
          ?place wgs84:long ?lng .
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
          ?concept rdfs:label ?llabel .
          FILTER(LANG(?llabel)="en")
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
  $scope.temporalQueries = {
    'Events Near in Time' :
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query : '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        SELECT ?concept (SAMPLE(?label) AS ?slabel) (SAMPLE(?description) AS ?sdescription) (SAMPLE(?imageURL) AS ?simageURL) (SAMPLE(?bob) AS ?sbob) (SAMPLE(?eob) AS ?seob) (SAMPLE(?boe) AS ?sboe) (SAMPLE(?eoe) AS ?seoe) {
          {
            SELECT ?concept {
              BIND(STRDT(REPLACE(STR(<BEG>),CONCAT(TZ(<BEG>),"$"),""),xsd:dateTime) AS ?lbeg)
              BIND(STRDT(REPLACE(STR(<END>),CONCAT(TZ(<END>),"$"),""),xsd:dateTime) AS ?lend)
              {
                SELECT ?concept (MAX(?tp) AS ?end) (MIN(?tp) AS ?beg) {
                  ?concept crm:P4_has_time-span/(crm:P82a_begin_of_the_begin|crm:P81a_end_of_the_begin|crm:P81b_begin_of_the_end|crm:P82b_end_of_the_end) ?tp .
                }
                GROUP BY ?concept
              }
              BIND(STRDT(REPLACE(STR(?lbeg - ?beg),"^-",""),xsd:duration) AS ?dif1)
              FILTER(BOUND(?dif1))
              BIND(STRDT(REPLACE(STR(?lend - ?end),"^-",""),xsd:duration) AS ?dif2)
              FILTER(BOUND(?dif2))
            }
            ORDER BY (?dif1+?dif2)
            LIMIT 15
          }
          ?concept skos:prefLabel ?label .
          FILTER(LANG(?label)='en' || LANG(?label)='')
          ?concept crm:P4_has_time-span ?ts .
          ?ts crm:P82a_begin_of_the_begin ?bob .
          ?ts crm:P82b_end_of_the_end ?eoe .
          OPTIONAL { ?ts crm:P81a_end_of_the_begin ?eob }
          OPTIONAL { ?ts crm:P81b_begin_of_the_end ?boe }
          OPTIONAL {
            ?concept dc:description ?description
            FILTER(LANG(?description)='en' || LANG(?description)='')
          }
        }
        GROUP BY ?concept
      '''
    'Important Events Near in Time' :
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query : '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        SELECT ?concept (SAMPLE(?label) AS ?slabel) (SAMPLE(?description) AS ?sdescription) (SAMPLE(?imageURL) AS ?simageURL) (SAMPLE(?bob) AS ?sbob) (SAMPLE(?eob) AS ?seob) (SAMPLE(?boe) AS ?sboe) (SAMPLE(?eoe) AS ?seoe) {
          {
            SELECT ?concept {
              BIND(STRDT(REPLACE(STR(<BEG>),CONCAT(TZ(<BEG>),"$"),""),xsd:dateTime) AS ?lbeg)
              BIND(STRDT(REPLACE(STR(<END>),CONCAT(TZ(<END>),"$"),""),xsd:dateTime) AS ?lend)
              {
                SELECT ?concept (MAX(?tp) AS ?end) (MIN(?tp) AS ?beg) {
                  GRAPH <http://ldf.fi/ww1lod/iwm/> { ?concept crm:P4_has_time-span ?ts }
                  ?ts crm:P82a_begin_of_the_begin|crm:P81a_end_of_the_begin|crm:P81b_begin_of_the_end|crm:P82b_end_of_the_end ?tp .
                }
                GROUP BY ?concept
              }
              BIND(STRDT(REPLACE(STR(?lbeg - ?beg),"^-",""),xsd:duration) AS ?dif1)
              FILTER(BOUND(?dif1))
              BIND(STRDT(REPLACE(STR(?lend - ?end),"^-",""),xsd:duration) AS ?dif2)
              FILTER(BOUND(?dif2))
            }
            ORDER BY (?dif1+?dif2)
            LIMIT 15
          }
          ?concept skos:prefLabel ?label .
          FILTER(LANG(?label)='en' || LANG(?label)='')
          ?concept crm:P4_has_time-span ?ts .
          ?ts crm:P82a_begin_of_the_begin ?bob .
          ?ts crm:P82b_end_of_the_end ?eoe .
          OPTIONAL { ?ts crm:P81a_end_of_the_begin ?eob }
          OPTIONAL { ?ts crm:P81b_begin_of_the_end ?boe }
          OPTIONAL {
            ?concept dc:description ?description
            FILTER(LANG(?description)='en' || LANG(?description)='')
          }
        }
        GROUP BY ?concept
      '''
    'Other Events Near Location' :
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query : '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        SELECT ?concept (SAMPLE(?label) AS ?slabel) (SAMPLE(?description) AS ?sdescription) (SAMPLE(?imageURL) AS ?simageURL) (SAMPLE(?bob) AS ?sbob) (SAMPLE(?eob) AS ?seob) (SAMPLE(?boe) AS ?sboe) (SAMPLE(?eoe) AS ?seoe) {
          FILTER(<LAT>!="")
          {
            SELECT ?concept (STRDT(SAMPLE(?lat1),xsd:decimal) AS ?lat) (STRDT(SAMPLE(?lng1),xsd:decimal) AS ?lng) {
              {
                SELECT DISTINCT ?concept {
                  ?concept crm:P4_has_time-span/(crm:P82a_begin_of_the_begin|crm:P81a_end_of_the_begin|crm:P81b_begin_of_the_end|crm:P82b_end_of_the_end) ?tp .
                }
              }
              ?concept crm:P7_took_place_at ?place .
              ?place wgs84:lat ?lat1 .
              ?place wgs84:long ?lng1 .
            }
            GROUP BY ?concept
            ORDER BY (ABS(<LAT> - ?lat) + ABS(<LNG> - ?lng))
            LIMIT 15
          }
          ?concept skos:prefLabel ?label .
          FILTER(LANG(?label)='en' || LANG(?label)='')
          ?concept crm:P4_has_time-span ?ts .
          ?ts crm:P82a_begin_of_the_begin ?bob .
          ?ts crm:P82b_end_of_the_end ?eoe .
          OPTIONAL { ?ts crm:P81a_end_of_the_begin ?eob }
          OPTIONAL { ?ts crm:P81b_begin_of_the_end ?boe }
          OPTIONAL {
            ?concept dc:description ?description
            FILTER(LANG(?description)='en' || LANG(?description)='')
          }
        }
        GROUP BY ?concept
      '''
  }
  $scope.locationQuery = '''
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    PREFIX georss: <http://www.georss.org/georss/>
    SELECT ?group ?concept ?label ?description ?imageURL ?lat ?lng ?polygon {
      {
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
        BIND (1 AS ?group)
      } UNION {
        {
          SELECT ?concept (STRDT(SAMPLE(?lat1),xsd:decimal) AS ?lat) (STRDT(SAMPLE(?lng1),xsd:decimal) AS ?lng) {
            ?place wgs84:lat ?lat1 .
            ?place wgs84:long ?lng1 .
            ?concept crm:P7_took_place_at ?place .
          }
          GROUP BY ?concept
          ORDER BY (ABS(<LAT> - ?lat) + ABS(<LNG> - ?lng))
          LIMIT 50
        }
        ?concept skos:prefLabel ?label .
        OPTIONAL {
          ?concept dc:description ?description .
        }
        BIND (0 AS ?group)
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
        SELECT DISTINCT ?group ?source ?description ?url ?label ?imageURL {
          {
            VALUES ?mlabel2 {
              <LABELS>
            }
            BIND (CONCAT("'",?mlabel2,"'") AS ?mlabel)
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
  icons = ['http://maps.google.com/mapfiles/ms/icons/blue-dot.png','http://maps.google.com/mapfiles/ms/icons/green-dot.png','http://maps.google.com/mapfiles/ms/icons/orange-dot.png','http://maps.google.com/mapfiles/ms/icons/pink-dot.png','http://maps.google.com/mapfiles/ms/icons/purple-dot.png']
  !function openContext(concepts)
    $location.search('concepts',concepts)
    context = {}
    $scope.concepts=concepts
    context.descriptions = []
    context.imageURLs = []
    context.temporalQueries = []
    $scope.context=context
    sconcepts = concepts.join(" ")
    cancelers = {}
    for canceler of cancelers then canceler.resolve!
    cancelers.infoQuery = $q.defer!
    response <-! sparql.query($scope.sparqlEndpoint,$scope.infoQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.infoQuery.promise}).then(_,handleError)
    for binding in response.data.results.bindings
      if (binding.label? && !context.label?) then context.label=binding.label.value
      if (binding.description?)
        context.descriptions.push({text:binding.description.value,class:binding.order.value})
      if (binding.imageURL?)
        context.imageURLs.push(binding.imageURL.value)
      if (binding.lat?) then context.lat=binding.lat.value
      if (binding.lng?) then context.lng=binding.lng.value
      if (binding.bob?)
        d = new Date(binding.bob.value)
        context.bob=d
        if (!beg? || beg>d) then beg=d
        if (!end? || end<d) then end=d
      if (binding.eob?)
        d = new Date(binding.eob.value)
        context.eob=d
        if (!beg? || beg>d) then beg=d
        if (!end? || end<d) then end=d
      if (binding.boe?)
        context.boe=d
        d = new Date(binding.boe.value)
        if (!beg? || beg>d) then beg=d
        if (!end? || end<d) then end=d
      if (binding.eoe?)
        context.eoe=d
        d = new Date(binding.eoe.value)
        if (!beg? || beg>d) then beg=d
        if (!end? || end<d) then end=d
    if (beg? && end?)
      begS='"'+beg.toISOString! + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>'
      endS='"'+end.toISOString! + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>'
      count = 0
      for id1,q of $scope.temporalQueries
        let id = id1
          cancelers['temporalQuery_' + id] = $q.defer!
          response <-! sparql.query(q.endpoint,q.query.replace(/<BEG>/g,begS).replace(/<END>/g,endS).replace(/<LAT>/g,context.lat ? '""').replace(/<LNG>/g,context.lng ? '""'),{timeout: cancelers['temporalQuery_' + id].promise}).then(_,handleError)
          eventsD = []
          eventsM = []
          eventsY = []
          for binding in response.data.results.bindings when binding.sbob? && binding.seoe?
            bob = new Date(binding.sbob.value)
            eoe = new Date(binding.seoe.value)
            start = if binding.seob? then new Date(binding.seob.value) else new Date(bob.getTime! + (eoe - bob)/2)
            end = if binding.sboe? then new Date(binding.sboe.value) else new Date(bob.getTime! + (eoe - bob)/2)
            diff = eoe - bob
            array = if diff <= 1209600000 then eventsD else if diff < 15768000000 then eventsM else eventsY
            array.push(
              earliestEnd: end
              latestStart: start
              start: bob
              end: eoe
              durationEvent: binding.seob? || binding.sboe? || binding.sbob?.value != binding.seoe?.value
              title: binding.slabel.value
              description: if binding.sdescription? then binding.sdescription.value else ''
            )
          bandInfos = []
          theme = Timeline.ClassicTheme.create!
          theme.autoWidth = true
          tsize = (eventsD.length+eventsM.length+eventsY.length)*100
          if (tsize>0)
            if (eventsD.length>0)
              eventSourceD = new Timeline.DefaultEventSource!
              eventSourceD.loadJSON(events:eventsD,'.')
              bandInfos.push(Timeline.createBandInfo(
                eventSource: eventSourceD
                theme: theme
                width: (tsize/eventsD.length)+"%"
                intervalUnit: Timeline.DateTime.DAY
                intervalPixels: 70
              ))
            if (eventsM.length>0)
              eventSourceM = new Timeline.DefaultEventSource!
              eventSourceM.loadJSON(events:eventsM,'.')
              bandInfos.push(Timeline.createBandInfo(
                eventSource: eventSourceM
                theme: theme
                width: (tsize/eventsM.length)+"%"
                intervalUnit: Timeline.DateTime.MONTH
                intervalPixels: 150
              ))
            if (eventsY.length>0)
              eventSourceY = new Timeline.DefaultEventSource!
              eventSourceY.loadJSON(events:eventsY,'.')
              bandInfos.push(Timeline.createBandInfo(
                eventSource: eventSourceY
                theme: theme
                width: (tsize/eventsY.length)+"%"
                intervalUnit: Timeline.DateTime.YEAR
                intervalPixels: 200
              ))
            for i from 1 til bandInfos.length
              bandInfos[i].syncWith = i - 1
              bandInfos[i].highlight = true
            tl = Timeline.create($window.document.getElementById('timeline_'+(count:=count + 1)),bandInfos)
            tl.getBand(0).setCenterVisibleDate(beg)
            context.temporalQueries[id] = true
            console.log(tsize,context.temporalQueries)
    if (context.lat? && context.lng?) then
      cancelers.locationQuery = $q.defer!
      response <-! sparql.query($scope.sparqlEndpoint,$scope.locationQuery.replace(/<LAT>/g,context.lat).replace(/<LNG>/g,context.lng),{timeout: cancelers.locationQuery.promise}).then(_,handleError)
      $scope.context.linkedLocations = []
      for binding in response.data.results.bindings
        $scope.context.linkedLocations.push({icon:icons[parseInt(binding.group.value)],concept:sparql.bindingToString(binding.concept),label:binding.label.value,lat:binding.lat.value,lng:binding.lng.value})
    cancelers.relatedEntitiesQuery = $q.defer!
    response <-! sparql.query($scope.sparqlEndpoint,$scope.relatedEntitiesQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.relatedEntitiesQuery.promise}).then(_,handleError)
    for binding in response.data.results.bindings then sconcepts += ' ' + sparql.bindingToString(binding.concept)
    cancelers.labelQuery = $q.defer!
    response <-! sparql.query($scope.sparqlEndpoint,$scope.labelQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.labelQuery.promise}).then(_,handleError)
    labels = []
    for binding in response.data.results.bindings
      labels.push(sparql.bindingToString(binding.label))
    if (!begS?) then begS = '"1914-01-01"^^<http://www.w3.org/2001/XMLSchema#date>'
    if (!endS?) then endS = '"1919-01-01"^^<http://www.w3.org/2001/XMLSchema#date>'
    linkedResources = {}
    for id1,q of $scope.relatedQueries
      let id = id1
        cancelers['linkedResourcesQuery_' + id] = $q.defer!
        response <-! sparql.query(q.endpoint,q.query.replace(/<CONCEPTS>/g,sconcepts).replace(/<LABELS>/g,labels.join(" ").replace(/<BEG>/g,begS).replace(/<END>/g,endS)),{timeout: cancelers['linkedResourcesQuery_' + id].promise}).then(_,handleError)
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
  $scope.openContext = (event,concept) !-> openContext([concept])
  $scope.sparqlEndpoint = 'http://ldf.fi/ww1lod/sparql'
  !function handleError(response)
    console.log(response)
  !function runAnalysis(textDivs)
    texts = [textDiv.textContent for textDiv in textDivs]
    lastIndex = 0
    escapedTexts = ""
    for text in texts
      for text2 in text.split('\n')
        escapedTexts+= '"' + sparql.sanitize(text2) + '" '
        cLastIndex = text2.match(/\s+/g)?.length ? 0
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
  if ($scope.view=='pdf') then $window.webViewerLoad!
  if $stateParams.concepts?
    if !($stateParams.concepts instanceof Array) then $stateParams.concepts=$stateParams.concepts.split(',')
    openContext($stateParams.concepts)
