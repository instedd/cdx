class Manifest < ActiveRecord::Base
  has_and_belongs_to_many :models

  before_save :update_models
  before_save :update_version
  after_destroy :ensure_no_orphan_models
  after_save :ensure_no_orphan_models

  def update_models
    self.models = Array(JSON.parse(self.definition)["models"] || []).map { |model| Model.find_or_create_by(name: model)}
  end

  def update_version
    self.version = JSON.parse(self.definition)["version"]
  end

  def ensure_no_orphan_models
    Model.includes(:manifests).where('manifests_models.manifest_id' => nil).destroy_all
  end
end
