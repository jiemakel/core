angular.module('app', ['ngMap','wu.staticGmap','angularify.semantic.popup', 'ui.router', 'fi.seco.prefix', 'fi.seco.sparql'])
  .config ($stateProvider, $urlRouterProvider) !->
    $stateProvider.state 'home',
      url: '/?concepts&url'
      resolve:
        init : ($q,$window) ->
          ret = $q.defer!
          $window.onload = ret.resolve
          ret.promise
      templateUrl: 'partials/main.html'
      controller: 'MainCtrl'
      reloadOnSearch: false
    $urlRouterProvider.otherwise '/'
