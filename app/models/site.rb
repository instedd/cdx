class Site < ActiveRecord::Base
  include AutoUUID
  include Resource

  belongs_to :institution
  has_one :user, through: :institution
  has_many :devices
  has_many :test_results, through: :devices

  validates_presence_of :institution
  validates_presence_of :name

  attr_writer :location

  def location(opts={})
    @location = nil if @location_opts != opts
    @location_opts = opts
    @location ||= Location.find(location_geoid, opts)
  end

  def self.filter_by_owner(user, check_conditions)
    if check_conditions
      joins(:institution).where(institutions: {user_id: user.id})
    else
      self
    end
  end

  def filter_by_owner(user, check_conditions)
    institution.user_id == user.id ? self : nil
  end

  def self.filter_by_query(query)
    if institution = query["institution"]
      where(institution_id: institution)
    else
      self
    end
  end

  def self.csv_builder(sites)
    CSVBuilder.new sites
  end

  def filter_by_query(query)
    if institution = query["institution"]
      if institution_id == institution.to_i
        self
      else
        nil
      end
    else
      self
    end
  end

  def to_s
    name
  end
end
