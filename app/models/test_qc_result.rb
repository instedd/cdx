class TestQcResult < ActiveRecord::Base
  # include AutoUUID
  # include Entity

  belongs_to :laboratory_sample

  has_many :test_qc_result_assays, dependent: :destroy
  accepts_nested_attributes_for :test_qc_result_assays, allow_destroy: true

  def files=(pictures = [])
    pictures.each do |picture|
      test_qc_result_assays.build(picture: picture)
    end
  end

  # def self.entity_scope
  #   "test_result_qc"
  # end
end
