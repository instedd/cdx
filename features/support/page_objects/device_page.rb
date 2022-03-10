class DeviceSetupSection < SitePrism::Section
  element :view_instructions, :link, 'View instructions'

  element :online_support, :link, 'online support'
end

class DeviceSetupPage < CdxPageBase
  set_url '/devices/{id}/setup{?query*}'

  section :setup, DeviceSetupSection, '[data-react-class="DeviceSetup"]'

  def open_view_instructions
    setup.view_instructions.click
    yield setup if block_given?
  end

  def id
    url_matches['id'].to_i
  end

  def device
    Device.find(self.id)
  end
end

class DevicePage < DeviceSetupPage
  set_url '/devices/{id}{?query*}'

  element :edit, "a[title='Edit']"

  section :tab_header, '.tabs' do
    element :performance, :link, 'Performance'
    element :setup, :link, 'Setup'
  end

  section :tabs_content, '.tabs-content' do
    element :explore_tests, :link, 'Explore tests'
  end

  section :tests_run, TestsRun, '#tests_run'

  def shows_deleted?
    page.has_css?('h2.deleted')
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
  section :site, CdxSelect, "label", text: "SITE"
  element :serial_number, :field, "Serial number"
end
