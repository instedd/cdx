class Institution < ActiveRecord::Base
  belongs_to :user
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

  def self.filter_by_owner(user)
    where(user_id: user.id)
  end

  def filter_by_owner(user)
    user_id == user.id ? self : nil
  end

  def self.filter_by_resource(resource)
    unless resource =~ /cdpx:institution\/(.*)/
      return nil
    end

    match = $1
    if match == "*"
      return self
    end

    where(id: match)
  end

  def filter_by_resource(resource)
    unless resource =~ /cdpx:institution\/(.*)/
      return nil
    end

    match = $1
    if match == "*"
      return self
    end

    if match.to_i == id
      return self
    end

    nil
  end

  def to_s
    name
  end
end
