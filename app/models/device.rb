class Device < ActiveRecord::Base
  include Resource

  has_many :manifests, through: :device_model
  belongs_to :device_model
  belongs_to :institution
  has_and_belongs_to_many :laboratories
  has_many :locations, through: :laboratories
  has_many :events
  has_many :activation_tokens

  validates_presence_of :institution
  validates_presence_of :name
  validates_presence_of :device_model

  before_create :set_key, :set_uuid

  has_many :ssh_keys

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
    result = self
    if institution = query["institution"]
      result = result.where(institution_id: institution)
    end
    result
  end

  def filter_by_query(query)
    if institution = query["institution"]
      if institution_id == institution
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
    secret_key == token
  end

  def set_key
    self.secret_key = Guid.new.to_s
    self.ssh_keys.destroy_all
    self.activation_tokens.destroy_all
  end

  def set_uuid
    self.uuid = Guid.new.to_s
  end
end
