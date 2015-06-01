# Ensure TestResult class is loaded first from app/models before reopening it to ensure its super class is properly set
TestResult; class TestResult
  def self.create_and_index indexed_fields, params={}
    test = self.make params
    EventIndexer.new(indexed_fields, test).index
    test
  end
end
