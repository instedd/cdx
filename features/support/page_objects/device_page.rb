class DevicePage < SitePrism::Page
  include CdxPageHelper

  set_url '/devices/{id}'

  def open_device_setup_tab
    click_link 'Setup'
    wait_for_ajax
    yield DeviceSetupPage.new
  end

  class DeviceSetupPage < DevicePage
    set_url '/devices/{id}/setup'

    def open_view_instructions
      click_link 'View instructions'
      remove_target_blank!
    end
  end
end
