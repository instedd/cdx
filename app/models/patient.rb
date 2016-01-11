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

  def has_entity_id?
    entity_id_hash.not_nil?
  end

  def self.entity_scope
    "patient"
  end

  # Creates accessors for Entity fields
  #
  # `attribute_field :foo, :bar` will generate r/w accessors for foo and bar fields, despite pii value
  # `attribute_field :foo, source: :foo_field_name` will use "foo_field_name" as the source.
  # `attribute_field :foo, copy: true` will ensure a copy of the value is keept in the foo attribute
  #
  def self.attribute_field(*args)
    options = args.extract_options!
    options.reverse_merge! copy: false
    do_copy = options[:copy]

    args.each do |arg|
      field_name = (options[:field] || arg).to_s
      field_source = if self.entity_fields.detect { |f| f.name == field_name }.pii?
        "plain_sensitive_data"
      else
        "core_fields"
      end

      define_method arg do
        send(field_source)[field_name]
      end

      define_method "#{arg}=" do |value|
        write_attribute(arg, value) if do_copy
        if value.blank?
          send(field_source).delete(field_name)
        else
          send(field_source)[field_name] = value
        end
      end

      if do_copy
        # copy attribute to db, in case the entity_field was changed directly
        before_validation do
          write_attribute(arg, send(arg))
        end
      end
    end
  end

  attribute_field :name, copy: true
  attribute_field :entity_id, field: :id, copy: true
  attribute_field :gender, :dob, :email, :phone

end
