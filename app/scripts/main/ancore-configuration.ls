angular.module('app').value 'configuration',
  sparqlEndpoint : 'http://ldf.fi/ancore/sparql'
  defaultURL : 'http://www.perseus.tufts.edu/hopper/text?doc=Perseus%3Atext%3A1999.02.0001%3Abook%3D1%3Achapter%3D1' #'http://www.gutenberg.org/files/226/226-h/226-h.htm'
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  arpaURLs :
    en: [ 'http://demo.seco.tkk.fi/arpa/ancore-en' ]
    _: [ 'http://demo.seco.tkk.fi/arpa/ancore-la' ]
  sources : [ 'Pleiades', 'DBPedia', 'Latin DBPedia' ]
  # used to locate the IRI corressponding to the document metadata when opening a document URL for reading
  findContextByDocumentURLQuery : '''
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    SELECT ?id {
      {
        BIND(STR(<ID>) AS ?page)
        ?id foaf:page ?page .
      } UNION {
        ?id foaf:page <ID> .
      }
    }
    LIMIT 1
  '''
  # used to expand a concept into its equivalencies for opening context, when this is not already available (e.g. using context-to-context links)
  expandEquivalentConceptsQuery : '''
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    SELECT DISTINCT ?concept {
      {
        <ID> (owl:sameAs|^owl:sameAs|skos:exactMatch|^skos:exactMatch|foaf:primaryTopicOf|^foaf:primaryTopicOf)* ?concept .
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
    PREFIX dct: <http://purl.org/dc/terms/>
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
          ?concept skos:prefLabel|rdfs:label|dct:title ?llabel .
          FILTER(LANG(?llabel)="en")
        }
        OPTIONAL {
          ?concept skos:prefLabel|rdfs:label|dct:title ?dlabel .
          FILTER(LANG(?dlabel)="")
        }
        OPTIONAL {
          ?concept skos:prefLabel|rdfs:label|dct:title ?alabel .
        }
        OPTIONAL {
          ?concept dct:description ?description .
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
    'Coins Found from Location' :
      endpoint : 'http://ldf.fi/ancore/sparql'
      query : '''
        PREFIX oa: <http://www.w3.org/ns/oa#>
        PREFIX oao: <http://www.openannotation.org/ns/>
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        SELECT ?concept ?url ?slabel ?sdescription ?simageURL ?sbob ?seob ?sboe ?seoe {
          VALUES ?o {
            <CONCEPTS>
          }
          ?a oa:hasBody ?o .
          ?a oa:hasTarget ?concept .
          ?concept dct:title ?slabel .
          ?concept foaf:homepage ?url .
          ?concept dct:temporal ?t .
          FILTER(STRSTARTS(?t,"start"))
          BIND(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(?t
            ,"start=(.*);.*","$1")
            ,"^(-?)(\\\\d)$","$1000$2")
            ,"^(-?)(\\\\d\\\\d)$","$100$2")
            ,"^(-?)(\\\\d\\\\d\\\\d)$","$10$2")
            ,"^-","-00")
            AS ?sbob)
          BIND(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(?t
            ,".*; end=(.*)","$1")
            ,"^(-?)(\\\\d)$","$1000$2")
            ,"^(-?)(\\\\d\\\\d)$","$100$2")
            ,"^(-?)(\\\\d\\\\d\\\\d)$","$10$2")
            ,"^-","-00")
            AS ?seoe)
        }
        LIMIT 30
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
    PREFIX dct: <http://purl.org/dc/terms/>
    PREFIX rdve3: <http://rdvocab.info/ElementsGr3/>
    SELECT DISTINCT ?concept ?label {
      {
        VALUES ?concept {
          <CONCEPTS>
        }
        ?concept dct:title|rdfs:label|skos:prefLabel|skos:altLabel ?label .
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
      name : 'Pelagios'
      endpoint : 'http://ldf.fi/ancore/sparql'
      query : '''
        PREFIX oa: <http://www.w3.org/ns/oa#>
        PREFIX oao: <http://www.openannotation.org/ns/>
        PREFIX dct: <http://purl.org/dc/terms/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        SELECT DISTINCT ?group ?group2 ?source ?description ?url ?label ?imageURL {
          VALUES ?o {
            <CONCEPTS>
          }
          GRAPH ?g {
            ?s oa:hasBody|oao:hasBody ?o .
          }
          ?s oa:hasTarget|oao:hasTarget ?s2 .
          {
            ?s dct:title ?label .
            BIND(?s2 AS ?url)
          } UNION {
            ?s2 dct:title ?label .
            ?s2 foaf:homepage ?url .
          }
          BIND(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(
            REPLACE(STR(?g)
              ,"http://dcc.dickinson.edu/sites/all/files/pelagios/ss-o-c.rdf","Dickinson College Commentaries")
              ,"http://gap.alexandriaarchive.org/bookdata/GAPtriples.n3","Place reference in book visualized in GapVis")
              ,"http://awmc.unc.edu/api/rdf_main.rdf","Place in AMWC feature database")
              ,"http://imperium.ahlfeldt.se/dare_pelagios2.n3","Place in the Digital Atlas of the Roman Empire")
              ,"http://isawnyu.github.com/isaw-papers-awdl/pelagios/isaw-papers-pelagios.rdf","References in ISAW papers")
              ,"http://nomisma.org/pelagios.rdf","Place in nomisma vocabulary")
              ,"http://finds.org.uk/rdf/pelagios.rdf","Place in nomisma vocabulary")
              ,"http://numismatics.org/ocre/pelagios.rdf","Coins found in this place in Online Coins of the Roman Empire")
              ,"http://numismatics.org/chrr/pelagios.rdf","Coins found in this place in Coin Hoards of the Roman Republic")
              ,"http://www.perseus.tufts.edu/xml/Perseus:collection:Greco-Roman.pleiades.rdf","References in the Perseus collection")
              ,"http://www.ancientwisdoms.ac.uk/media/pelagios/SAWSpelagios.rdf","References in Sharing Ancient Wisdoms")
              ,"http://omnesviae.org/api/sites/all/rdf","Place in the OmnesViae Roman Routeplanner")
              ,"http://opencontext.org/export/pelagios","References in Open Context archaeological data")
              ,"http://orbis.stanford.edu/api/orbis.pelagios.rdf","Place in the Stanford Geospatial Network Model of the Roman World")
            AS ?group)
        }
      '''
    }
    {
      name : 'Perseus Hopper'
      type : 'Atom'
      endpoint : 'http://catalog.perseus.org/catalog.atom?q=<QUERY>'
    }
    {
      name : 'Europeana'
      endpoint : 'http://ldf.fi/ancore/sparql'
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
