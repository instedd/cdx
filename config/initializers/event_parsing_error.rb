class EventParsingError < RuntimeError
  def self.incomplete_data
    new "Incomplete data"
  end
end
