angular.module('app').controller 'MainCtrl', ($window, $scope, $state, $location, $timeout, $stateParams, $q, $http, sparql, prefixService, $compile, $sce, $templateCache,configuration ) !->
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
  css.setAttribute('href',loc + 'bower_components/semantic-ui/dist/semantic.min.css')
  css.setAttribute('rel','stylesheet')
  cd.head.appendChild(css)
  $scope.closeContext = !->
    $location.search('concepts',void)
    $scope.context=false
    $scope.concepts=void
    context = {}
    $timeout($scope.updateDisplay)
  $window.document.getElementById("htmlviewer").contentWindow.onclick = $scope.closeContext
  $scope.configuration = configuration
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
  fetchInfo = (scope,concepts) !-->
    if (!scope.loading)
      scope.loading=1
      response <-! sparql.query(configuration.sparqlEndpoint,configuration.shortInfoQuery.replace(/<CONCEPTS>/g,concepts.join(" "))).then(_,handleError)
      b = response.data.results.bindings[0]
      if (b.simageURL.value!="") then scope.imageURL=b.simageURL.value
      if (b.sllabel.value!="") then scope.label=b.sllabel.value
      else if (b.sdlabel.value!="") then scope.label=b.sdlabel.value
      else scope.label=b.salabel.value
      if (b.sgloss.value!="") then scope.gloss=b.sgloss.value.replace(/\n/g,"<p>\n")
      if (b.slat.value!="") then scope.lat=b.slat.value
      if (b.slng.value!="") then scope.lng=b.slng.value
      scope.loading=2
  icons = ['http://maps.google.com/mapfiles/ms/icons/green-dot.png','http://maps.google.com/mapfiles/ms/icons/red-dot.png','http://maps.google.com/mapfiles/ms/icons/orange-dot.png','http://maps.google.com/mapfiles/ms/icons/blue-dot.png','http://maps.google.com/mapfiles/ms/icons/pink-dot.png','http://maps.google.com/mapfiles/ms/icons/purple-dot.png']
  !function openContext(concepts,replace)
    $timeout($scope.updateDisplay)
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
      response <-! sparql.query(configuration.sparqlEndpoint,configuration.propertiesQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.propertiesQuery.promise}).then(_,handleError)
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
    response <-! sparql.query(configuration.sparqlEndpoint,configuration.infoQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.infoQuery.promise}).then(_,handleError)
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
    do
      begS= if beg? then '"'+beg.toISOString! + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>' else '"foo"'
      endS= if end? then '"'+end.toISOString! + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>' else '"foo"'
      count = 0
      eventsD = []
      eventsM = []
      eventsY = []
      eventsO = []
      total = 0
      colors = ['blue','green','red']
      images = ['dull-blue-circle.png','dull-green-circle.png','dull-red-circle.png','dark-blue-circle.png','dark-green-circle.png','dark-red-circle.png','blue-circle.png','green-circle.png','red-circle.png']
      context.cmap = {}
      for id1,q of configuration.temporalQueries
        total++
        let id = id1
          cancelers['temporalQuery_' + id] = $q.defer!
          response <-! sparql.query(q.endpoint,q.query.replace(/<CONCEPTS>/g,sconcepts).replace(/<BEG>/g,begS).replace(/<END>/g,endS).replace(/<LAT>/g,context.lat ? '""').replace(/<LNG>/g,context.lng ? '""'),{timeout: cancelers['temporalQuery_' + id].promise}).then(_,handleError)
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
              link: if binding.url? then $state.href('home',{url:binding.url.value}) else 'javascript:openContext("'+sparql.bindingToString(binding.concept)+'")'
              durationEvent: false
              title: binding.slabel.value
              description: if binding.sdescription? then binding.sdescription.value else ''
            array.push(obj)
            eventsO.push(obj)
            context.cmap[id]=colors[count % colors.length]
          if ++count == total
            tsize = (eventsD.length+eventsM.length+eventsY.length)
            if tsize==0 then context.cmap=void
            else
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
                intervalPixels: 100
              ))
              for i from 1 til bandInfos.length
                bandInfos[i].syncWith = i - 1
                bandInfos[i].highlight = true
              tldiv = angular.element($window.document.getElementById('timeline'))
              tldiv.replaceWith('<div id="timeline"></div>')
              tl = Timeline.create($window.document.getElementById('timeline'),bandInfos)
              eventsO.sort (a,b) -> a.start - b.start
              tl.getBand(0).setCenterVisibleDate(eventsO[Math.floor(eventsO.length/2)].start)
    if (context.lat? && context.lng?)
      $scope.context.linkedLocations = []
      for id1,q1 of configuration.locationQueries
        let id = id1, q=q1
          cancelers['locationQuery_' + id] = $q.defer!
          response <-! sparql.query(q.endpoint,q.query.replace(/<CONCEPTS>/g,sconcepts).replace(/<LATLNG>/g,"(#{context.lat} #{context.lng})"),{timeout: cancelers['locationQuery_' + id].promise}).then(_,handleError)
          for binding in response.data.results.bindings when binding.concept?
            $scope.context.linkedLocations.push({icon:icons[id],concept:sparql.bindingToString(binding.concept),label:binding.label.value,lat:binding.lat.value,lng:binding.lng.value})
    cancelers.relatedEntitiesQuery = $q.defer!
    response <-! sparql.query(configuration.sparqlEndpoint,configuration.relatedEntitiesQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.relatedEntitiesQuery.promise}).then(_,handleError)
    for binding in response.data.results.bindings when binding.concept? then sconcepts += ' ' + sparql.bindingToString(binding.concept)
    cancelers.labelQuery = $q.defer!
    response <-! sparql.query(configuration.sparqlEndpoint,configuration.allLabelsQuery.replace(/<CONCEPTS>/g,sconcepts),{timeout: cancelers.labelQuery.promise}).then(_,handleError)
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
    context.linkedResources = []
    context.relatedQueriesRunning = 0
    context.linkedResourcesCount = 0
    for id1,q1 of configuration.relatedQueries
      let id = id1, q=q1
        cancelers['linkedResourcesQuery_' + id] = $q.defer!
        context.relatedQueriesRunning++
        if (q.query)
          response <-! sparql.query(q.endpoint,q.query.replace(/<CONCEPTS>/g,sconcepts).replace(/<CONCEPTSLABELS>/g,conceptLabels).replace(/<LABELS>/g,labels).replace(/<BEG>/g,begS).replace(/<END>/g,endS),{timeout: cancelers['linkedResourcesQuery_' + id].promise}).then(_,handleError)
          --context.relatedQueriesRunning
          if response.data.results.bindings.length>0 and response.data.results.bindings[0].url?
            res=
                title: q.name
                groups: []
            context.linkedResourcesCount++
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
              res.groups.push(gr)
            context.linkedResources[id]=res
        else
          response <-! $http.get(q.endpoint.replace(/<QUERY>/g,encodeURI(larr.join(' OR ')))).then(_,handleError)
          --context.relatedQueriesRunning
          lrmap={}
          res=
            title: q.name
            groups: []
          if q.type=='Europeana'
            for doc in response.data.docs
              lrmap.{}[doc.sourceResource.language?[0].name].[][doc.sourceResource.type].push({url:doc.isShownAt,imageURL:doc.object,description:(if Array.isArray(doc.sourceResource.description) then doc.sourceResource.description.join(', ') else doc.sourceResource.description),source:doc.provider.name,label:if Array.isArray(doc.sourceResource.title) then doc.sourceResource.title.join(', ') else doc.sourceResource.title})
          else if q.type=='OpenSearch'
            for doc in response.data.Results
              lrmap.{}[doc.LANGUAGE[0]].[][''].push({url:doc.URI,imageURL:doc.THUMBNAIL?[0],description:doc.TOPIC?.join(', '),label:doc.TITLE.join(', ')})
          else if q.type=='Atom'
            results = []
            for entry in angular.element(new DOMParser!.parseFromString(response.data,"application/xml")).find('entry')
              e = angular.element(entry)
              results.push({label:e.children('title').text!, url:e.children('link[type="text/html"]').attr('href'),description:$sce.trustAsHtml(e.children('summary').text!)})
            lrmap['']={'':results}
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
          haveResources = false
          for lang,typeMap of lrmap
            gr = {group:lang,resources:[]}
            for type,values of typeMap
              if (type!='') then gr.resources.push({group:type})
              for value in values
                haveResources = true
                gr.resources.push(value)
            res.groups.push(gr)
          if haveResources then context.linkedResources[id]=res
  $scope.openContext1 = (event,concept) !-> $scope.openContext2(concept)
  $scope.openContext2 = (concept) !->
    response <-! sparql.query(configuration.sparqlEndpoint,configuration.expandEquivalentConceptsQuery.replace(/<ID>/g,concept)).then(_,handleError)
    concepts = []
    for binding in response.data.results.bindings
      concepts.push(sparql.bindingToString(binding.concept))
    openContext(concepts)
  $window.openContext = $scope.openContext2
  $scope.errors = []
  !function handleError(response)
    $scope.errors.push({ errorSource : response.config.url, errorStatus : response.status + ( if (response.statusText) then " ("+response.statusText+")" else ""), errorRequest : response.config.data ? response.config.params?.query, errorMessage: response.data })
  !function runAnalysis(textDivs)
    texts = [textDiv.textContent for textDiv in textDivs]
    query  = ""
    for text in texts then query+=text+" "
    /*lastIndex = 0
    escapedTexts = ""
    for text in texts
      for text2 in text.split('\n')
        escapedTexts+= '"' + sparql.sanitize(text2) + '" '
        cLastIndex = text2.match(/\s+/g)?.length ? 0
        if (cLastIndex>lastIndex) then lastIndex=cLastIndex */
    $scope.findQueryRunning = true
    /*query = configuration.findQuery.replace(/<WORD_INDICES>/g,[0 to lastIndex].join(" ")).replace(/<TEXTS>/g,escapedTexts)
    response <-! sparql.query(configuration.sparqlEndpoint,query).then(_,handleError) */
    promise = if configuration.arpaURLs instanceof Array
      ret = $q.defer!
      ret.resolve(configuration.arpaURLs)
      ret.promise
    else
      $http.post('http://demo.seco.tkk.fi/las/identify',$.param({text:query}),{headers: {'Content-Type': 'application/x-www-form-urlencoded'}}).then (response) ->
        ret = configuration.arpaURLs[response.data.locale]
        if (!ret?) then ret = configuration.arpaURLs._
        ret
    arpaURLs <-! promise.then(_,handleError)
    promises = [ $http.post(findURL,$.param({text:query}),{headers: {'Content-Type': 'application/x-www-form-urlencoded'}}).catch((error) -> "") for findURL in arpaURLs ]
    responses <-! $q.all(promises).then(_,handleError)
    combinedResults = []
    for response,index in responses then if response.data? then for result in response.data.results
      if (!result.properties.source?) then result.properties.source=[index+1]
      combinedResults.push(result)
    $scope.findQueryRunning = false
    ngramsToConcepts = {}
    for c in combinedResults
      c.properties.source.sort((a,b) -> parseInt(a)-parseInt(b))
    combinedResults.sort((a,b)->
      ret=(b.label.match(/ +/g)?.length ? 0) - (a.label.match(/ +/g)?.length ? 0)
      if ret!=0 then ret else parseInt(a.properties.source[0]) - parseInt(b.properties.source[0])
    )
    for c in combinedResults
      for m in c.matches
        ngramsToConcepts[][m].push(c)
    texts2 = [[text] for text in texts]
    for ngram, bindings of ngramsToConcepts
