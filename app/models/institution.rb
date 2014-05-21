class Institution < ActiveRecord::Base
  resourcify

  belongs_to :user
  has_many :subscribers, dependent: :destroy
  has_many :laboratories, dependent: :destroy
  has_many :devices, dependent: :destroy

  if Rails.env.test?
    def index_name
      "cpd_institution_#{id}_test"
    end
  else
    def index_name
      "cpd_institution_#{id}"
    end
  end

  def test_result_provider
    ElasticRecord.for index_name, 'test_result'
  end

  def to_s
    name
  end
end
