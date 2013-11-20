angular.module('Directory.account.models', [])
.factory('Plan', ['Model', function (Model) {
  var Plan = Model({url:'/api/plans', name: 'plan'});

  Plan.community = function () {
  	return this.get().then(function (plans) {
      var community;
      angular.forEach(plans, function (plan) {
        if (typeof community == 'undefined' && plan.amount == 0) {
          community = plan;
        }
      });
      return community;
  	});
  };

  return Plan;

}]);