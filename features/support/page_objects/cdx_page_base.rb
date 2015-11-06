class CdxPageBase < SitePrism::Page
  include CdxPageHelper

  element :primary, ".btn-primary"

  def submit
    primary.click
    wait_for_submit
  end
end
