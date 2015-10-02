module ApplicationHelper
  extend ComponentsBuilder

  def has_access?(resource, action)
    Policy.can? action, resource, current_user, @current_user_policies
  end

  def check_access(resource, action)
    Policy.authorize action, resource, current_user, @current_user_policies
  end

  def flash_message
    res = nil

    keys = { :notice => 'flash_notice', :error => 'flash_error', :alert => 'flash_error' }

    keys.each do |key, value|
      if flash[key]
        html_option = { :class => "flash #{value}" }
        html_option[:'data-hide-timeout'] = 3000 if key == :notice
        res = content_tag :div, html_option do
          content_tag :div do
            flash[key]
          end
        end
      end
    end

    res
  end

  def cdx_table(&block)
    concat(content_tag(:table, capture(&block), class: "table row-href", cellpadding: "0", cellspacing: "0"))
  end

  define_component :card, sections: [:top, :bottom], attributes: [:image]

end
