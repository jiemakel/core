angular.module('app').value 'configuration',
  sparqlEndpoint : 'http://ldf.fi/ww1lod/sparql'
  defaultURL : 'http://media.onki.fi/0/0/0/ww1/i71780828.pdf#15'
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  arpaURLs : [ 'http://demo.seco.tkk.fi/arpa/ww1lod' ]
  sources : [ 'WW1LOD', 'PCDHN-LOD','Trenches to Triples','DBPedia','Europeana' ]
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  findContextByDocumentURLQuery : '''
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    SELECT ?id {
      SERVICE <http://ldf.fi/colorado-ww1/sparql> {
        BIND(REPLACE(STR(<ID>),'https://','http://') AS ?page)
        ?id foaf:page ?page .
      }
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
      } UNION {
        SERVICE <http://ldf.fi/colorado-ww1/sparql> {
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
          {
            VALUES ?concept {
              <CONCEPTS>
            }
            ?concept ?propertyIRI ?object .
          } UNION {
            VALUES ?concept {
              <CONCEPTS>
            }
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
          ?concept wgs84:lat ?lat .
          ?concept wgs84:long ?lng .
        }
        OPTIONAL {
            ?concept crm:P7_took_place_at ?c2 .
            ?c2 wgs84:lat ?lat .
            ?c2 wgs84:long ?lng .
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
            FILTER NOT EXISTS {
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
  # used to expand a context item into intimately related resources for later querying
  relatedEntitiesQuery : '''
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
            ?originalConcept bf:instanceOf/(bf:subject|bf:contributor) ?concept .
          }
        }
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
  temporalQueries : {
    'Events from 1914-1918 Online' :
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query : '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX e1418: <http://encyclopedia.1914-1918-online.net/lod/schema#>
        SELECT ?concept (SAMPLE(?curl) AS ?url) (SAMPLE(?label) AS ?slabel) (SAMPLE(?description) AS ?sdescription) (SAMPLE(?imageURL) AS ?simageURL) (SAMPLE(?bob) AS ?sbob) (SAMPLE(?eob) AS ?seob) (SAMPLE(?boe) AS ?sboe) (SAMPLE(?eoe) AS ?seoe) {
          {
            SELECT ?concept {
              BIND(STRDT(REPLACE(STR(<BEG>),CONCAT(TZ(<BEG>),"$"),""),xsd:dateTime) AS ?lbeg)
              BIND(STRDT(REPLACE(STR(<END>),CONCAT(TZ(<END>),"$"),""),xsd:dateTime) AS ?lend)
              {
                SELECT ?concept (MAX(?tp) AS ?end) (MIN(?tp) AS ?beg) {
                  GRAPH <http://encyclopedia.1914-1918-online.net/lod/> { ?concept crm:P4_has_time-span ?ts }
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
            LIMIT 5
          }
          ?concept skos:prefLabel ?label .
          FILTER(LANG(?label)='en' || LANG(?label)='')
          ?concept crm:P4_has_time-span ?ts .
          ?ts crm:P82a_begin_of_the_begin ?bob .
          ?ts crm:P82b_end_of_the_end ?eoe .
          OPTIONAL { ?ts crm:P81a_end_of_the_begin ?eob }
          OPTIONAL { ?ts crm:P81b_begin_of_the_end ?boe }
          OPTIONAL { ?concept e1418:E1418_P_Related_Image ?imageURL }
          OPTIONAL { ?concept e1418:E1418_P_Related_Article ?curl }
        }
        GROUP BY ?concept
      '''
    'Events Near in Time' :
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query : '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        SELECT ?concept (SAMPLE(?label) AS ?slabel) (SAMPLE(?description) AS ?sdescription) (SAMPLE(?imageURL) AS ?simageURL) (SAMPLE(?bob) AS ?sbob) (SAMPLE(?eob) AS ?seob) (SAMPLE(?boe) AS ?sboe) (SAMPLE(?eoe) AS ?seoe) {
          {
            SELECT ?concept {
              BIND(STRDT(REPLACE(STR(<BEG>),CONCAT(TZ(<BEG>),"$"),""),xsd:dateTime) AS ?lbeg)
              BIND(STRDT(REPLACE(STR(<END>),CONCAT(TZ(<END>),"$"),""),xsd:dateTime) AS ?lend)
              {
                SELECT ?concept (MAX(?tp) AS ?end) (MIN(?tp) AS ?beg) {
                  GRAPH ?g { ?concept crm:P4_has_time-span ?ts }
                  FILTER (?g!=<http://ldf.fi/ww1lod/iwm/>)
                  FILTER NOT EXISTS {
                    ?concept owl:sameAs ?concept2 .
                  }
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
            LIMIT 5
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
            LIMIT 5
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
      name: 'Places'
      endpoint: 'http://ldf.fi/ww1lod/sparql'
      query: '''
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
    }
    {
      name: 'Events'
      endpoint: 'http://ldf.fi/ww1lod/sparql'
      query: '''
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
              ?place wgs84:lat ?lat1 .
              ?place wgs84:long ?lng1 .
              ?concept crm:P7_took_place_at ?place .
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
    }
    {
      name: 'Life events'
      endpoint: 'http://ldf.fi/dbpedia/sparql'
      query: '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
        PREFIX dbo: <http://dbpedia.org/ontology/>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX wgs84: <http://www.w3.org/2003/01/geo/wgs84_pos#>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX georss: <http://www.georss.org/georss/>
        SELECT ?concept (STRDT(STR(SAMPLE(?lat1)),xsd:decimal) AS ?lat) (STRDT(STR(SAMPLE(?lng1)),xsd:decimal) AS ?lng) ?label {
          {
            VALUES ?id {
              <CONCEPTS>
            }
            ?id dbo:birthPlace ?concept .
            ?id dbo:birthDate ?date .
            BIND("Born" AS ?eventLabel)
          } UNION {
            VALUES ?id {
              <CONCEPTS>
            }
            ?id dbo:deathPlace ?concept .
            ?id dbo:deathDate ?date .
            BIND("Died" AS ?eventLabel)
          }
          ?concept wgs84:lat ?lat1 .
          ?concept wgs84:long ?lng1 .
          ?concept rdfs:label ?placeLabel .
          FILTER (LANG(?placeLabel)='en')
          BIND(CONCAT(?eventLabel," on ",STR(?date)," in ",?placeLabel) AS ?label)
        }
        GROUP BY ?concept ?label
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
  relatedQueries : [
    {
      name: 'Colorado WW1 Collection'
      endpoint : 'http://ldf.fi/colorado-ww1/sparql'
      query : '''
        PREFIX bf: <http://bibframe.org/vocab/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        PREFIX cww1s: <http://ldf.fi/colorado-ww1-schema#>
        PREFIX mads: <http://www.loc.gov/mads/rdf/v1#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        SELECT (GROUP_CONCAT(DISTINCT ?gr;separator=', ') AS ?group) (MIN(?gr2) AS ?group2) (SAMPLE(?d) AS ?description) ?url (SAMPLE(?l) AS ?label) (SAMPLE(?iURL) AS ?imageURL) {
          {
            SELECT ?s (GROUP_CONCAT(DISTINCT ?mtype;separator=', ') AS ?gr2) (SAMPLE(?mlabel) AS ?gr) {
              {
                VALUES (?concept ?mlabel) {
                    <CONCEPTSLABELS>
                }
                ?s bf:subject ?concept .
                BIND("as subject" AS ?mtype)
              }
              UNION
              {
                VALUES (?concept ?mlabel) {
                    <CONCEPTSLABELS>
                }
                ?s cww1s:possiblyMentions ?concept .
                BIND("mentioned" AS ?mtype)
              }
            }
            GROUP BY ?s
          } UNION {
            {
              SELECT ?s2 (SAMPLE(?mlabel) AS ?gr) {
                {
                  VALUES ?mlabel {
                    <LABELS>
                  }
                  ?s2 bf:authorizedAccessPoint ?mlabel .
                } UNION {
                  VALUES ?mlabel {
                    <LABELS>
                  }
                  BIND(REPLACE(STR(?mlabel),"(?U)(\\\\w+) (.*)","$2, $1") AS ?mlabel2)
                  ?s2 a bf:Person .
                  ?s2 bf:authorizedAccessPoint ?alabel .
                  FILTER(STRSTARTS(?alabel,?mlabel2))
                }
              }
              GROUP BY ?s2
            }
            FILTER(BOUND(?s2))
            ?s ?p ?s2 .
            ?p rdfs:label ?gr2 .
          }
          ?s bf:title ?l .
          ?i bf:instanceOf ?s .
          ?i foaf:page ?url .
          BIND(REPLACE(?url,".pdf$",".jpg") AS ?iURL)
          OPTIONAL { ?s bf:contentsNote ?d }
        }
        GROUP BY ?url
        LIMIT 50
      '''
    }
    {
      name : 'Europeana'
      endpoint : 'http://ldf.fi/ww1lod/sparql'
      query: '''
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        PREFIX edm: <http://www.europeana.eu/schemas/edm/>
        PREFIX ore: <http://www.openarchives.org/ore/terms/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        PREFIX luc: <http://www.ontotext.com/owlim/lucene#>
        SELECT (GROUP_CONCAT(DISTINCT ?olabel;separator=', ') AS ?group) ?group2 ?source ?description ?url ?label ?imageURL {
          VALUES ?olabel {
            <LABELS>
          }
          BIND (CONCAT("+",REPLACE(?olabel,"\\\\s+"," +")) AS ?mlabel)
          SERVICE <http://europeana.ontotext.com/sparql> {
            SELECT ?mlabel ?group2 ?source (GROUP_CONCAT(DISTINCT ?descriptionS;separator=', ') AS ?description) ?url (GROUP_CONCAT(DISTINCT ?labelS;separator=', ') AS ?label) (SAMPLE(?imageURLS) AS ?imageURL) {
              ?s luc:full ?mlabel .
              ?s luc:score ?score .
              FILTER(STRDT(?score,<http://www.w3.org/2001/XMLSchema#decimal>)>0.5)
              ?s dc:title ?labelS .
              ?s dc:description ?descriptionS .
              ?s edm:type ?type .
              ?s ore:proxyFor ?edmA .
              ?p edm:aggregatedCHO ?edmA .
              ?p edm:isShownAt ?url .
              ?p edm:provider ?source .
              ?p2 edm:aggregatedCHO ?edmA .
              ?p2 edm:object ?edmObject .
              BIND(IRI(CONCAT('http://www.europeanastatic.eu/api/v2/thumbnail-by-url.json?size=w400&uri=',STR(?edmObject))) AS ?imageURLS)
              BIND(REPLACE(REPLACE(REPLACE(?type,"IMAGE","Images"),"TEXT","Texts"),"VIDEO","Videos") AS ?group2)
            }
            GROUP BY ?mlabel ?group2 ?source ?url
            LIMIT 50
          }
        }
        GROUP BY ?group2 ?source ?description ?url ?label ?imageURL
      '''
    }
#    {
#      name : 'WW1 Discovery'
#      type : 'SOLR'
#      endpoint : 'http://ldf.fi/corsproxy/discovery.ac.uk/ww1/api/?q=<QUERY>&wt=json'
#    }
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
