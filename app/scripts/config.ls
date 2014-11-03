var loaded
angular.module('app', ['ngMap','wu.staticGmap','angularify.semantic.popup', 'ui.router', 'fi.seco.prefix', 'fi.seco.sparql','fi.seco.cors-proxy-interceptor'])
  .config ($stateProvider, $urlRouterProvider) !->
    $stateProvider.state 'home',
      url: '/?url&concepts'
      resolve:
        init : ->
          loaded.promise
      templateUrl: 'partials/main.html'
      controller: 'MainCtrl'
      reloadOnSearch : false
    $urlRouterProvider.otherwise '/'
  .run ($window,$q) !->
    loaded := $q.defer!
    $window.onload = loaded.resolve
