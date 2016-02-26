class CSVMessageParser
  DEFAULT_SEPARATOR = ";"
  DEFAULT_TOP_LINES_SKIPPED = 0

  def initialize(separator=DEFAULT_SEPARATOR, skip_lines_at_top=DEFAULT_TOP_LINES_SKIPPED)
    @separator = separator
    @skip_lines_at_top = skip_lines_at_top
  end

  def lookup(path, data, root = data)
    if path.split(Manifest::PATH_SPLIT_TOKEN).size > 1
      raise "path nesting is unsupported for CSV Messages"
    else
      data[path]
    end
  end

  def load(data, root_path = nil)
    csv = CSV.new(data, col_sep: @separator, skip_blanks: true)
    @skip_lines_at_top.times do
      csv.shift
    end
    headers = csv.shift
    csv.map do |row|
      result = {}
      headers.each_with_index do |header, index|
        result[header] = row[index]
      end
      result
    end
  end
end
