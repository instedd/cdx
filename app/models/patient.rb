class Patient < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash
  include Resource

  belongs_to :institution

  has_many :test_results, dependent: :restrict_with_error
  has_many :samples, dependent: :restrict_with_error
  has_many :encounters, dependent: :restrict_with_error

  validates_presence_of :institution

  def entity_id
    plain_sensitive_data["id"]
  end

  def has_entity_id?
    entity_id_hash.not_nil?
  end

  def self.entity_scope
    "patient"
  end

  def self.attribute_field(*args)
    args.each do |arg|
      if self.entity_fields.detect { |f| f.name == arg.to_s }.pii?
        define_method arg do
          self.plain_sensitive_data[arg.to_s]
        end

        define_method "#{arg}=" do |value|
          self.plain_sensitive_data[arg.to_s] = value
        end
      else
        define_method arg do
          self.core_fields[arg.to_s]
        end

        define_method "#{arg}=" do |value|
          self.core_fields[arg.to_s] = value
        end
      end
    end
  end

  attribute_field :name, :gender, :dob, :email, :phone

end
