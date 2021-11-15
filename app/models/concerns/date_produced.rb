module DateProduced
  extend ActiveSupport::Concern

  included do
    validate :date_produced_is_a_date
  end

  def date_produced_is_a_date
    return if date_produced.blank?
    errors.add(:date_produced, "should be a date in #{self.class.date_produced_placeholder}") unless date_produced.is_a?(Time)
  end

  def date_produced_description
    if date_produced.is_a?(Time)
      return date_produced.strftime(I18n.t('date.input_format.pattern'))
    end

    date_produced
  end


  class_methods do
    def date_produced_placeholder
      date_format[:placeholder]
    end

    def date_format
      { pattern: I18n.t('date.input_format.pattern'), placeholder: I18n.t('date.input_format.placeholder') }
    end
  end
end