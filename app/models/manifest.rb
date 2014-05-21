class Manifest < ActiveRecord::Base
  has_and_belongs_to_many :device_models

  before_save :update_models
  before_save :update_version
  after_destroy :ensure_no_orphan_models
  after_save :ensure_no_orphan_models

  def update_models
    self.device_models = Array(metadata["device_models"] || []).map { |model| DeviceModel.find_or_create_by(name: model)}
  end

  def update_version
    self.version = metadata["version"]
  end

  def ensure_no_orphan_models
    DeviceModel.includes(:manifests).where('device_models_manifests.manifest_id' => nil).destroy_all
  end

  def metadata
    JSON.parse(self.definition)["metadata"]
  end
end
