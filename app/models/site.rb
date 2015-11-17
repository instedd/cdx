class Site < ActiveRecord::Base
  include AutoUUID
  include Resource

  belongs_to :institution
  has_one :user, through: :institution
  has_many :devices, dependent: :restrict_with_exception
  has_many :test_results
  has_many :sample_identifiers
  has_many :samples, through: :sample_identifiers

  belongs_to :parent, class_name: "Site"
  has_many :children, class_name: "Site", foreign_key: "parent_id"

  acts_as_paranoid

  validates_presence_of :institution
  validate :same_institution_as_parent
  validates_presence_of :name

  after_create :compute_prefix

  attr_writer :location

  def location(opts={})
    @location = nil if @location_opts.presence != opts.presence
    @location_opts = opts
    @location ||= Location.find(location_geoid, opts)
  end

  def self.preload_locations!
    locations = Location.details(all.map(&:location_geoid).uniq).index_by(&:id)
    all.to_a.each do |site|
      site.location = locations[site.location_geoid]
    end
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

  def path
    prefix.split(".")
  end

  def to_s
    name
  end

  def self.prefix(id)
    Site.find(id).prefix
  end

  private

  def compute_prefix
    if parent
      self.prefix = "#{parent.prefix}.#{uuid}"
    else
      self.prefix = uuid
    end
    self.save!
  end

  def same_institution_as_parent
    if parent && parent.institution != self.institution
      self.errors.add(:institution, "must match parent site institution")
    end
  end
end
