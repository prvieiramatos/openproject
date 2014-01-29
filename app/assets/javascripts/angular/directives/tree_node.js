openprojectApp.directive('treeNode', [function() {
  return {
    restrict: 'A',
    scope: true,
    link: function(scope, element, attributes) {
      scope.row.dom_element = element;

      scope.$watch('row.expanded', function(expanded, formerlyExpanded) {
        if(expanded !== formerlyExpanded) scope.timeline.rebuildAll();
      });
    }
  };
}]);
