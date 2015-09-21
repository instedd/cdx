# Ensure TestResult class is loaded first from app/models before reopening it to ensure its super class is properly set
TestResult; class TestResult
  def self.create_and_index params={}
    test = self.make params
    TestResultIndexer.new(test).index(true)
    test
  end
end
