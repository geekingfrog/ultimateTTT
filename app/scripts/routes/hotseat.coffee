App.HotseatRoute = Ember.Route.extend({
  setupController: -> @controllerFor("game").reset()
})
