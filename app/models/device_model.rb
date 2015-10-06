class DeviceModel < ActiveRecord::Base

  include Resource

  has_one :manifest, dependent: :destroy, inverse_of: :device_model
  has_many :devices
  belongs_to :institution, inverse_of: :device_models

  scope :published,   -> { where.not(published_at: nil) }
  scope :unpublished, -> { where(published_at: nil) }

  validates_uniqueness_of :name

  accepts_nested_attributes_for :manifest

  #This is kept for forward compatibility (we will have multiple manifests, published and unpublished)
  alias_method :current_manifest, :manifest

  def full_name
    if institution
      "#{name} (#{institution.name})"
    else
      name
    end
  end

  def published?
    !!published_at
  end
end
