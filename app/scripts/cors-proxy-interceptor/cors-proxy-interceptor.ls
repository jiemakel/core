angular.module('fi.seco.cors-proxy-interceptor',[]).config ($httpProvider) !->
  $httpProvider.interceptors.push ($q,$injector) ->
    var $http
    { 'responseError' : (response) ->
      if (response.status <= 0)
        $http := $http ? $injector.get '$http'
        console.log(response.config.url,response.config.url.replace(/^(https?):(?:\/|%2F)/,'$1'))
        response.config.url='http://ldf.fi/corsproxy/'+response.config.url.replace(/^(https?):(?:\/|%2F)/,'$1')
        $http(response.config)
      else $q.reject(response)
    }
