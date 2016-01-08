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
    options = args.extract_options!
    options.reverse_merge! copy: false
    db_attribute = options[:copy]

    args.each do |arg|
      field_source = if self.entity_fields.detect { |f| f.name == arg.to_s }.pii?
        "plain_sensitive_data"
      else
        "core_fields"
      end

      define_method arg do
        send(field_source)[arg.to_s]
      end

      define_method "#{arg}=" do |value|
        write_attribute(arg, value) if db_attribute
        if value.blank?
          send(field_source).delete(arg.to_s)
        else
          send(field_source)[arg.to_s] = value
        end
      end

      if db_attribute
        # copy attribute to db, in case the entity_field was changed directly
        before_validation do
          write_attribute(arg, send(arg))
        end
      end
    end
  end

  attribute_field :name, copy: true
  attribute_field :gender, :dob, :email, :phone

end
