App.ConnectView = Ember.View.extend({
  templateName: "connect"

  isUsernameValid: (-> @get("username").length > 3).property("username")

  errorMessage: (->
    if @get("username").length <= 3
      return "too short"
  ).property("username")

  isErrorMessageVisible: (->
    @get("focusedOut") and not @get("isUsernameValid")
  ).property("focusedOut", "isUsernameValid")

  isButtonDisabled: (->
    if @get("focusedIn")
      return !@get("isUsernameValid")
    else
      return true
  ).property("isUsernameValid", "focusedIn")

  focusedOut: false
  focusOut: -> @set("focusedOut", true)

  focusedIn: false
  focusIn: -> @set("focusedIn", true)

  click: (ev) ->
    return unless @get("isUsernameValid")
    if ev.target.nodeName is "A"
      @get("controller").send("connect")
    return

  connect: ->
    console.log "connect in view"
})

App.ValidatedTextField = Ember.TextField.extend({
  classNameBindings: ['isValid::error']
  isValid: true
})
