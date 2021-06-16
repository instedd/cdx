class TestQcResult < ActiveRecord::Base
  # include AutoUUID
  # include Entity

  belongs_to :laboratory_sample
  has_many :assays, class_name: "TestQcResultAssay", dependent: :destroy

  def assays=(pictures = [])
    pictures.each do |picture|
      assays.create picture: picture
    end
  end

  # def self.entity_scope
  #   "test_result_qc"
  # end
end
