module CdxFormHelper
  # Creates a form builder instance using CdxFormBuilder
  def cdx_form_for(record_or_name_or_array, *args, &block)
    options = args.extract_options!
    form_for(record_or_name_or_array, *(args << options.merge(builder: FormFieldBuilder))) do |form|
      yield form

      # `form_errors` could be called in the block, but that doesn't matter because a
      # second call is a no-op.
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
    if block_given?
      value = @template.capture(&block)
    else
      value = @template.content_tag("div", options[:value], class: "value")
    end

    @template.render partial: "form_builder/field", locals: {
      form: self,
      method: method,
      value: value,
      options: objectify_options(options),
    }
  end

  # Renders all error messages for *attribute*.
  def field_errors(attribute)
    messages = @object.errors.full_messages_for(attribute)
    return if messages.empty?

    errors_to_show.delete attribute

    @template.render partial: "form_builder/field_errors", locals: {
      form: self,
      messages: messages,
    }
  end

  # Renders form errors for fields that have not been handled by a dedicated
  # `#field` errors.
  def form_errors(options = {})
    rendered = @template.render partial: "form_builder/form_errors", locals: {
      form: self,
      messages: error_messages_to_show.values.flatten,
    }

    log_unhandled_errors unless options[:ignore_unhandled]

    rendered
  ensure
    @errors_to_show = []
  end

  private

  def errors_to_show
    @errors_to_show ||= @object.errors.keys
  end

  def error_messages_to_show
    Hash[errors_to_show.map do |attribute|
      messages = @object.errors.full_messages_for(attribute)
      next if messages.empty?
      [attribute, messages]
    end.compact]
  end

  def log_unhandled_errors
    unhandled_errors = error_messages_to_show.dup
    unhandled_errors.delete(:base)
    return if unhandled_errors.empty?

    if Rails.env.test?
      raise "Unhandled form errors in #{@object.model_name}: #{unhandled_errors}"
    end

    Rails.logger.info "Unhandled form errors in #{@object.model_name}: #{unhandled_errors}"
    Raven.capture_message("Unhandled form errors",
      form: @object.model_name,
      errors: unhandled_errors,
    )
  end
end
