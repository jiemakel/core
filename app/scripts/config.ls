angular.module('app', ['ngMap','wu.staticGmap','angularify.semantic.popup', 'ui.router', 'fi.seco.prefix', 'fi.seco.sparql'])
  .config ($stateProvider, $urlRouterProvider) !->
    $stateProvider.state 'home',
      url: '/?concepts&url'
      templateUrl: 'partials/main.html'
      controller: 'MainCtrl'
      reloadOnSearch: false
    $urlRouterProvider.otherwise '/'
