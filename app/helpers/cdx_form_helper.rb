module CdxFormHelper
  # Creates a form builder instance using CdxFormBuilder
  def cdx_form_for(record_or_name_or_array, *args, &block)
    options = args.extract_options!
    form_for(record_or_name_or_array, *(args << options.merge(builder: FormFieldBuilder))) do |form|
      yield form

      concat form.form_errors
    end
  end
end

# This form builder adds some methods for showing error messages.
# It keeps track which error messages are shown directly with the corresponding
# fields.
class FormFieldBuilder < ActionView::Helpers::FormBuilder
  # Renders a form field including label, value (block) and error messages.
  def form_field(method, options = {}, &block)
    options = { full_message: true }.merge(options)

    @template.render layout: "form_builder/field", locals: {
      form: self,
      method: method.to_sym,
      options: objectify_options(options),
    } do
      if block
        @template.capture(&block)
      else
        @template.content_tag("div", options[:value], class: "value")
      end
    end
  end

  # Renders all error messages for *attribute*.
  def field_errors(attr_name, full_message: true)
    error_key = prefixed_error_key(attr_name)
    messages =
      if full_message
        object_errors.full_messages_for(error_key)
      else
        object_errors[error_key]
      end
    return if messages.empty?

    errors_to_show.delete(error_key)

    @template.render partial: "form_builder/field_errors", locals: {
      form: self,
      messages: messages,
    }
  end

  # Renders form errors for fields that have not been handled by a dedicated
  # `#field` errors.
  #
  # This method is called in `cdx_form_for` and should not be called explicitly
  # in the form body.
  def form_errors(options = {})
    rendered = @template.render partial: "form_builder/form_errors", locals: {
      form: self,
      messages: error_messages_to_show.values.flatten,
    }

    log_unhandled_errors unless options[:ignore_unhandled]

    rendered
  ensure
    clear_errors_to_show
  end

  # Renders the final section of the form which usually includes the submit
  # button and other actions.
  def form_actions(&block)
    @template.render(layout: "form_builder/form_actions", locals: {
      form: self,
    }) do
      @template.capture(&block)
    end
  end

  def fields_for(record_name, record_object = nil, fields_options = {}, &block)
    fields_options[:nested_errors_namespace] = prefixed_error_key(record_name)

    super(record_name, record_object = nil, objectify_options(fields_options)) do |form|
      form.errors_to_show = errors_to_show
      block.call(form)

      @template.concat form.form_errors
    end
  end

  def has_error?(attr_name)
    errors_to_show.include?(prefixed_error_key(attr_name))
  end

  # Returns `true` if the object has any errors.
  def has_errors?
    !object_errors.empty?
  end

  protected

  def errors_to_show=(errors_to_show)
    @errors_to_show = errors_to_show
  end

  private

  def errors_to_show
    @errors_to_show ||= object_errors.keys
  end

  def object_errors
    (@object || @options[:object]).errors
  end

  def prefixed_error_key(key)
    if nested_prefix = @options[:nested_errors_namespace]
      "#{nested_prefix}.#{key}"
    else
      key
    end.to_sym
  end

  def error_messages_to_show
    nested_prefix = @options[:nested_errors_namespace]
    nested_prefix = "#{nested_prefix}." if nested_prefix
    Hash[errors_to_show.map do |attribute|
      next if nested_prefix && !attribute.to_s.starts_with?(nested_prefix)

      messages = object_errors.full_messages_for(attribute)
      [attribute, messages] unless messages.empty?
    end.compact]
  end

  def clear_errors_to_show
    if nested_prefix = @options[:nested_errors_namespace]
      nested_prefix = "#{nested_prefix}."
      errors_to_show.delete_if { |key| key.to_s.starts_with?(nested_prefix) }
    else
      errors_to_show.clear
    end
  end

  def log_unhandled_errors
    unhandled_errors = error_messages_to_show.reject { |k, _| k == :base }
    return if unhandled_errors.empty?

    message = "Unhandled form errors in #{object_name}: #{unhandled_errors}"
    if Rails.env.test?
      raise message
    end

    Rails.logger.info message
    Raven.capture_message("Unhandled form errors",
      form: object_name,
      errors: unhandled_errors,
    )
  end
end
