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
    attr_name = attr_name.to_sym

    messages =
      if full_message
        @object.errors.full_messages_for(attr_name)
      else
        @object.errors[attr_name]
      end
    return if messages.empty?

    errors_to_show.delete(attr_name)

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
    if record_object.nil? && @object.respond_to?(record_name)
      record_object = @object.send(record_name)
    end

    super(record_name, record_object, objectify_options(fields_options)) do |form|
      # Clear errors that are handeld in the nested form
      form.errors_to_show.each do |nested_key|
        errors_to_show.delete("#{record_name}.#{nested_key}".to_sym)
      end

      block.call(form)

      @template.concat form.form_errors
    end
  end

  def has_error?(attr_name)
    errors_to_show.include?(attr_name.to_sym)
  end

  protected

  def errors_to_show
    @errors_to_show ||= @object.errors.keys
  end

  private

  def error_messages_to_show
    Hash[errors_to_show.map do |attribute|
      messages = @object.errors.full_messages_for(attribute)
      [attribute, messages] unless messages.empty?
    end.compact]
  end

  def log_unhandled_errors
    unhandled_errors = error_messages_to_show.reject { |k, _| k == :base }
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
