class DeviceSetupSection < SitePrism::Section
  element :view_instructions, :link, 'View instructions'

  element :online_support, :link, 'online support'
end

class DeviceSetupPage < CdxPageBase
  set_url '/devices/{id}/setup'

  section :setup, DeviceSetupSection, '[data-react-class="DeviceSetup"]'

  def open_view_instructions
    setup.view_instructions.click
    yield setup if block_given?
  end
end

class DevicePage < DeviceSetupPage
  set_url '/devices/{id}'

  element :edit, "a[title='Edit']"

  section :tab_header, '.tabs' do
    element :setup, :link, 'Setup'
  end

  section :tabs_content, '.tabs-content' do
    element :explore_tests, :link, 'Explore tests'
  end
end

class DeviceEditPage < CdxPageBase
  set_url '/devices/{id}/edit{?query*}'

  element :delete, :link, 'Delete'
end

class NewDevicePage < CdxPageBase
  set_url '/devices/new{?query*}'

  section :device_model, CdxSelect, "label", text: /Device Model/i
  element :name, :field, "Name"
  element :serial_number, :field, "Serial number"
end
