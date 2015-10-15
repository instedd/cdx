$(function() {
  //Only run on device new with an institution dropdown
  if ($('form.new_device').length > 0 && $('#device_institution_id:visible').length > 0) {

    //Index device models by id
    var deviceModelsById = _.indexBy(gon.device_models, 'id');
 
    //Initialize institution ddslick, if exists, and update device models dropdown by toggling unpublished models
    $('#device_institution_id').ddslick({
      onSelected: function(data) {
        var deviceModelDropdown = $('#device_device_model_id-dd-placeholder');
        var institutionId = parseInt(data.selectedData.value);
        var currentDeviceModelId = parseInt(deviceModelDropdown.data('ddslick').selectedData.value);

        $('.dd-options li', deviceModelDropdown).each(function(index, item) {
          var deviceModelId = parseInt($('.dd-option-value', item).val());
          var deviceModel = deviceModelsById[deviceModelId];

          //Show device model iff published or belongs to the selected institution
          var visible = !deviceModel || !!deviceModel.published_at || (deviceModel.institution_id == parseInt(institutionId));
          $(item).toggle(visible);

          //Go back to "select an item" if the current selection is now hidden
          if (deviceModelId == currentDeviceModelId && !visible) {
            deviceModelDropdown.ddslick('select', { index: 0 });
          }
        });
      }
    });
  }
});

