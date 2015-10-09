$ ->
  # Track changes on forms
  form = $('form.new_device_model, form.edit_device_model')
  form.areYouSure({silent: true})

  # Request confirmation on publish
  $('#device-model-publish').on 'click', (evt) ->
    msg = if evt.target.name == 'publish'
      "Publishing this device model will make it available to all institutions."
    else
      "Withdrawing this device model will hide it from all institutions."

    msg += " Are you sure you want to proceed?"
    msg += "\n\nAny pending changes will be saved before proceeding." if form.hasClass('dirty')

    if not window.confirm(msg)
      evt.preventDefault()
