module DateDistanceHelper
  include ActionView::Helpers::DateHelper

  def years_between(first_date, second_date)
    distance_between(first_date, second_date, :years)
  end

  def months_between(first_date, second_date)
    distance_between(first_date, second_date, :months)
  end

  def days_between(first_date, second_date)
    distance_between(first_date, second_date, :days)
  end

  def hours_between(first_date, second_date)
    distance_between(first_date, second_date, :hours)
  end

  def minutes_between(first_date, second_date)
    distance_between(first_date, second_date, :minutes)
  end

  def seconds_between(first_date, second_date)
    distance_between(first_date, second_date, :seconds)
  end

  def milliseconds_between(first_date, second_date)
    seconds_between(first_date, second_date) * 1000
  end

  def distance_between(first_date, second_date, unit)
    second_date = DateTime.parse(second_date.to_s)
    first_date = DateTime.parse(first_date.to_s)
    distance_of_time_in_words_hash(first_date, second_date, accumulate_on: unit)[unit]
  end
end
