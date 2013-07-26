# App.IndexRoute = Ember.Route.extend()

App.IndexController = Ember.Controller.extend({
  isUsernameInvalid: (->
    if @get("username").length < 5
      return "Too short"
    else
      return false
  ).property("username")
  username: ""

})
