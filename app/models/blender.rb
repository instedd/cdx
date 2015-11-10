class Blender

  attr_accessor :patients, :encounters, :samples, :test_results, :institution

  class InstitutionMismatchError < StandardError; end
  class UnknownEntityError < StandardError; end
  class EntityTypeMismatchError < StandardError; end

  class MergeNonPhantomError < StandardError
    attr_reader :entity_type
    def initialize(msg=nil, entity_type=nil)
      @message = msg
      @entity_type = entity_type
    end
  end

  def initialize(institution)
    @institution = institution
    @patients = [] # of PatientBlender
    @encounters = [] # of EncounterBlender
    @samples = [] # of SampleBlender
    @test_results = [] # of TestResult
  end

  def hierarchy
    @@hierarchy ||= [TestResult, Sample, Encounter, Patient].freeze
  end

  def load(entity)
    raise "Entity cannot be null" if entity.nil?
    raise InstitutionMismatchError, "Entity institution does not match" if entity.institution != @institution
    blender_type = blender_type_for(entity)
    target = blenders_of(entity.class)

    if (blender = target.find{|existing_blender| existing_blender.include_entity?(entity)}).nil?
      blender = blender_type.new(self, entity)
      target << blender
      add_children(entity, blender)
      add_parents(entity, blender)
    end

    blender
  end

  def remove(entity)
    target = blenders_of(entity.class)
    if (blender = target.find{|existing_blender| existing_blender.include_entity?(entity)})
      target.remove(blender)
      blender.parent.remove_child(blender)
      blender.children.each{ |c| remove(c) }
    end
  end

  def blender_type_for(entity)
    [TestResultBlender, SampleBlender, EncounterBlender, PatientBlender].find do |blender|
      blender.entity_type === entity
    end
  end

  def blenders
    {Patient => @patients, Encounter => @encounters, Sample => @samples, TestResult => @test_results}
  end

  def blenders_of(klazz)
    blenders[klazz] or raise UnknownEntityError, "Unknown entity type #{klazz.name}"
  end

  def add_children(entity, blender)
    hierarchy.each do |h|
      if entity.respond_to?(h.model_name.plural)
        entity.send(h.model_name.plural).each do |child|
          child_blender = load(child)
          child_blender.set_parent(blender)
        end
      end
    end
  end

  def add_parents(entity, blender)
    hierarchy.each do |h|
      if entity.respond_to?(h.model_name.singular) && (parent = entity.send(h.model_name.singular))
        parent_blender = load(parent)
        blender.set_parent(parent_blender)
      end
    end
  end

  def set_parent(child_blender, parent_blender)
    types_to_change = hierarchy.drop_while{|type| type != child_blender.class.entity_type}.take_while {|type| type != parent_blender.class.entity_type}
    parents_to_change = child_blender.parents.select {|klazz, entity| types_to_change.include?(klazz)}.values
    children_to_set = (child_blender.children + [child_blender] + parents_to_change + parents_to_change.map(&:children).flatten).uniq

    children_to_set.each do |blender|
      parent_blender.self_and_parents.each do |parent|
        blender.set_parent(parent)
      end
    end
  end

  def merge_parent(child_blender, parent_blender)
    merged_parents = []

    types_to_merge = hierarchy.drop_while{|type| type != parent_blender.entity_type}.reverse
    types_to_merge.each do |type|
      current_parent = child_blender.parents[type]
      other_parent   = parent_blender.self_and_parents.find{ |p| p.entity_type == type }

      merged_parent = if current_parent && other_parent
        other_parent.merge_blender(current_parent)
      else
        current_parent || other_parent
      end

      if merged_parent
        merged_parents.each do |ancestor|
          set_parent(merged_parent, ancestor)
        end
        merged_parents << merged_parent
      end
    end

    set_parent(child_blender, merged_parents.last)
  end

  def save_without_index!
    entities = @patients.map(&:save!) + @encounters.map(&:save!) + @samples.map(&:save!) + @test_results.map(&:save!)
    blenders.values.flatten.each &:sweep
    entities
  end

  def save_and_index!
    entities = save_without_index!
    entities.each do |entity|
      case entity
      when TestResult then TestResultIndexer.new(entity).index
      when Encounter then EncounterIndexer.new(entity).index
      when Entity then EntityIndexUpdater.new(entity).update
      when nil then next
      else raise UnknownEntityError, "Unknown entity type #{entity.class.name}"
      end
    end
  end


  class EntityBlender

    attr_reader :institution, :children, :entities, :entity_id, :parents, :garbage,\
      :plain_sensitive_data, :custom_fields, :core_fields

    def initialize(blender, entities=nil)
      @container = blender

      @entities = []
      @children = []
      @parents =  {}

      @garbage =  []

      @plain_sensitive_data = {}
      @custom_fields = {}
      @core_fields = {}

      @entity_id = nil
      @institution = blender.institution

      Array.wrap(entities).each { |p| add_entity(p) }
    end

    def find_entity(entity)
      @entities.find { |existing| existing == entity || (existing.uuids & entity.uuids).any? }
    end

    def include_entity?(entity)
      !!find_entity(entity)
    end

    def add_entity(entity, opts={})
      add_or_set_entity(entity, true, opts)
    end

    def set_entity(entity, opts={})
      add_or_set_entity(entity, false, opts)
    end

    def add_child(child)
      return self if child.nil?
      raise InstitutionMismatchError, "Cannot add child from a different institution" if child.institution && child.institution != @institution
      raise EntityTypeMismatchError, "Entity blender add child must receive an entity blender" unless child.kind_of?(EntityBlender)
      @children << child unless @children.any?{|child_blender| child_blender == child}
    end

    def remove_child(child)
      @children.delete(child)
    end

    def set_parent(parent)
      previous_parent = @parents[parent.class.entity_type]
      previous_parent.remove_child(self) if previous_parent
      @parents[parent.class.entity_type] = parent
      parent.add_child(self)
      parent
    end

    def merge_blender(blender)
      raise InstitutionMismatchError, "Cannot merge entity blender from a different institution" if blender.institution && self.institution && blender.institution != self.institution
      raise EntityTypeMismatchError, "Cannot merge entity blender from a different type" if blender.entity_type != self.entity_type
      return self if blender == self
      blender.entities.each { |entity| self.add_entity(entity) }
      blender.children.each { |child| @container.set_parent(child, self) }

      @garbage += blender.garbage
      merge_attributes(blender)
      self
    end

    def merge_attributes(entity_or_attributes)
      plain_sensitive_data, custom_fields, core_fields = attributes = attributes_from(entity_or_attributes)

      @plain_sensitive_data.deep_merge_not_nil!(plain_sensitive_data)
      @custom_fields.deep_merge_not_nil!(custom_fields)
      @core_fields.deep_merge_not_nil!(core_fields)

      new_id = get_entity_id(*attributes)
      merge_entity_id(new_id)

      self
    end

    def rebuild_attributes
      [@plain_sensitive_data, @custom_fields, @core_fields].each(&:clear)
      @entity_id = nil
      @entities.each { |entity| merge_attributes(entity) }
    end

    def attributes
      {
        plain_sensitive_data: @plain_sensitive_data,
        custom_fields: @custom_fields,
        core_fields: @core_fields
      }
    end

    def uuids
      @entities.map(&:uuid)
    end

    def single_entity
      raise "Multiple entities found on call to single entity" if @entities.size > 1
      @entities.first
    end

    def empty?
      self.plain_sensitive_data.blank? &&
        self.core_fields.blank? &&
        self.custom_fields.except('custom').blank? &&
        self.custom_fields.try(:[], 'custom').blank?
    end

    def save!
      target = @entities.find(&:not_phantom?) || @entities.first || self.class.entity_type.new(institution: institution)

      target.plain_sensitive_data = @plain_sensitive_data
      target.custom_fields = @custom_fields
      target.core_fields = @core_fields

      @parents.each do |klazz, parent|
        target.send("#{klazz.model_name.singular}=", parent.target) if target.respond_to?("#{klazz.model_name.singular}=")
      end

      before_save(target)

      if target.empty_entity? && target.phantom? && !target.kind_of?(TestResult)
        @garbage += @entities
        @target = nil
      else
        @garbage += (@entities - [target])
        target.save!
        @target = target
      end

      @target
    end

    def sweep
      @garbage.compact.each do |e|
        begin
          e.destroy if e.phantom?
        rescue ActiveRecord::RecordNotDestroyed
          # This entity still had associated children, move on to the next one
        end
      end
    end

    def target
      @target
    end

    def self_and_parents
      [self] + @parents.values
    end

    def patient
      @parents[Patient]
    end

    def encounter
      @parents[Encounter]
    end

    def sample
      @parents[Sample]
    end

    def test_results
      @children.select{|c| c.kind_of?(TestResultBlender)}
    end

    def samples
      @children.select{|c| c.kind_of?(SampleBlender)}
    end

    def encounters
      @children.select{|c| c.kind_of?(EncounterBlender)}
    end

    def entity_type
      self.class.entity_type
    end

    protected

    def before_save(entity)
    end

    def get_entity_id(plain_sensitive_data, custom_fields, core_fields)
      core_fields['id'].try(:to_s)
    end

    def merge_entity_id(new_id)
      if @entity_id.nil?
        @entity_id = new_id
      elsif @entity_id != new_id && !new_id.nil?
        raise "Cannot change entity id of #{self.class.entity_type.entity_scope} from #{@entity_id} to #{new_id}"
      end
    end

    def contains?(entity)
      self.uuids.include?(entity.uuid)
    end

    def add_or_set_entity(entity, is_add, opts={})
      return self if entity.nil? || contains?(entity)
      raise InstitutionMismatchError, "Cannot set #{self.class.entity_type.entity_scope} from a different institution" if entity.institution && entity.institution != @institution

      # If there is already a non phantom entity, we either replace it (on set) or raise (on merge)
      if (entity.not_phantom? || opts[:entity_id]) && (not_phantom = @entities.select(&:not_phantom?).any?)
        if is_add
          raise MergeNonPhantomError.new("Cannot merge two identified #{self.class.entity_type.entity_scope}s", self.class.entity_type)
        else
          @entities, rejected = @entities.partition(&:phantom?)
          @garbage += rejected
          rebuild_attributes
        end
      end

      # Add entity to collection and merge its attributes and id
      @entities << entity
      merge_attributes(entity)
      merge_entity_id(opts[:entity_id]) if opts[:entity_id]

      self
    end

    private

    def attributes_from(entity_or_attributes)
      keys = %W(plain_sensitive_data custom_fields core_fields)
      if entity_or_attributes.kind_of?(Entity) || entity_or_attributes.kind_of?(EntityBlender)
        keys.map{ |key| entity_or_attributes.send(key) }
      else
        hash = entity_or_attributes.with_indifferent_access
        keys.map{ |key| hash[key] || Hash.new }
      end
    end

  end


  class PatientBlender < EntityBlender

    def self.entity_type
      Patient
    end

    def self.child_type
      EncounterBlender
    end

    def self.parent_type
      nil
    end

    protected

    def get_entity_id(plain_sensitive_data, custom_fields, core_fields)
      plain_sensitive_data['id'].try(:to_s)
    end

  end


  class EncounterBlender < EntityBlender

    def self.entity_type
      Encounter
    end

    def self.child_type
      Sample
    end

    def self.parent_type
      Patient
    end

  end


  class SampleBlender < EntityBlender

    def load_entities(uuids, auth)
      self.class.entity_type.joins(:sample_identifiers).where("sample_identifiers.uuid" => uuids)
    end

    def uuids
      @entities.map(&:uuids).flatten
    end

    def entity_ids
      @entities.map(&:entity_ids).flatten
    end

    def self.entity_type
      Sample
    end

    def self.child_type
      TestResult
    end

    def self.parent_type
      Encounter
    end

  end


  class TestResultBlender < EntityBlender

    attr_accessor :sample_id

    def self.entity_type
      TestResult
    end

    def self.child_type
      nil
    end

    def self.parent_type
      Sample
    end

    def add_child(child)
      raise "Test result has no children entities"
    end

    def merge_attributes(entity_or_attributes)
      super
      @sample_id ||= entity_or_attributes.kind_of?(Hash) \
        ? entity_or_attributes[:sample_id].try(:to_s) \
        : entity_or_attributes.sample_identifier.try(:entity_id)
    end

    protected

    def before_save(entity)
      sample = @parents[Sample].try(:target)
      sample_id = @sample_id

      existing_identifier = entity.sample_identifier
      existing_identifier_does_not_match =  existing_identifier && (existing_identifier.sample != sample || existing_identifier.sample_id != sample_id)

      if sample.nil?
        entity.sample_identifier = nil
        @garbage << existing_identifier
      elsif existing_identifier.nil? || existing_identifier_does_not_match
        entity.sample_identifier = sample.sample_identifiers.where(entity_id: sample_id).first || SampleIdentifier.new(entity_id: sample_id, sample: sample)
        @garbage << existing_identifier
      end
    end

  end

end
