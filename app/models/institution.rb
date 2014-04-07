class Institution < ActiveRecord::Base
  belongs_to :user
  has_many :subscribers
  has_many :laboratories
  has_many :devices, through: :laboratories

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
end
