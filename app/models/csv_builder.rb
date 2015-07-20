class CSVBuilder
  def initialize elements, options={}
    @elements = elements

    if options[:column_names]
      @columns = options[:column_names]
    else
      @columns = elements.first.try(:keys)
    end
  end

  def build csv
    if @columns
      csv << @columns

      @elements.each do |element|
        element = element.with_indifferent_access
        csv << @columns.map {|column| element[column]}
      end
    end

    csv
  end
end
