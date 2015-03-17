class HeadlessCSVEventParser
  DEFAULT_SEPARATOR = ";"

  def initialize(separator=DEFAULT_SEPARATOR)
    @separator = separator
  end

  def lookup(path, data)
    unless ManifestFieldValidation.new(nil).is_an_integer?(path)
      raise "Header lookup is unsupported for headless CSV Events"
    else
      data[path]
    end
  end

  def load(data)
    CSV.new(data, col_sep: @separator)
  end
end
