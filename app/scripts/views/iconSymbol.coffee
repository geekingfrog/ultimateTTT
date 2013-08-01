# used to dispaly the symbol for the current player
# A cross ('x') or an empty circle ('o').
App.IconSymbolView = Ember.View.extend({
  # template: Ember.Handlebars.compile("<i {{bindAttr class=view.iconSymbol}}></i>bla")
  template: Ember.Handlebars.compile(" ")
  classNameBindings: ['iconSymbol']
  tagName: 'i'
  iconSymbol: (->
    symbol = @get("symbol")
    if symbol is 'x'
      return "icon-remove"
    else if symbol is 'o'
      return "icon-circle-blank"
    else
      return ""
  ).property("symbol")
})

