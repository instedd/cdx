RSpec::Matchers.define :eq_hash do |expected|
  match do |actual|
    actual == expected
  end
  failure_message_for_should do |actual|
    diff = HashDiff.diff(expected, actual).join("\n ")
    "expected hashes to be equal, diff was:\n #{diff}"
  end
end