#      ngram = ( bfrmap[baseform] for baseform in label.split(' ') ).join(' ')
      re = new XRegExp('(^|.*?[\\p{P}\\p{Z}])('+ngram.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')+')(?=[\\p{P}\\p{Z}]|$)','g')
      for ntexts in texts2
        i = 0
        while (i<ntexts.length)
          if (typeof ntexts[i] is "string" && ntexts[i].indexOf(ngram)>=0)
            nntexts = XRegExp.split(ntexts[i],re)
            ntexts.splice(i,1)
            for text in nntexts
              if (text==ngram)
                nscope = $scope.$new(true)
                nscope.class = bindings[0].properties.source[0] # bindings[0].order.value
                nscope.concepts = []
                for binding in bindings
                  # concept = sparql.bindingToString(binding.concept)
                  concept = '<'+binding.id+'>'
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
  if (!$stateParams.url?) then $state.go('home',{url:configuration.defaultURL})
  else
    if (!$scope.context)
      response <-! sparql.query(configuration.sparqlEndpoint,configuration.findContextByDocumentURLQuery.replace(/<ID>/g,'<'+$stateParams.url+'>')).then(_,handleError)
      if (response.data.results.bindings.length==1 && response.data.results.bindings[0].id?) then openContext([sparql.bindingToString(response.data.results.bindings[0].id)],true)
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
      $window.document.title = cd.body.getElementsByTagName("title")[0].textContent
      angular.element(cd.body).find('a').click (event) !->
        $state.go('home',{url:event.target.href})
        event.preventDefault!
      angular.element(cd.body).find('p,div,span').contents().filter(-> this.nodeType == 3 && this.parentNode.childNodes.length>1).replaceWith ->
        span = $window.document.createElement('span')
        span.textContent=this.textContent
        span
      runAnalysis(angular.element(cd.body).find('a,p,div,span').contents().filter(-> this.nodeType == 3 && this.parentNode.childNodes.length==1).parent())
