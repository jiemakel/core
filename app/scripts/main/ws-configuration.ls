angular.module('app').value 'configuration',
  sparqlEndpoint : 'http://ldf.fi/warsa/sparql'
  defaultURL : 'http://kansataisteli.sshs.fi/Tekstit/1983/Kansa_Taisteli_09_1983.pdf&page=13'
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  arpaURLs : ['http://demo.seco.tkk.fi/arpa/karelia-places','http://demo.seco.tkk.fi/arpa/warsa_actor_persons','http://demo.seco.tkk.fi/arpa/warsa_actor_units','http://demo.seco.tkk.fi/arpa/warsa-dbpedia-fi']
  sources : ['Karelian places','Warsa persons','Warsa units','DBPedia']
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
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX georss: <http://www.georss.org/georss/>
	PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
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
        #?concept rdfs:comment ?gloss2 .
	OPTIONAL {
          {
            ?concept wgs84:lat ?slat .
            ?concept wgs84:long ?slng .
          } UNION {
            ?concept crm:P7_took_place_at ?c2 .
            ?c2 wgs84:lat ?slat .
            ?c2 wgs84:long ?slng .
          }
        }
        OPTIONAL {
          ?concept georss:polygon ?polygon .
        }
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
      #BIND("" AS ?slat)
      #BIND("" AS ?slng)
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
    PREFIX sch: <http://schema.org/>
    PREFIX dct: <http://purl.org/dc/terms/>
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
      OPTIONAL {
        ?imageId dct:spatial ?concept .
        ?imageId sch:contentUrl ?imageURL .
      }
    }
    LIMIT 1
  '''
  temporalQueries : {
  }
  locationQuery : '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
        PREFIX dbo: <http://dbpedia.org/ontology/>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX georss: <http://www.georss.org/georss/>
        SELECT ?concept ?label ?description ?imageURL ?lat ?lng ?polygon {
          {
            SELECT ?concept (STRDT(STR(SAMPLE(?lat1)),xsd:decimal) AS ?lat) (STRDT(STR(SAMPLE(?lng1)),xsd:decimal) AS ?lng) {
              VALUES (?rlat ?rlng) {
                <LATLNG>
              }
              ?concept wgs84:lat ?lat1 .
              ?concept wgs84:long ?lng1 .
            }
            GROUP BY ?concept ?rlat ?rlng
            ORDER BY (ABS(?rlat - ?lat) + ABS(?rlng - ?lng))
            LIMIT 50
          }
          ?concept skos:prefLabel ?label .
          OPTIONAL {
            ?concept dc:description ?description .
          }
        }

  '''
  relatedQueries : [
    {
      name: 'Kuvia paikalta'
      endpoint : 'http://ldf.fi/warsa/sparql'
      query : '''
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX fls: <http://ldf.fi/finlex/schema/laki/>
	      PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX sch: <http://schema.org/>
        SELECT ?url (SAMPLE(?subjectLabel) AS ?label) ?imageURL {
          VALUES ?concept {
            <CONCEPTS>
          }
	         ?url dct:spatial ?concept .
	         ?url sch:contentUrl ?imageURL .
	         ?url skos:prefLabel ?subjectLabel .
        }
        GROUP BY ?url ?imageURL
        '''
    }
  ]
