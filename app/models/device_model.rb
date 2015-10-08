class DeviceModel < ActiveRecord::Base

  include Resource

  before_destroy :destroy_devices!

  has_one :manifest, dependent: :destroy, inverse_of: :device_model
  has_many :devices, dependent: :restrict_with_exception

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

  def set_published_at
    self.published_at ||= DateTime.now
  end

  def unset_published_at
    self.published_at = nil
  end

  private

  def destroy_devices!
    raise ActiveRecord::RecordNotDestroyed, "Cannot destroy a published device model" if published?
    devices = self.devices.to_a
    raise ActiveRecord::RecordNotDestroyed, "Cannot destroy a device model with devices outside its institution" if devices.any?{|d| d.institution_id != institution_id}
    devices.each(&:destroy_cascade!)
    devices(true) # Reload devices relation so destroy:restrict does not prevent the record from being destroyed
  end
end
