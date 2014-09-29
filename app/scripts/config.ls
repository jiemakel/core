angular.module('app', ['ngMap','wu.staticGmap','angularify.semantic.popup', 'ui.router', 'fi.seco.prefix', 'fi.seco.sparql'])
	.config ($stateProvider, $urlRouterProvider) !->
		$stateProvider
		.state 'home',
			url: '/?data&restEndpoint&sparqlEndpoint&graphIRI&configuration',
			templateUrl: 'partials/main.html',
			controller: 'MainCtrl'
		$urlRouterProvider.otherwise '/'
