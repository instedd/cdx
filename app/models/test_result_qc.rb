class TestQcResult < ActiveRecord::Base
  # include AutoUUID
  # include Entity

  belongs_to :laboratory_sample

  has_attached_file :picture, styles: { card: "130x130>" }, default_url: "card-unkown.png"

  # def self.entity_scope
  #   "test_result_qc"
  # end

end
