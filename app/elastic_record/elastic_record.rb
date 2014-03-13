class ElasticRecord
  class << self
    attr_accessor :index, :type, :client
  end

  attr_accessor :id, :properties, :created_at, :updated_at, :_source

  def initialize(*attributes)
    @properties = if attributes.first.is_a? Hash
      attributes.first
    else
      {}
    end
  end

  def self.for(index, type)
    record = Class.new(self)
    record.instance_eval do
      extend ActiveModel::Naming
      def name
        type.camelize
      end
    end
    record.index = index
    record.type = type
    record.client = Elasticsearch::Client.new log: false
    record
  end

  def self.where(*options)
    all.where!(*options)
  end

  def self.find(*ids)
    results = where(id: ids.flatten)
    results = results.first if results.count == 1
    results
  rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
    raise ActiveRecord::RecordNotFound.new e.message
  end

  def self.find_by_id(*ids)
    find ids
  end

  def self.all
    ElasticQuery.new(self)
  end

  def self.count
    self.all.count
  end

  def self.first
    self.all.first
  end

  def self.columns
    client.indices.refresh index: index
    begin
      result = client.indices.get_mapping(index: index, type: type)
      result[type]['properties']['properties']['properties'].keys rescue []
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      []
    end
  end

  def self.human_attribute_name(name)
    name
  end

  def persisted?
    !id.nil?
  end

  def save!
    self.class.save! self
  end

  def save
    save! rescue false
  end

  def update_attributes!(attributes)
    properties.merge! attributes
    save!
  end

  def update_attributes(attributes)
    properties.merge! attributes
    save
  end

  def self.save! object
    updated_at = Time.now
    created_at = object.created_at || updated_at
    response = client.index index: index, type: type, id: object.id, body: {properties: object.properties, created_at: created_at.utc.iso8601, updated_at: updated_at.utc.iso8601}, refresh: true
    if response["ok"]
      object.created_at = created_at
      object.updated_at = updated_at
      object.id = response["_id"]
    end
    object
  end

  def self.create(objects)
    objects = [objects] unless objects.kind_of?(Array)
    objects.map { |o| self.new(o) }.each &:save!
  end

  def destroy
    self.class.destroy self
  end

  def self.destroy object
    client.delete index: index, type: type, id: object.id, refresh: true
  end

  def as_json extras = {}
    { id: id, created_at: created_at, updated_at: updated_at }.merge(properties: properties).merge extras
  end
end
