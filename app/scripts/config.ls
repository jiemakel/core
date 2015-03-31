var loaded
angular.module('app', ['ngMap','ngSanitize','wu.staticGmap', 'ui.router', 'ui.layout', 'fi.seco.prefix', 'fi.seco.sparql','fi.seco.cors-proxy-interceptor'])
  .config ($stateProvider, $urlRouterProvider) !->
    $stateProvider.state 'home',
      url: '/?url'
      resolve:
        init : ->
          loaded.promise
      templateUrl: 'partials/main.html'
      controller: 'MainCtrl'
    $urlRouterProvider.otherwise '/'
  .run ($window,$q) !->
    loaded := $q.defer!
    $window.onload = loaded.resolve
  .directive 'ngEnter', ->
    (scope,element,attrs) !->
      element.bind "keydown keypress", (event) !->
        if event.which == 13
          scope.$apply(!->scope.$eval(attrs.ngEnter))
          event.preventDefault!
