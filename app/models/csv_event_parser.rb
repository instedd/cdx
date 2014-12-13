class CSVEventParser
  def apply_selector(selector, data)
    if (selector.split(Manifest::COLLECTION_SPLIT_TOKEN)).size > 1 || selector.split(Manifest::PATH_SPLIT_TOKEN).size > 1
      raise "selector nesting is unsupported for CSV Events"
    else
      data[selector]
    end
  end

  def load_all(data)
    csv = CSV.parse data
    headers = csv.first
    csv[1..-1].map do |row|
      result = Hash.new
      headers.each_with_index do |header, index|
        result[header] = row[index]
      end
      result
    end
  end

  def load(data)
    load_all(data).first
  end

  def dump(data)
    CSV.generate_line(data.keys) + CSV.generate_line(data.values)
  end
end
