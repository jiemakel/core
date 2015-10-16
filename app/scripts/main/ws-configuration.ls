angular.module('app').value 'configuration',
  sparqlEndpoint : 'http://ldf.fi/warsa/sparql'
  defaultURL : 'http://kansataisteli.sshs.fi/Tekstit/1983/Kansa_Taisteli_09_1983.pdf#page=13'
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  arpaURLs : ['http://demo.seco.tkk.fi/arpa/karelia-places','http://demo.seco.tkk.fi/arpa/warsa_actor_persons','http://demo.seco.tkk.fi/arpa/warsa_actor_units']
  sources : ['Asseri','Tieteen termipankki','Wikipedia']
  findContextByDocumentURLQuery : '''
    SELECT ?id {
      {
        BIND(IRI(REPLACE(STR(<ID>),"http://.*finlex\\\\.fi/../laki/ajantasa/\\\\d\\\\d\\\\d\\\\d/","http://ldf.fi/finlex/laki/statute-sd")) AS ?id)
        FILTER EXISTS {
          ?id ?p ?o
        }
      } UNION {
        BIND(REPLACE(STR(<ID>),"http://www\\\\.finlex\\\\.fi/","http://finlex.fi/") AS ?url)
        ?id <http://purl.org/finlex/id/common/sourceUrl> ?url .
      }
    }
    LIMIT 1
  '''
  # used to expand a concept into its equivalencies for opening context, when this is not already available (e.g. using context-to-context links)
  expandEquivalentConceptsQuery : '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    SELECT DISTINCT ?concept {
      <ID> (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch)* ?concept .
    }
  '''
  # used to fetch properties for an identified context resource
  propertiesQuery : '''
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dct: <http://purl.org/dc/terms/>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT DISTINCT ?property ?object ?objectLabel {
      VALUES ?concept {
        <CONCEPTS>
      }
      ?concept ?propertyIRI ?object .
      ?propertyIRI rdfs:label ?property .
      FILTER (LANG(?property)='fi' || LANG(?property)='')
      OPTIONAL {
        ?object skos:prefLabel|dct:title|rdfs:label ?robjectLabel .
      }
      BIND(COALESCE(?robjectLabel,?object) AS ?objectLabel)
      FILTER(ISLITERAL(?objectLabel) && (LANG(?objectLabel)='fi' || LANG(?objectLabel)=''))
    }
  '''
  # used to get glosses, images, maps etc for the context hover popups
  shortInfoQuery : '''
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX dct: <http://purl.org/dc/terms/>
    SELECT ?simageURL ?sllabel ?sdlabel ?salabel ?sgloss ?slat ?slng ?spolygon {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        ?concept skos:prefLabel ?sllabel .
        FILTER(LANG(?sllabel)="fi")
        OPTIONAL {
          ?concept dct:description ?gloss .
        }
        ?concept rdfs:comment ?gloss2 .
      } UNION {
        SERVICE <http://ldf.fi/dbpedia-fi/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          ?concept rdfs:label ?sllabel .
          ?concept rdfs:comment ?gloss2 .
        }
      }
      BIND("" AS ?sdlabel)
      BIND("" AS ?salabel)
      BIND(IF(BOUND(?gloss),CONCAT(?gloss,".\\n\\n",?gloss2),?gloss2) AS ?sgloss)
      BIND("" AS ?slat)
      BIND("" AS ?slng)
      BIND("" AS ?spolygon)
      BIND("" AS ?simageURL)
    }
  '''
  # used to expand a context item into intimately related resources for later querying
  relatedEntitiesQuery : '''
    SELECT ?concept {
        VALUES ?originalConcept {
          <CONCEPTS>
        }
    }
  '''
  # used to get concept labels for context and intimately related resources in order to get related content from outside sources
  allLabelsQuery : '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    SELECT DISTINCT ?concept ?label {
      VALUES ?concept {
        <CONCEPTS>
      }
      ?concept skos:prefLabel|skos:altLabel|dc:title ?label .
    }
  '''
  # used to get gloss, image, location and temporal information about context item for both visualization and further querying
  infoQuery : '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    SELECT (COALESCE(?llabel,?dlabel,?alabel) AS ?label) ?description ?order ?imageURL ?lat ?lng ?polygon ?bob ?eob ?boe ?eoe {
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
      }
    }
  '''
  temporalQueries : {
  }
  locationQuery : '''
    SELECT ?group ?concept ?label ?description ?imageURL ?lat ?lng ?polygon {
    }
  '''
  relatedQueries : {
    'Samoja teemoja käsitteleviä lakeja' :
      order : 0
      endpoint : 'http://ldf.fi/finlex/sparql'
      query : '''
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX fls: <http://ldf.fi/finlex/schema/laki/>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          SELECT (GROUP_CONCAT(DISTINCT ?subjectLabel;separator=', ') AS ?group) ?url (SAMPLE(?l) AS ?label) {
            VALUES ?concept {
              <CONCEPTS>
            }
            ?concept (dc:subject|dct:subject)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)* ?subject .
            ?concept2 dct:subject ?subject .
            FILTER(?concept!=?concept2)
            ?concept2 skos:prefLabel|dc:title ?l .
            FILTER(LANG(?l)="fi" || LANG(?l)="")
            ?subject skos:prefLabel ?subjectLabel .
            FILTER(LANG(?subjectLabel)="fi")
            BIND(IRI(REPLACE(STR(?concept2),"http://ldf.fi/finlex/laki/statute-sd(\\\\d\\\\d\\\\d\\\\d)","http://finlex.fi/fi/laki/ajantasa/$1/$1")) AS ?url)
          }
          GROUP BY ?url
          ORDER BY DESC(COUNT(DISTINCT ?subjectLabel))
        }'''
    'Samoja teemoja käsitteleviä oikeuden päätöksiä' :
      order : 1
      endpoint : 'http://ldf.fi/finlex/sparql'
      query : '''
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX fls: <http://ldf.fi/finlex/schema/laki/>
        PREFIX fos: <http://ldf.fi/finlex/schema/oikeus/>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          SELECT (GROUP_CONCAT(DISTINCT ?subjectLabel;separator=', ') AS ?group) ?url (SAMPLE(?l) AS ?label) {
            VALUES ?concept {
              <CONCEPTS>
            }
            ?concept (dc:subject|dct:subject)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)* ?subject .
            ?concept2 dc:subject ?subject .
            FILTER(?concept!=?concept2)
            ?concept2 <http://purl.org/finlex/id/common/sourceUrl> ?url .
            ?concept2 rdfs:label ?l .
            FILTER(LANG(?l)="fi" || LANG(?l)="")
            ?subject skos:prefLabel ?subjectLabel .
            FILTER(LANG(?subjectLabel)="fi")
          }
          GROUP BY ?url
          ORDER BY DESC(COUNT(DISTINCT ?subjectLabel))
        }'''
    'Samoja teemoja käsitteleviä uutisia' :
      order : 2
      endpoint : 'http://ldf.fi/finlex/sparql'
      query : '''
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX fls: <http://ldf.fi/finlex/schema/laki/>
        PREFIX fos: <http://ldf.fi/finlex/schema/oikeus/>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          SELECT (GROUP_CONCAT(DISTINCT ?subjectLabel;separator=', ') AS ?group) ?url (SAMPLE(?l) AS ?label) {
            VALUES ?concept {
              <CONCEPTS>
            }
            ?concept (dc:subject|dct:subject)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)* ?subject .
            ?subject skos:prefLabel ?subjectLabel .
            FILTER(LANG(?subjectLabel)="fi")
            SERVICE <http://ldf.fi/media/sparql> {
              ?concept2 rdfs:label ?subjectLabel .
              ?article <http://purl.org/edilex/schema/news/subject> ?concept2 .
              ?article rdfs:label ?l .
              ?article <http://purl.org/finlex/id/common/sourceUrl> ?url .
            }
          }
          GROUP BY ?url
          ORDER BY DESC(COUNT(DISTINCT ?subjectLabel))
        }
      '''
    'Laveasti samoja teemoja käsitteleviä lakeja' :
      order : 3
      endpoint : 'http://ldf.fi/finlex/sparql'
      query : '''
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX fls: <http://ldf.fi/finlex/schema/laki/>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          SELECT (GROUP_CONCAT(DISTINCT ?subjectLabel;separator=', ') AS ?group) ?url (SAMPLE(?l) AS ?label) {
            VALUES ?concept {
              <CONCEPTS>
            }
            ?concept (dc:subject|dct:subject)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)*/(skos:related|^skos:related|skos:broader|^skos:broader)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)* ?subject .
            ?concept2 dct:subject ?subject .
            FILTER(?concept!=?concept2)
            ?concept2 skos:prefLabel|dc:title ?l .
            FILTER(LANG(?l)="fi" || LANG(?l)="")
            ?subject skos:prefLabel ?subjectLabel .
            FILTER(LANG(?subjectLabel)="fi")
            BIND(IRI(REPLACE(STR(?concept2),"http://ldf.fi/finlex/laki/statute-sd(\\\\d\\\\d\\\\d\\\\d)","http://finlex.fi/fi/laki/ajantasa/$1/$1")) AS ?url)
          }
          GROUP BY ?url
          ORDER BY DESC(COUNT(DISTINCT ?subjectLabel))
        }'''
    'Laveasti samoja teemoja käsitteleviä oikeuden päätöksiä' :
      order : 4
      endpoint : 'http://ldf.fi/finlex/sparql'
      query : '''PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX fls: <http://ldf.fi/finlex/schema/laki/>
        PREFIX fos: <http://ldf.fi/finlex/schema/oikeus/>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          SELECT (GROUP_CONCAT(DISTINCT ?subjectLabel;separator=', ') AS ?group) ?url (SAMPLE(?l) AS ?label) {
            VALUES ?concept {
              <CONCEPTS>
            }
            ?concept (dc:subject|dct:subject)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)*/(skos:related|^skos:related|skos:broader|^skos:broader)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)* ?subject .
            ?concept2 dc:subject ?subject .
            FILTER(?concept!=?concept2)
            ?concept2 <http://purl.org/finlex/id/common/sourceUrl> ?url .
            ?concept2 rdfs:label ?l .
            FILTER(LANG(?l)="fi" || LANG(?l)="")
            ?subject skos:prefLabel ?subjectLabel .
            FILTER(LANG(?subjectLabel)="fi")
          }
          GROUP BY ?url
          ORDER BY DESC(COUNT(DISTINCT ?subjectLabel))
        }'''
    'Laveasti samoja teemoja käsitteleviä uutisia' :
      order : 5
      endpoint : 'http://ldf.fi/finlex/sparql'
      query : '''
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX fls: <http://ldf.fi/finlex/schema/laki/>
        PREFIX fos: <http://ldf.fi/finlex/schema/oikeus/>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          SELECT (GROUP_CONCAT(DISTINCT ?subjectLabel;separator=', ') AS ?group) ?url (SAMPLE(?l) AS ?label) {
            VALUES ?concept {
              <CONCEPTS>
            }
            ?concept (dc:subject|dct:subject)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)*/(skos:related|^skos:related|skos:broader|^skos:broader)/(skos:exactMatch|^skos:exactMatch|owl:sameAs|^owl:sameAs)* ?subject .
            ?subject skos:prefLabel ?subjectLabel .
            FILTER(LANG(?subjectLabel)="fi")
            SERVICE <http://ldf.fi/media/sparql> {
              ?concept2 rdfs:label ?subjectLabel .
              ?article <http://purl.org/edilex/schema/news/subject> ?concept2 .
              ?article rdfs:label ?l .
              ?article <http://purl.org/finlex/id/common/sourceUrl> ?url .
            }
          }
          GROUP BY ?url
          ORDER BY DESC(COUNT(DISTINCT ?subjectLabel))
        }
      '''
  }
