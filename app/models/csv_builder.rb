class CSVBuilder
  def initialize events
    @events = events
    @columns = events.first.try(:keys)
  end

  def build csv
    if @columns
      csv << @columns

      @events.each do |event|
        csv << @columns.map {|column| event[column]}
      end
    end

    csv
  end
end
