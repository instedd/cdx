class EventCSVBuilder
  def initialize events
    @events = events
    @columns = events.first.keys
  end

  def build csv
    csv << @columns

    @events.each do |event|
      csv << @columns.map {|column| event[column]}
    end
  end
end
