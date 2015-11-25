class Device < ActiveRecord::Base
  include Resource

  belongs_to :device_model
  belongs_to :institution
  belongs_to :site

  has_one :manifest, through: :device_model

  has_one :ssh_key, dependent: :destroy

  has_many :test_results
  has_many :device_messages
  has_many :device_logs
  has_many :device_commands

  serialize :custom_mappings, JSON

  attr_reader :plain_secret_key

  validates_uniqueness_of :uuid
  validates_presence_of :institution
  validates_presence_of :name
  validates_presence_of :serial_number
  validates_presence_of :device_model

  validate :unpublished_device_model_from_institution
  validate :same_institution_of_site

  before_create :set_uuid
  before_save :set_site_prefix

  delegate :current_manifest, to: :device_model

  CUSTOM_FIELD_TARGETS = ["patient.id", "sample.id", "encounter.id"]

  def self.filter_by_owner(user, check_conditions)
    if check_conditions
      joins(:institution).where(institutions: {user_id: user.id})
    else
      self
    end
  end

  def locations(opts={})
    sites.map{|l| l.location(opts)}.uniq
  end

  def filter_by_owner(user, check_conditions)
    institution.user_id == user.id ? self : nil
  end

  def self.filter_by_query(query)
    result = self
    if institution = query["institution"]
      result = result.where(institution_id: institution)
    end
    result
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

  def validate_authentication(token)
    self.secret_key_hash == MessageEncryption.hash(token)
  end

  def set_key
    set_key_for_activation_token
    self.ssh_key.try :destroy
    self.activation_token = nil
  end

  def set_key_for_activation_token
    @plain_secret_key = MessageEncryption.secure_random(9)
    self.secret_key_hash = MessageEncryption.hash(@plain_secret_key)
  end

  def set_uuid
    self.uuid = MessageEncryption.secure_random(9)
  end

  def set_site_prefix
    self.site_prefix = site.try(:prefix)
  end

  ACTIVATION_TOKEN_CHARS = ('0'..'9').to_a + ('A'..'Z').to_a

  def new_activation_token(token_value = ACTIVATION_TOKEN_CHARS.sample(16, random: Random.new).join)
    self.ssh_key.try :destroy
    self.activation_token = nil
    SshKey.regenerate_authorized_keys!
    self.activation_token = token_value
  end

  def has_pending_log_requests?
    device_commands.where(name: "send_logs").exists?
  end

  def request_client_logs
    return if has_pending_log_requests?

    device_commands.create! name: "send_logs"
  end

  def destroy_cascade!
    self.class.reflect_on_all_associations(:has_many).each { |a| self.send(a.name).destroy_all }
    self.destroy!
  end

  def activated?
    device_messages.any? || (device_model.supports_activation? && secret_key_hash && !activation_token)
  end

  def use_activation_token!(public_key)
    Device.transaction do
      self.ssh_key = SshKey.create!(public_key: public_key, device: self)
      SshKey.regenerate_authorized_keys!
    end
    self.activation_token = nil
    self.set_key_for_activation_token
    self.save!
    SyncHelpers.client_settings(uuid, plain_secret_key)
  end

  private

  def unpublished_device_model_from_institution
    if device_model && !device_model.published? && device_model.institution_id != self.institution_id
      errors.add(:device_model, "Unpublished device models can only be used to setup devices from the same institution")
    end
  end

  def same_institution_of_site
    if self.site && self.site.institution != self.institution
      errors.add(:site, "must belong to the institution of the device")
    end
  end

end
