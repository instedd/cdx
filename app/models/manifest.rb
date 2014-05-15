class Manifest < ActiveRecord::Base
  has_and_belongs_to_many :device_models

  before_save :update_models
  # before_save :update_version

  def update_models
    JSON.parse(self.definition)["device_models"].each { |model| self.device_models << (DeviceModel.find_or_create_by(name: model))}
  end

  # def update_version
  #   self.version = 1
  # end
end
