angular.module('app').controller 'MainCtrl', ($window, $scope, $state, $location, $stateParams, $q, $http, sparql, prefixService, $compile, $templateCache) !->
  $window.PDFJS.workerSrc = 'bower_components/pdfjs-bower/dist/pdf.worker.js'
  iframe = $window.document.getElementById("htmlviewer")
  cd = iframe.contentDocument
  cd.open!
  cd.write('<html><head></head><body></body></html>')
  cd.close!
  base = cd.createElement('base')
  cd.head.appendChild(base)
  loc = $window.location.protocol + '//' + $window.location.host + $window.location.pathname
  css = cd.createElement('link')
  css.setAttribute('href',loc + 'styles/main.css')
  css.setAttribute('rel','stylesheet')
  cd.head.appendChild(css)
  css = cd.createElement('link')
  css.setAttribute('href',loc + 'bower_components/semantic/build/packaged/css/semantic.css')
  css.setAttribute('rel','stylesheet')
  cd.head.appendChild(css)
  $scope.closeContext = !->
    $location.search('concepts',void)
    $scope.context=false
    $scope.concepts=void
    context = {}
  $window.document.getElementById("htmlviewer").contentWindow.onclick = $scope.closeContext
  $scope.redirectQuery = '''
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    SELECT ?id {
      BIND(STR(<ID>) AS ?page)
      SERVICE <http://ldf.fi/colorado-ww1/sparql> {
        ?id foaf:page ?page .
      }
    }
    LIMIT 1
  '''
  $scope.equivalentsQuery = '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    SELECT DISTINCT ?concept {
      {
        <ID> (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch)* ?concept .
      } UNION {
        SERVICE <http://ldf.fi/dbpedia/sparql> {
          <ID> (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch)* ?concept .
        }
      } UNION {
        SERVICE <http://ldf.fi/colorado-ww1/sparql> {
          <ID> (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch)* ?concept .
        }
      }
    }
  '''
  $scope.propertiesQuery = '''
    PREFIX bf: <http://bibframe.org/vocab/>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX cww1s: <http://ldf.fi/colorado-ww1-schema#>
    PREFIX mads: <http://www.loc.gov/mads/rdf/v1#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT DISTINCT ?property ?object ?objectLabel {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        ?concept ?propertyIRI ?object .
        ?propertyIRI rdfs:label ?property .
        FILTER (LANG(?property)='en' || LANG(?property)='')
        OPTIONAL {
          ?object skos:prefLabel ?robjectLabel .
        }
        BIND(COALESCE(?robjectLabel,?object) AS ?objectLabel)
        FILTER(ISLITERAL(?objectLabel) && (LANG(?objectLabel)='en' || LANG(?objectLabel)=''))
      } UNION {
        SERVICE <http://ldf.fi/colorado-ww1/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          {
            ?concept ?propertyIRI ?object .
          } UNION {
            ?concept bf:instanceOf ?book .
            ?book ?propertyIRI ?object .
          }
          ?propertyIRI rdfs:label ?property .
          FILTER (LANG(?property)='en' || LANG(?property)='')
          OPTIONAL {
            FILTER(ISIRI(?object))
            ?object bf:titleStatement|bf:authorizedAccessPoint|bf:label|mads:authoritativeLabel|rdfs:label|skos:prefLabel ?robjectLabel .
          }
          BIND(COALESCE(?robjectLabel,?object) AS ?objectLabel)
          FILTER(ISLITERAL(?objectLabel) && (LANG(?objectLabel)='en' || LANG(?objectLabel)=''))
        }
      }
    }
  '''
  $scope.findQuery = '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX rdve3: <http://rdvocab.info/ElementsGr3/>
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
        SERVICE <http://ldf.fi/ww1/sparql> {
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
            {
              BIND(?ngram AS ?mngram)
              ?c skos:prefLabel|skos:altLabel|rdfs:label|rdve3:preferredNameForTheEvent|foaf:name ?mngram
            } UNION {
              BIND(LCASE(?ngram) AS ?mngram)
              ?c skos:prefLabel|skos:altLabel|rdfs:label ?mngram
            } UNION {
              BIND(CONCAT(UCASE(SUBSTR(?ngram,1,1)),LCASE(SUBSTR(?ngram,2))) AS ?mngram)
              ?c skos:prefLabel|skos:altLabel|rdfs:label ?mngram
            } UNION {
              BIND(STRLANG(?ngram,"en") AS ?mngram)
              ?c skos:prefLabel|skos:altLabel|rdfs:label ?mngram
            } UNION {
              BIND(STRLANG(LCASE(?ngram),"en") AS ?mngram)
              ?c skos:prefLabel|skos:altLabel|rdfs:label ?mngram
            } UNION {
              BIND(STRLANG(CONCAT(UCASE(SUBSTR(?ngram,1,1)),LCASE(SUBSTR(?ngram,2))),"en") AS ?mngram)
              ?c skos:prefLabel|skos:altLabel|rdfs:label ?mngram
            }
            ?c (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch)* ?concept .
            BIND(IF(STRSTARTS(STR(?c),"http://rdf.canadiana.ca/PCDHN-LOD/"),2,IF(STRSTARTS(STR(?c),"http://data.aim25.ac.uk/"),3,5)) AS ?order)
          }
        }
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
            FILTER NOT EXISTS {
              ?c a dbo:Album .
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
        BIND(4 AS ?order)
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
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX rdve3: <http://rdvocab.info/ElementsGr3/>
    SELECT (MAX(?cimageURL) AS ?simageURL) (MAX(?cllabel) AS ?sllabel) (MAX(?cdlabel) AS ?sdlabel) (MAX(?calabel) AS ?salabel) (MAX(?cgloss) AS ?sgloss) (MAX(?clat) AS ?slat) (MAX(?clng) AS ?slng) (MAX(?cpolygon) AS ?spolygon) WHERE {
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
          ?concept dc:description ?gloss .
          FILTER(LANG(?gloss)="en")
        }
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
        OPTIONAL {
          ?concept georss:polygon ?polygon .
        }
        BIND(COALESCE(?llabel,"") AS ?cllabel)
        BIND(COALESCE(?dlabel,"") AS ?cdlabel)
        BIND(COALESCE(?alabel,"") AS ?calabel)
        BIND(COALESCE(?gloss,"") AS ?cgloss)
        BIND(COALESCE(?lat,"") AS ?clat)
        BIND(COALESCE(?lng,"") AS ?clng)
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
          OPTIONAL {
            ?concept dbo:thumbnail ?imageURL .
          }
        }
        BIND(COALESCE(STR(?imageURL),"") AS ?cimageURL)
        BIND(COALESCE(?lat,"") AS ?clat)
        BIND(COALESCE(?lng,"") AS ?clng)
        BIND("" AS ?cdlabel)
        BIND("" AS ?calabel)
        BIND("" AS ?cpolygon)
        BIND(3 AS ?order)
      } UNION {
        SERVICE <http://ldf.fi/ww1/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          OPTIONAL {
            ?concept wgs84:point/wgs84:lat ?lat .
            ?concept wgs84:point/wgs84:long ?lng .
          }
          OPTIONAL {
            ?concept foaf:thumbnail ?imageURL .
          }
          OPTIONAL {
            ?concept skos:prefLabel|rdfs:label|rdve3:preferredNameForTheEvent|foaf:name ?llabel .
            FILTER(LANG(?llabel)="en")
          }
          OPTIONAL {
            ?concept skos:prefLabel|rdfs:label|rdve3:preferredNameForTheEvent|foaf:name ?dlabel .
            FILTER(LANG(?dlabel)="")
          }
          OPTIONAL {
            ?concept skos:prefLabel|rdfs:label|rdve3:preferredNameForTheEvent|foaf:name ?alabel .
          }
        }
        BIND(COALESCE(STR(?imageURL),"") AS ?cimageURL)
        BIND(COALESCE(?llabel,"") AS ?cllabel)
        BIND(COALESCE(?dlabel,"") AS ?cdlabel)
        BIND(COALESCE(?alabel,"") AS ?calabel)
        BIND(COALESCE(?lat,"") AS ?clat)
        BIND(COALESCE(?lng,"") AS ?clng)
        BIND("" AS ?cpolygon)
        BIND("" AS ?cgloss)
        BIND(2 AS ?order)
      }
    }
    ORDER BY ?order
  '''
  $scope.labelQuery = '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX bf: <http://bibframe.org/vocab/>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX rdve3: <http://rdvocab.info/ElementsGr3/>
    SELECT DISTINCT ?concept ?label {
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
      } UNION {
        SERVICE <http://ldf.fi/colorado-ww1/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          ?concept bf:titleStatement|bf:authorizedAccessPoint ?label .
        }
      } UNION {
        SERVICE <http://ldf.fi/ww1/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          ?concept skos:prefLabel|skos:altLabel|rdfs:label|rdve3:preferredNameForTheEvent|foaf:name ?label .
        }
      }
    }
  '''
  $scope.relatedEntitiesQuery = '''
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX bf: <http://bibframe.org/vocab/>
    SELECT ?concept {
        {
          VALUES ?originalConcept {
            <CONCEPTS>
          }
          ?originalConcept crm:P7_took_place_at|crm:P11_had_participant|crm:P14_carried_out_by ?concept .
        } UNION {
          SERVICE <http://ldf.fi/colorado-ww1/sparql> {
            VALUES ?originalConcept {
              <CONCEPTS>
            }
            {
              ?originalConcept bf:instanceOf/bf:subject ?concept .
            } UNION {
              ?originalConcept bf:instanceOf/bf:contributor ?concept .
            }
          }
        }
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
    PREFIX bf: <http://bibframe.org/vocab/>
    PREFIX rdve3: <http://rdvocab.info/ElementsGr3/>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
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
      } UNION {
        SERVICE <http://ldf.fi/colorado-ww1/sparql> {
          SELECT ?order ?concept ?llabel ?description ?imageURL {
            VALUES ?concept {
              <CONCEPTS>
            }
            ?concept bf:titleStatement ?llabel .
            ?concept bf:note ?description .
            BIND(3 AS ?order)
            ?concept foaf:page ?pdfIRI .
            BIND(REPLACE(STR(?pdfIRI),".pdf$",".jpg") AS ?imageURL)
          }
        }
      } UNION {
        SERVICE <http://ldf.fi/ww1/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          OPTIONAL {
            ?concept skos:prefLabel|rdfs:label|rdve3:preferredNameForTheEvent|foaf:name ?llabel .
            FILTER(LANG(?llabel)="en")
          }
          OPTIONAL {
            ?concept skos:prefLabel|rdfs:label|rdve3:preferredNameForTheEvent|foaf:name ?dlabel .
            FILTER(LANG(?dlabel)="")
          }
          OPTIONAL {
            ?concept skos:prefLabel|rdfs:label|rdve3:preferredNameForTheEvent|foaf:name ?alabel .
          }
          OPTIONAL {
            ?concept wgs84:point/wgs84:lat ?lat .
            ?concept wgs84:point/wgs84:long ?lng .
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
                  GRAPH ?g { ?concept crm:P4_has_time-span ?ts }
                  FILTER (?g!=<http://ldf.fi/ww1lod/iwm/>)
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
          SELECT ?concept (STRDT(STR(SAMPLE(?lat1)),xsd:decimal) AS ?lat) (STRDT(STR(SAMPLE(?lng1)),xsd:decimal) AS ?lng) {
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
          SELECT ?concept (STRDT(STR(SAMPLE(?lat1)),xsd:decimal) AS ?lat) (STRDT(STR(SAMPLE(?lng1)),xsd:decimal) AS ?lng) {
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
  $scope.$on '$locationChangeSuccess', (event) !->
    concepts = $location.search().concepts
    if (!concepts?) then concepts = []
    else if !(concepts instanceof Array) then concepts=concepts.split(',')
    if concepts.length!=$scope.concepts?.length then
      if (concepts.length>0) then openContext(concepts)
      else
        $scope.context=false
        $scope.concepts=void
    else for i from 0 til concepts.length
      if (concepts[i]!=$scope.concepts[i])
        openContext(concepts)
        return
  $scope.relatedQueries = {
    'WW1 Discovery' :
      type : 'SOLR'
      endpoint : 'http://ldf.fi/corsproxy/discovery.ac.uk/ww1/api/?q=<QUERY>&wt=json'
    'The European Library' :
      type : 'OpenSearch'
      endpoint : 'http://ldf.fi/corsproxy/http://data.theeuropeanlibrary.org/opensearch/json?query=<QUERY>&count=100&apikey=ct1b9u3jqll2lvfde8k4n7fm3k&'
    'DPLA' :
      type : 'Europeana'
      endpoint : 'http://ldf.fi/corsproxy/http://api.dp.la/v2/items?q=<QUERY>&page_size=200&api_key=c731bfd7f8038e0574a1b0dc22f2262a'
    'Colorado WW1 Collection' :
      endpoint : 'http://ldf.fi/colorado-ww1/sparql'
      query : '''
        PREFIX bf: <http://bibframe.org/vocab/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        PREFIX cww1s: <http://ldf.fi/colorado-ww1-schema#>
        PREFIX mads: <http://www.loc.gov/mads/rdf/v1#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          {
            VALUES (?concept ?mlabel) {
                <CONCEPTSLABELS>
            }
            FILTER(LANG(?mlabel)="en" || LANG(?mlabel)="")
            {
              ?s bf:subject ?concept .
              BIND("has subject" AS ?mtype)
            }
            UNION
            {
              ?s cww1s:possiblyMentions ?concept .
              BIND("mentions" AS ?mtype)
            }
          } UNION {
            VALUES ?mlabel {
              <LABELS>
            }
            {
              ?s2 bf:authorizedAccessPoint ?mlabel .
            } UNION {
              BIND(REPLACE(STR(?mlabel),"(?U)(\\\\w+) (.*)","$2, $1") AS ?mlabel2)
              ?s2 a bf:Person .
              ?s2 bf:authorizedAccessPoint ?alabel .
              FILTER(STRSTARTS(?alabel,?mlabel2))
            }
            ?s ?p ?s2 .
            ?p rdfs:label ?mtype .
          }
          BIND(CONCAT(?mtype,' ',?mlabel) AS ?group2)
          ?s bf:title ?label .
          ?i bf:instanceOf ?s .
          ?i foaf:page ?url .
          BIND(REPLACE(?url,".pdf$",".jpg") AS ?imageURL)
          OPTIONAL { ?s bf:contentsNote ?description }
          {
            ?s bf:language/bf:languageOfPartUri*/mads:authoritativeLabel ?group .
            FILTER(LANG(?group)="en")
          }
        }
        LIMIT 50
      '''
    Europeana :
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query: '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX edm: <http://www.europeana.eu/schemas/edm/>
        PREFIX ore: <http://www.openarchives.org/ore/terms/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX luc: <http://www.ontotext.com/owlim/lucene#>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          {
            VALUES ?group2 {
              <LABELS>
            }
            BIND (CONCAT("+",REPLACE(?group2,"\\\\s+"," +")) AS ?mlabel)
            SERVICE <http://europeana.ontotext.com/sparql> {
              ?subject luc: ?mlabel .
              ?subject luc:score ?score .
              FILTER(STRDT(?score,<http://www.w3.org/2001/XMLSchema#decimal>)>0.5)
              { SELECT ?label ?description ?type ?url ?source ?imageURL {
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
                ?p edm:provider ?source .
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
  !function openContext(concepts,replace)
    cs = {}
    for concept in concepts then cs[concept]=concept
    concepts = for concept of cs then concept
    if replace then $location.replace!
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
    cancelers.propertiesQuery = $q.defer!
    do
      response <-! sparql.query($scope.sparqlEndpoint,$scope.propertiesQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.propertiesQuery.promise}).then(_,handleError)
      if (response.data.results.bindings.length>0)
        context.properties = {}
        for binding in response.data.results.bindings
          arr = context.properties[binding.property.value]
          if (!arr?) then
            arr = []
            context.properties[binding.property.value]=arr
          if (binding.objectLabel.value!=binding.object.value) then
            arr.push({iri:sparql.bindingToString(binding.object),label:binding.objectLabel.value})
          else
            arr.push({label:binding.objectLabel.value})
    cancelers.infoQuery = $q.defer!
    response <-! sparql.query($scope.sparqlEndpoint,$scope.infoQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.infoQuery.promise}).then(_,handleError)
    descs = {}
    for binding in response.data.results.bindings
      if (binding.label? && !context.label?) then context.label=binding.label.value
      if (binding.description? && !descs[binding.description.value]?)
        descs[binding.description.value]={text:binding.description.value,class:binding.order.value}
      if binding.imageURL? && !(binding.imageURL.value in context.imageURLs)
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
    for v,desc of descs
      context.descriptions.push(desc)
    if (beg? && end?)
      begS='"'+beg.toISOString! + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>'
      endS='"'+end.toISOString! + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>'
      count = 0
      eventsD = []
      eventsM = []
      eventsY = []
      eventsO = []
      total = 0
      colors = ['blue','green','red']
      images = ['dull-blue-circle.png','dull-green-circle.png','dull-red-circle.png','dark-blue-circle.png','dark-green-circle.png','dark-red-circle.png','blue-circle.png','green-circle.png','red-circle.png']
      context.cmap = {}
      for id1,q of $scope.temporalQueries
        total++
        let id = id1
          cancelers['temporalQuery_' + id] = $q.defer!
          response <-! sparql.query(q.endpoint,q.query.replace(/<BEG>/g,begS).replace(/<END>/g,endS).replace(/<LAT>/g,context.lat ? '""').replace(/<LNG>/g,context.lng ? '""'),{timeout: cancelers['temporalQuery_' + id].promise}).then(_,handleError)
          for binding in response.data.results.bindings when binding.sbob? && binding.seoe?
            bob = new Date(binding.sbob.value)
            eoe = new Date(binding.seoe.value)
            start = if binding.seob? then new Date(binding.seob.value) else new Date(bob.getTime! + (eoe - bob)/2)
            end = if binding.sboe? then new Date(binding.sboe.value) else new Date(bob.getTime! + (eoe - bob)/2)
            diff = eoe - bob
            array = if diff <= 1209600000 then eventsD else if diff < 15768000000 then eventsM else eventsY
            obj =
              earliestEnd: end
              latestStart: start
              start: bob
              end: eoe
              image: binding.simageURL?.value
              color: colors[count % colors.length]
              textColor: 'black'
              icon: loc+'scripts/timeline_2.3.1/timeline_js/images/'+images[count % images.length]
              link: 'javascript:openContext("'+sparql.bindingToString(binding.concept)+'")'
              durationEvent: false
              title: binding.slabel.value
              description: if binding.sdescription? then binding.sdescription.value else ''
            array.push(obj)
            eventsO.push(obj)
            context.cmap[id]=colors[count % colors.length]
          if ++count == total
            tsize = (eventsD.length+eventsM.length+eventsY.length)
            if (tsize>0)
              bandInfos = []
              theme = Timeline.ClassicTheme.create!
              theme.autoWidth = true
              if (eventsD.length>0)
                eventSourceD = new Timeline.DefaultEventSource!
                eventSourceD.loadJSON(events:eventsD,'.')
                bandInfos.push(Timeline.createBandInfo(
                  eventSource: eventSourceD
                  theme: theme
                  width: (eventsD.length*100/tsize)+"%"
                  intervalUnit: Timeline.DateTime.DAY
                  intervalPixels: 70
                ))
              if (eventsM.length>0)
                eventSourceM = new Timeline.DefaultEventSource!
                eventSourceM.loadJSON(events:eventsM,'.')
                bandInfos.push(Timeline.createBandInfo(
                  eventSource: eventSourceM
                  theme: theme
                  width: (eventsM.length*100/tsize)+"%"
                  intervalUnit: Timeline.DateTime.MONTH
                  intervalPixels: 150
                ))
              if (eventsY.length>0)
                eventSourceY = new Timeline.DefaultEventSource!
                eventSourceY.loadJSON(events:eventsY,'.')
                bandInfos.push(Timeline.createBandInfo(
                  eventSource: eventSourceY
                  theme: theme
                  width: (eventsY.length*100/tsize)+"%"
                  intervalUnit: Timeline.DateTime.YEAR
                  intervalPixels: 200
                ))
              eventSourceO = new Timeline.DefaultEventSource!
              eventSourceO.loadJSON(events:eventsO,'.')
              bandInfos.push(Timeline.createBandInfo(
                eventSource: eventSourceO
                theme: theme
                overview: true
                width: "2%"
                intervalUnit: Timeline.DateTime.YEAR
                intervalPixels: 150
              ))
              for i from 1 til bandInfos.length
                bandInfos[i].syncWith = i - 1
                bandInfos[i].highlight = true
              tldiv = angular.element($window.document.getElementById('timeline'))
              tldiv.replaceWith('<div id="timeline"></div>')
              tl = Timeline.create($window.document.getElementById('timeline'),bandInfos)
              tl.getBand(0).setCenterVisibleDate(beg)
    if (context.lat? && context.lng?)
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
    labels = ""
    larr = []
    conceptLabels = ""
    for binding in response.data.results.bindings
      ls = sparql.bindingToString(binding.label)
      larr.push('"'+binding.label.value+'"')
      labels+=ls+" "
      conceptLabels+="(#{sparql.bindingToString(binding.concept)} #ls) "
    if (!begS?) then begS = '"1914-01-01"^^<http://www.w3.org/2001/XMLSchema#date>'
    if (!endS?) then endS = '"1919-01-01"^^<http://www.w3.org/2001/XMLSchema#date>'
    linkedResources = {}
    context.relatedQueriesRunning = 0
    context.linkedResourcesCount = 0
    for id1,q1 of $scope.relatedQueries
      let id = id1, q=q1
        cancelers['linkedResourcesQuery_' + id] = $q.defer!
        context.relatedQueriesRunning++
        if (q.query)
          response <-! sparql.query(q.endpoint,q.query.replace(/<CONCEPTS>/g,sconcepts).replace(/<CONCEPTSLABELS>/g,conceptLabels).replace(/<LABELS>/g,labels).replace(/<BEG>/g,begS).replace(/<END>/g,endS),{timeout: cancelers['linkedResourcesQuery_' + id].promise}).then(_,handleError)
          --context.relatedQueriesRunning
          if (response.data.results.bindings.length>0)
            context.linkedResourcesCount++
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
        else
          response <-! $http.get(q.endpoint.replace(/<QUERY>/g,encodeURI(larr.join(' OR ')))).then(_,handleError)
          --context.relatedQueriesRunning
          lrmap={}
          linkedResources[id]=[]
          if q.type=='Europeana'
            for doc in response.data.docs
              lrmap.{}[doc.sourceResource.language?[0].name].[][doc.sourceResource.type].push({url:doc.isShownAt,imageURL:doc.object,description:(if Array.isArray(doc.sourceResource.description) then doc.sourceResource.description.join(', ') else doc.sourceResource.description),source:doc.provider.name,label:if Array.isArray(doc.sourceResource.title) then doc.sourceResource.title.join(', ') else doc.sourceResource.title})
          else if q.type=='OpenSearch'
            for doc in response.data.Results
              lrmap.{}[doc.LANGUAGE[0]].[][''].push({url:doc.URI,imageURL:doc.THUMBNAIL?[0],description:doc.TOPIC?.join(', '),label:doc.TITLE.join(', ')})
          else
            for doc in response.data.response.result.doc
              infos = []
              for info in doc.str ? []
                switch info['@name']
                case "JISCDiscovery.previewMediaAbsolutePath" then imageURL=info.$t
                case "dc.identifier" then url = info.$t
                case "dcterms.relation" then url = info.$t
                case "dc.description" then description = info.$t
                case "dc.title" then label = info.$t
              for info in doc.arr ? []
                switch info['@name']
                case "JISCDiscovery.previewMediaAbsolutePath" then imageURL=(info.str ? info).$t
                case "dc.identifier" then url = (info.str ? info).$t
                case "dc.description" then description = (info.str ? info).$t
                case "dc.title" then label = (info.str ? info).$t
              lrmap.{}[doc['@source']].[][''].push({url,imageURL,description,label})
          for lang,typeMap of lrmap
            gr = {group:lang,resources:[]}
            for type,values of typeMap
              if (type!='') then gr.resources.push({group:type})
              for value in values
                gr.resources.push(value)
            linkedResources[id].push(gr)
    $scope.context.linkedResources = linkedResources
  $scope.openContext1 = (event,concept) !-> $scope.openContext2(concept)
  $scope.openContext2 = (concept) !->
    response <-! sparql.query($scope.sparqlEndpoint,$scope.equivalentsQuery.replace(/<ID>/g,concept)).then(_,handleError)
    concepts = []
    for binding in response.data.results.bindings
      concepts.push(sparql.bindingToString(binding.concept))
    openContext(concepts)
  $window.openContext = $scope.openContext2
  $scope.sparqlEndpoint = 'http://ldf.fi/ww1lod/sparql'
  $scope.errors=0
  !function handleError(response)
    console.log(response)
    $scope.errors++
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
    $scope.findQueryRunning = true
    response <-! sparql.query($scope.sparqlEndpoint,query).then(_,handleError)
    $scope.findQueryRunning = false
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
                nscope.concepts = []
                for binding in bindings
                  concept = sparql.bindingToString(binding.concept)
                  nscope.concepts.push(concept)
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
  oldError = PDFView.error
  PDFView.error = (error,moreInfo) !->
    if error=='An error occurred while loading the PDF.' and moreInfo.message == /^Unexpected server response \(0\) while retrieving PDF "/
      $window.DEFAULT_URL = 'http://ldf.fi/corsproxy/'+$window.DEFAULT_URL.substring(7)
      $window.webViewerLoad!
    else oldError(error,moreInfo)
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
  $scope.$watch 'url', (url,ourl) !-> if ourl? && url!=ourl then $state.go('home',{url})
  $scope.concepts = $location.search!.concepts
  if $scope.concepts?
    if !($scope.concepts instanceof Array) then $scope.concepts=$scope.concepts.split(',')
    openContext($scope.concepts)
  if (!$stateParams.url?) then $state.go('home',{url:'http://media.onki.fi/0/0/0/ww1/i71780828.pdf'})
  else
    if (!$scope.context)
      response <-! sparql.query($scope.sparqlEndpoint,$scope.redirectQuery.replace(/<ID>/g,'<'+$stateParams.url+'>')).then(_,handleError)
      if (response.data.results.bindings.length==1) then openContext([sparql.bindingToString(response.data.results.bindings[0].id)],true)
    cd.body.innerHTML = '<h2><i class="icon loading"></i></h2>'
    response <-! $http.head($stateParams.url.replace(/^http:\/\//,'http://ldf.fi/corsproxy/'),headers:{Accept:'application/pdf,text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8'}).then(_,handleError)
    url = response.headers('X-Location')
    $scope.url = url
    $location.search('url',url)
    if url == /.pdf$/i or response.headers!['content-type'] == 'application/pdf'
      $scope.view='pdf'
      $window.DEFAULT_URL = url
      $window.webViewerLoad!
    else
      $scope.view='html'
      response <-! $http.get(url,headers:{Accept:'text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8'}).then(_,handleError)
      iframe = $window.document.getElementById("htmlviewer")
      base.setAttribute('href',url.substring(0,url.lastIndexOf('/')+1))
      cd.body.innerHTML = response.data
      angular.element(cd.body).find('a').click (event) !->
        $state.go('home',{url:event.target.href})
        event.preventDefault!
      angular.element(cd.body).find('p,div,span').contents().filter(-> this.nodeType == 3 && this.parentNode.childNodes.length>1).replaceWith ->
        span = $window.document.createElement('span')
        span.textContent=this.textContent
        span
      runAnalysis(angular.element(cd.body).find('a,p,div,span').contents().filter(-> this.nodeType == 3 && this.parentNode.childNodes.length==1).parent())

