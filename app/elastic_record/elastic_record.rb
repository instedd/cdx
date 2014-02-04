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
    table = Class.new(self)
    table.index = index
    table.type = type
    table.client = Elasticsearch::Client.new log: false
    # table.columns.each do |column|
    #   begin
    #     table.class_eval <<-METHODS, __FILE__, __LINE__ + 1
    #       def #{column.underscore}
    #         properties["#{column}"]
    #       end

    #       def #{column.underscore}= new_value
    #         properties["#{column}"] = new_value
    #       end
    #     METHODS
    #   rescue SyntaxError => e
    #     # The column name was probably a GUID and it doesn't make sense to generate a method
    #   end
    # end
    table
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

  def self.create(properties)
    self.new(properties).save!
  end

  def destroy
    self.class.destroy self
  end

  def self.destroy object
    client.delete index: index, type: type, id: object.id, refresh: true
  end

  def as_json
    { id: id, created_at: created_at, updated_at: updated_at }.merge properties
  end
end
