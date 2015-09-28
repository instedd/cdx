class Device < ActiveRecord::Base
  include Resource

  has_one :manifest, through: :device_model
  belongs_to :device_model
  belongs_to :institution
  belongs_to :laboratory
  has_many :test_results
  has_many :device_messages
  has_one :activation_token, dependent: :destroy
  has_one :ssh_key, dependent: :destroy
  has_many :device_logs

  serialize :custom_mappings, JSON

  attr_reader :plain_secret_key

  validates_uniqueness_of :uuid
  validates_presence_of :institution
  validates_presence_of :name
  validates_presence_of :serial_number
  validates_presence_of :device_model

  before_create :set_key, :set_uuid

  delegate :current_manifest, to: :device_model

  CUSTOM_FIELD_TARGETS = ["patient.id", "sample.id"]

  def self.filter_by_owner(user, check_conditions)
    if check_conditions
      joins(:institution).where(institutions: {user_id: user.id})
    else
      self
    end
  end

  def locations(opts={})
    laboratories.map{|l| l.location(opts)}.uniq
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
    self.activation_token.try :destroy
  end

  def set_key_for_activation_token
    @plain_secret_key = MessageEncryption.secure_random(9)
    self.secret_key_hash = MessageEncryption.hash(@plain_secret_key)
  end

  def set_uuid
    self.uuid = MessageEncryption.secure_random(9)
  end

  def new_activation_token
    self.ssh_key.try :destroy
    self.activation_token.try :destroy
    SshKey.regenerate_authorized_keys!
    self.activation_token = ActivationToken.new(device: self)
  end
end
