class TestQcResult < ActiveRecord::Base
  # include AutoUUID
  # include Entity

  belongs_to :laboratory_sample

  has_attached_file :picture, styles: { card: "130x130>" }, default_url: "card-unkown.png"
  validates_attachment_content_type :picture, content_type: /\Aimage\/.*\Z/

  # def self.entity_scope
  #   "test_result_qc"
  # end

end
