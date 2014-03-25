class WorkGroup < ActiveRecord::Base
  belongs_to :user
  has_many :subscribers
  has_many :devices

  if Rails.env.test?
    def index_name
      "cpd_work_group_#{id}_test"
    end
  else
    def index_name
      "cpd_work_group_#{id}"
    end
  end

  def report_provider
    ElasticRecord.for index_name, 'report'
  end
end
