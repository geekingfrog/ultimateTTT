App.ApplicationController = Ember.Controller.extend({
  init: ->
    @_super()
    socket.on("error", ({error}) -> toastr.error(error))
})
