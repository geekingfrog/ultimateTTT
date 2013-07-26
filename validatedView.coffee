################################################################################ 
# behaves like a regular textField with two differences:
#   * Do not directly supply class to the view. Instead, supply staticClasses
#   as a string.
#   * Provide a binding called invalidCondition to add or remove the class. This
#   should be provided as a computed property.
#
#   The class "invalid" is added to the input field when the focus has been lost
#   at least one time, and the invalidCondition returns a truthy value
#
#   Usage example:
#     {{ view App.ValidatedTextField type="email"
#     autofocus="autofocus"
#     placeholder="e-mail"
#     valueBinding=email
#     staticClasses="input-email"
#     invalidConditionBinding=isEmailInvalid
#     name="email"
#     }}
#
################################################################################ 

App.ValidatedTextField = Ember.TextField.extend({
  classNameBindings: ["staticClasses", "invalidClass"]
  invalidClass: Ember.computed( ->
    if @get("focusedOut") and @get("invalidCondition")
      return "invalid"
    else
      return ""
  ).property("invalidCondition", "focusedOut", "foo")

  focusedOut: false
  focusOut: (ev) -> @set("focusedOut", true)
})

