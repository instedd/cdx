$ ->
  # Only run on device new or edit
  if $('form.edit_device').length > 0 or $('form.new_device').length > 0

    # Index device models by id
    deviceModelsById = _.indexBy(gon.device_models, 'id')

    # Initialize institution ddslick, if exists, and update device models dropdown by toggling unpublished models
    $('#device_institution_id').ddslick
      onSelected: (data) ->
        deviceModelDropdown = $('#device_device_model_id-dd-placeholder')
        institutionId = parseInt(data.selectedData.value)
        currentDeviceModelId = parseInt(deviceModelDropdown.data('ddslick').selectedData.value)

        $('.dd-options li', deviceModelDropdown).each (index, item) ->
          deviceModelId = parseInt($('.dd-option-value', item).val())
          deviceModel = deviceModelsById[deviceModelId]

          # Show device model iff published or belongs to the selected institution
          visible = !deviceModel || !!deviceModel.published_at || (deviceModel.institution_id == parseInt(institutionId))
          $(item).toggle(visible)

          # Go back to "select an item" if the current selection is now hidden
          if deviceModelId == currentDeviceModelId && !visible
            deviceModelDropdown.ddslick('select', {index: 0})

