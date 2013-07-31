"use strict"

App.MultiplayerRoute = Ember.Route.extend({
  beforeModel: ->
    username = App.get("username")
    if not username
      console.log "no username !"
      @transitionTo("index")

  setupController: (controller) ->
    controller.set("username", App.get("username"))
})

