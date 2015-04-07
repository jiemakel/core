angular.module('app').value 'configuration',
  sparqlEndpoint : 'http://ldf.fi/ancore/sparql'
  defaultURL : 'http://www.perseus.tufts.edu/hopper/text?doc=Perseus:text:1999.01.0004'
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  findURL : 'http://demo.seco.tkk.fi/arpa/ancore'
  sources : [ 'Pleiades', 'DBPedia' ]
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  findContextByDocumentURLQuery : '''
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    SELECT ?id {
      BIND(STR(<ID>) AS ?page)
      ?id foaf:page ?page .
    }
    LIMIT 1
  '''
  # used to expand a concept into its equivalencies for opening context, when this is not already available (e.g. using context-to-context links)
  expandEquivalentConceptsQuery : '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    SELECT DISTINCT ?concept {
      {
        <ID> (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch)* ?concept .
      } UNION {
        SERVICE <http://ldf.fi/dbpedia/sparql> {
          <ID> (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch)* ?concept .
        }
      }
    }
  '''
  # used to fetch properties for an identified context resource
  propertiesQuery : '''
    PREFIX bf: <http://bibframe.org/vocab/>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX cww1s: <http://ldf.fi/colorado-ww1-schema#>
    PREFIX mads: <http://www.loc.gov/mads/rdf/v1#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX dct: <http://purl.org/dc/terms/>
    SELECT DISTINCT ?property ?object ?objectLabel {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        ?concept ?propertyIRI ?object .
        ?propertyIRI rdfs:label ?property .
        FILTER (LANG(?property)='en' || LANG(?property)='')
        OPTIONAL {
          ?object skos:prefLabel|rdfs:label|dct:title ?robjectLabel .
        }
        BIND(COALESCE(?robjectLabel,?object) AS ?objectLabel)
        FILTER(ISLITERAL(?objectLabel) && (LANG(?objectLabel)='en' || LANG(?objectLabel)=''))
      }
    }
  '''
  # used to get glosses, images, maps etc for the context hover popups
  shortInfoQuery : '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX georss: <http://www.georss.org/georss/>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX dbo: <http://dbpedia.org/ontology/>
    PREFIX rdve3: <http://rdvocab.info/ElementsGr3/>
    PREFIX dct: <http://purl.org/dc/terms/>
    SELECT (MAX(?cimageURL) AS ?simageURL) (MAX(?cllabel) AS ?sllabel) (MAX(?cdlabel) AS ?sdlabel) (MAX(?calabel) AS ?salabel) (MAX(?cgloss) AS ?sgloss) (MAX(?clat) AS ?slat) (MAX(?clng) AS ?slng) (MAX(?cpolygon) AS ?spolygon) WHERE {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        OPTIONAL {
          ?concept skos:prefLabel|dct:title|rdfs:label ?llabel .
          FILTER(LANG(?llabel)="en")
        }
        OPTIONAL {
          ?concept skos:prefLabel|dct:title|rdfs:label ?dlabel .
          FILTER(LANG(?dlabel)="")
        }
        OPTIONAL {
          ?concept skos:prefLabel|dct:title|rdfs:label ?alabel .
        }
        OPTIONAL {
          ?concept dc:description|dct:description ?gloss .
          FILTER(LANG(?gloss)="en" || LANG(?gloss)="")
        }
        OPTIONAL {
            ?concept wgs84:lat ?lat .
            ?concept wgs84:long ?lng .
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
            {
              ?concept wgs84:lat ?lat .
              ?concept wgs84:long ?lng .
              FILTER NOT EXISTS {
                ?concept a dbo:Agent .
              }
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
        BIND(2 AS ?order)
      }
    }
    ORDER BY ?order
  '''
  # used to expand a context item into intimately related resources for later querying
  relatedEntitiesQuery : '''
    PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
    PREFIX bf: <http://bibframe.org/vocab/>
    SELECT ?concept {
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
            {
              ?concept wgs84:lat ?lat .
              ?concept wgs84:long ?lng .
            }
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
  locationQueries  : [
    {
      name: 'Ancient Places'
      endpoint: 'http://ldf.fi/ancore/sparql'
      query: '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
        PREFIX dbo: <http://dbpedia.org/ontology/>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX georss: <http://www.georss.org/georss/>
        PREFIX dct: <http://purl.org/dc/terms/>
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
          ?concept dct:title ?label .
          OPTIONAL {
            ?concept dct:description ?description .
          }
        }
      '''
    }
  ]
  # used to get concept labels for context and intimately related resources in order to get related content from outside sources
  allLabelsQuery : '''
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
      }
    }
  '''
  relatedQueries : [
    {
      name : 'Europeana'
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query: '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX edm: <http://www.europeana.eu/schemas/edm/>
        PREFIX ore: <http://www.openarchives.org/ore/terms/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX luc: <http://www.ontotext.com/owlim/lucene#>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          {
            VALUES ?group {
              <LABELS>
            }
            BIND (CONCAT("+",REPLACE(?group,"\\\\s+"," +")) AS ?mlabel)
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
            BIND(REPLACE(REPLACE(REPLACE(?type,"IMAGE","Images"),"TEXT","Texts"),"VIDEO","Videos") AS ?group2)
          }
        }
      '''
    }
    {
      name :'Digital Public Library of America'
      type : 'Europeana'
      endpoint : 'http://ldf.fi/corsproxy/api.dp.la/v2/items?q=<QUERY>&page_size=200&api_key=c731bfd7f8038e0574a1b0dc22f2262a'
    }
    {
      name : 'The European Library'
      type : 'OpenSearch'
      endpoint : 'http://ldf.fi/corsproxy/data.theeuropeanlibrary.org/opensearch/json?query=<QUERY>&count=100&apikey=ct1b9u3jqll2lvfde8k4n7fm3k&'
    }
  ]
