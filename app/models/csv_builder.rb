class CSVBuilder
  def initialize elements, options={}
    @elements = elements
    @actual_columns = elements.first.try(:keys)

    if options[:column_names]
      @columns = options[:column_names]
    else
      @columns = @actual_columns
    end
  end

  def build csv
    if @columns
      csv << @columns

      @elements.each do |element|
        csv << @actual_columns.map {|column| element[column]}
      end
    end

    csv
  end
end
