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
  def form_errors
    @template.render partial: "form_builder/form_errors", locals: {
      form: self,
      messages: error_messages_to_show,
    }
  end

  # Renders the final section of the form which usually includes the submit
  # button and other actions.
  def form_actions
    @template.render partial: "form_builder/form_actions", locals: {
      form: self,
      body: yield
    }
  end

  private

  def errors_to_show
    @errors_to_show ||= @object.errors.keys
  end

  def error_messages_to_show
    errors_to_show.map do |attribute|
      @object.errors.full_messages_for(attribute)
    end.flatten.tap do
      @errors_to_show = []
    end
  end
end
