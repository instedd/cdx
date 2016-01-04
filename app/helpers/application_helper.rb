module ApplicationHelper
  def has_access?(resource, action)
    Policy.can? action, resource, current_user
  end

  def check_access(resource, action)
    Policy.authorize action, resource, current_user
  end

  def has_access_to_sites_index?
    has_access?(Institution, Policy::Actions::CREATE_INSTITUTION_SITE) || check_access(Site, Policy::Actions::READ_SITE).exists?
  end

  def has_access_to_devices_index?
    has_access?(Institution, Policy::Actions::REGISTER_INSTITUTION_DEVICE) || check_access(Device, Policy::Actions::READ_DEVICE).exists?
  end

  def has_access_to_device_models_index?
    has_access?(Institution, Policy::Actions::REGISTER_INSTITUTION_DEVICE_MODEL) || check_access(DeviceModel, Policy::Actions::READ_DEVICE_MODEL).exists?
  end

  def has_access_to_test_results_index?
    has_access?(TestResult, Policy::Actions::QUERY_TEST)
  end

  def can_delegate_permissions?
    current_user.computed_policies.any? &:delegable?
  end

  def format_datetime(value, time_zone = nil)
    return nil unless value

    value = Time.parse(value) unless value.is_a?(Time)
    value = value.in_time_zone(time_zone) if time_zone
    I18n.localize(value, locale: current_user.locale, format: :long)
  end

  def flash_message
    res = nil

    keys = { :notice => 'flash_notice', :error => 'flash_error', :alert => 'flash_error' }

    keys.each do |key, value|
      if flash[key]
        html_option = { :class => "flash #{value}" }
        res = content_tag :div, html_option do
          content_tag :div do
            flash[key]
          end
        end
      end
    end

    res
  end

  define_component :card, sections: [:top, :actions, :bottom], attributes: [:image]
  define_component :cdx_table, sections: [:columns, :thead, :tbody, :actions], attributes: [:title]

  define_component :cdx_tabs do |c|
    c.section :headers, multiple: true, component: :cdx_tabs_header
    c.section :contents, multiple: true
  end
  define_component :cdx_tabs_header, attributes: [:title, :url]

  ViewComponents::ComponentsBuilder::Component.classes[:cdx_tabs].class_eval do
    def tab(options, &block)
      self.header options
      if block_given?
        self.content &block
      else
        self.content {}
      end
    end
  end

  define_component :cdx_select, attributes: [:form, :name, :value, :class]
  ViewComponents::ComponentsBuilder::Component.classes[:cdx_select].class_eval do
    def item(value, label)
      @data[:items] ||= []
      @data[:items] << {value: value.to_s, label: label}
    end

    def items(values, value_attr = nil, label_attr = nil)
      values.each do |value|
        item_value = resolve(value, value_attr)
        item_label = resolve(value, label_attr)
        self.item(item_value, item_label)
      end
    end

    private

    def resolve(obj, attr)
      if attr.nil?
        obj
      elsif obj.is_a?(Hash)
        obj[attr]
      else
        obj.send(attr)
      end
    end
  end

  def test_results_table(attributes)
    options = { filter: {} }
    options[:filter]['site.uuid'] = attributes[:filter][:site].uuid if attributes[:filter][:site]
    options[:filter]['device.uuid'] = attributes[:filter][:device].uuid if attributes[:filter][:device]

    react_component('TestResultsTable', filter: options[:filter])
  end

  def show_institution?(action, resource)
    ComputedPolicy.condition_resources_for(action, resource, current_user)[:institution].count > 1
  end

  def validation_errors(model)
    if model.errors.present?
      render partial: "shared/validation_errors", locals: { model: model }
    end
  end
end
