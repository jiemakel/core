angular.module('app').value 'configuration',
  sparqlEndpoint : 'http://ldf.fi/warsa/sparql'
  defaultURL : 'http://kansataisteli.sshs.fi/Tekstit/1983/Kansa_Taisteli_09_1983.pdf'
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  arpaURLs : ['http://demo.seco.tkk.fi/arpa/karelia-places','http://demo.seco.tkk.fi/arpa/warsa_core_actors','http://demo.seco.tkk.fi/arpa/warsa_core_units','http://demo.seco.tkk.fi/arpa/warsa-dbpedia-fi']
  sources : ['Karelian places','Warsa persons','Warsa units','DBPedia']
  contextURLResolver : 'http://www.sotasampo.fi/page?uri='
  findDocumentURLByContextQuery : '''
    PREFIX dcterms: <http://purl.org/dc/terms/>
    SELECT ?id ?page {
      <ID> dcterms:hasFormat ?tid .
     	BIND(REPLACE(STR(?tid),"#.*","") AS ?id)
     	BIND(REPLACE(STR(?tid),".*#page=","") AS ?page)    }
    LIMIT 1
  '''
  findContextByDocumentURLQuery : '''
    PREFIX dcterms: <http://purl.org/dc/terms/>
    SELECT ?id {
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
      OPTIONAL {
        ?propertyIRI rdfs:label ?rproperty .
        FILTER (LANG(?rproperty)='fi' || LANG(?rproperty)='')
      }
      BIND(COALESCE(?rproperty,REPLACE(REPLACE(STR(?propertyIRI),".*/",""),".*#","")) AS ?property)
      FILTER(ISLITERAL(?property) && (LANG(?property)='fi' || LANG(?property)=''))
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
	  PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX schema: <http://schema.org/>
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
          FILTER(LANG(?llabel)="fi")
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
          FILTER(LANG(?gloss)="fi")
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
          ?concept schema:polygon ?polygon .
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
        SERVICE <http://ldf.fi/dbpedia-fi/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          ?concept rdfs:label ?cllabel .
          ?concept rdfs:comment ?cgloss .
          OPTIONAL {
            ?concept wgs84:lat ?lat .
            ?concept wgs84:long ?lng .
            MINUS {
              ?concept a dbo:Agent .
            }
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
      }
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
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX schema: <http://schema.org/>
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
          FILTER(LANG(?llabel)="fi")
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
          ?concept schema:polygon ?polygon .
        }
        OPTIONAL {
          ?concept crm:P4_has_time-span ?ts .
          OPTIONAL { ?ts crm:P82a_begin_of_the_begin ?bob }
          OPTIONAL { ?ts crm:P81a_end_of_the_begin ?eob }
          OPTIONAL { ?ts crm:P81b_begin_of_the_end ?boe }
          OPTIONAL { ?ts crm:P82b_end_of_the_end ?eoe }
        }
      } UNION {
        SERVICE <http://ldf.fi/dbpedia-fi/sparql> {
          VALUES ?concept {
            <CONCEPTS>
          }
          ?concept rdfs:label ?llabel .
          FILTER(LANG(?llabel)="fi")
          ?concept dbo:abstract ?description .
          BIND(2 AS ?order)
          FILTER(LANG(?description)="fi")
          OPTIONAL {
            ?concept dbo:thumbnail ?imageURL .
          }
          OPTIONAL {
            ?concept wgs84:lat ?lat .
            ?concept wgs84:long ?lng .
          }
          OPTIONAL {
            ?concept dbo:birthDate ?bob .
            BIND(?bob AS ?eob)
            ?concept dbo:deathDate ?boe .
            BIND(?bob AS ?eoe)
          }
        }
      }
    }
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
        SELECT ?directURL (SAMPLE(?subjectLabel) AS ?label) ?imageURL {
          VALUES ?concept {
            <CONCEPTS>
          }
	         ?directURL dct:spatial ?concept .
	         ?directURL sch:contentUrl ?imageURL .
	         ?directURL skos:prefLabel ?subjectLabel .
        }
        GROUP BY ?directURL ?imageURL
        '''
    }
  ]
