$(function() {
  //Track changes on forms
  var form = $('form.new_device_model, form.edit_device_model');
  form.areYouSure({ silent: true });

  //Request confirmation on publish
  $('#device-model-publish').on('click', function(evt) {
    var msg = evt.target.name == 'publish'
      ? "Publishing this device model will make it available to all institutions."
      : "Withdrawing this device model will hide it from all institutions.";
    msg += " Are you sure you want to proceed?";
    if (form.hasClass('dirty')) {
      msg += "\n\nAny pending changes will be saved before proceeding.";
    }

    if (!window.confirm(msg)) {
      evt.preventDefault();
    }
  });
});
