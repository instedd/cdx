module DateProduced
  extend ActiveSupport::Concern

  def date_produced_description
    return unless date_produced

    date_produced.strftime(I18n.t('date.input_format.pattern'))
  end

  class_methods do
    def date_format
      { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
    end
  end
end
