class CSVEventParser
  DEFAULT_SEPARATOR = ";"

  def initialize(separator=DEFAULT_SEPARATOR)
    @separator = separator
  end

  def lookup(path, data)
    if (path.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1 || path.split(Manifest::PATH_SPLIT_TOKEN).size > 1
      raise "path nesting is unsupported for CSV Events"
    else
      data[path]
    end
  end

  def load(data)
    csv = CSV.new(data, col_sep: @separator)
    headers = csv.shift
    csv.map do |row|
      result = Hash.new
      headers.each_with_index do |header, index|
        result[header] = row[index]
      end
      result
    end
  end
end
