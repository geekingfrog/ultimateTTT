# App.IndexRoute = Ember.Route.extend()
# App.set("username", "hardcoded-#{Date.now()}")

App.IndexController = Ember.Controller.extend({
  isUsernameInvalid: (->
    if @get("username").length < 5
      return "Too short"
    else
      return false
  ).property("username")
  username: ""

  connect: ->
    console.log "connect"
    username = @get "username"
    return if @get("isUsernameInvalid")
    App.set("username", username)
    console.log "connect with username: #{@get "username"}"
    @transitionToRoute("multiplayer")

})
