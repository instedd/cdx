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
    @garbage = [] # of EntityBlender
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

  def remove_blender(blender)
    to_remove = blender.self_and_children

    blender.parents.values.each do |p|
      to_remove.each { |child| p.remove_child(child) }
    end

    to_remove.each do |child|
      blenders_of(child.entity_type).delete(child)
      child.mark_for_destruction
      @garbage << child
    end

    blender.mark_for_destruction
    blender
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

  def merge_blenders(target, to_merge)
    Array.wrap(to_merge).inject(target) do |result, other|
      next result if other == result
      merge_parent(result, hierarchy.map{|t| other.parents[t]}.compact.first)
      result.merge_blender(other, force: true)
      remove_blender(other)
      result
    end
  end

  def merge_parent(child_blender, parent_blender)
    return if parent_blender.nil?
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
    ActiveRecord::Base.transaction do
      entities = @patients.map(&:save!) + @encounters.map(&:save!) + @samples.map(&:save!) + @test_results.map(&:save!)
      [blenders.values + @garbage].flatten.each &:sweep
      entities
    end
  end

  def save_and_index!
    entities = save_without_index!
    
#    binding.pry
    
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

    def inspect
      inspection = {
        "entities" => '[' + @entities.map(&:inspect).join(", ") + ']',
        "children" => '[' + @children.map(&:short_inspect).join(", ") + ']',
        "parents" =>  '[' + @parents.map{|k, v| "#{k}: #{v.short_inspect}"}.join(", ") + ']',
        "entity_id" => @entity_id
      }
      "#<#{self.class} #{inspection.to_s}>"
    end

    def short_inspect
      "#<#{self.class} entity_count: #{@entities.count}>"
    end

    def pretty_print(pp)
      pp.object_address_group(self) do
        pp.breakable
        pp.text "entity_id: #{@entity_id}"
        pp.breakable
        pp.group(1, "entities: ", "") do
          pp.breakable
          pp.seplist(@entities, proc { pp.text ', ' }) do |entity|
            pp.pp(entity)
          end
        end
        pp.breakable
        pp.group(1, "children: ", "") do
          pp.breakable
          pp.seplist(@children, proc { pp.text ', ' }) do |entity|
            pp.text(entity.short_inspect)
          end
        end
        pp.breakable
        pp.group(1, "parents: ", "") do
          pp.breakable
          pp.seplist(@parents.to_a, proc { pp.text ', ' }) do |key, entity|
            pp.text "#{key}: "
            pp.text(entity.short_inspect)
          end
        end
      end
    end

    def find_entity(entity)
      @entities.find { |existing| existing == entity || (existing.uuids & entity.uuids).any? }
    end

    def include_entity?(entity)
      !!find_entity(entity)
    end

    def add_entity(entity, opts={})
      return self if entity.nil? || contains?(entity)
      raise InstitutionMismatchError, "Cannot set #{self.class.entity_type.entity_scope} from a different institution" if entity.institution && entity.institution != @institution

      # Do not support merging two non-phantom entities by default
      if (entity.not_phantom? || opts[:entity_id]) && (not_phantom = @entities.select(&:not_phantom?).any?) && !opts[:force]
        raise MergeNonPhantomError.new("Cannot merge two identified #{self.class.entity_type.entity_scope}s", self.class.entity_type)
      end

      # Add entity to collection and merge its attributes and id
      @entities << entity
      merge_attributes(entity)
      merge_entity_id(opts[:entity_id]) if opts[:entity_id]

      self
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

    def merge_blender(blender, opts={})
      raise InstitutionMismatchError, "Cannot merge entity blender from a different institution" if blender.institution && self.institution && blender.institution != self.institution
      raise EntityTypeMismatchError, "Cannot merge entity blender from a different type" if blender.entity_type != self.entity_type
      return self if blender == self
      blender.entities.each { |entity| self.add_entity(entity, opts) }
      blender.children.clone.each { |child| child.set_parent(self) }

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
      @garbage.compact.uniq.each do |e|
        begin
          # We need to reload the entity as some of its dependencies might have been removed
          e.reload.destroy if e.phantom? || @marked_for_destruction
        rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordNotFound => ex
          # This entity still had associated children, move on to the next one
        end
      end
    end

    def mark_for_destruction
      @garbage += @entities
      @marked_for_destruction = true
      self
    end

    def target
      @target
    end

    def self_and_parents
      [self] + @parents.values
    end

    def self_and_children
      [self] + @children
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

    def preview
      target = @entities.find(&:not_phantom?) || @entities.first
      target = Patient.find(target.id) if target # grab a new patient in order to avoid dirty state
      target = self.class.entity_type.new(institution: institution) unless target

      target.plain_sensitive_data = plain_sensitive_data
      target.custom_fields = custom_fields
      target.core_fields = core_fields

      target
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

    attr_accessor :site

    protected

    def before_save(entity)
      created_at = entity.created_at
      test_results = @children.select { |child| child.is_a?(TestResultBlender) }

      start_times = fetch_times(test_results, "start_time")
      end_times = fetch_times(test_results, "end_time")

      if created_at
        start_times << created_at
        end_times << created_at
      end

      now = Time.now
      min_start_time = start_times.min || now
      max_end_time = end_times.max || min_start_time

      entity.core_fields["start_time"] = min_start_time.iso8601
      entity.core_fields["end_time"] = max_end_time.iso8601

      entity.site ||= self.site
    end

    def fetch_times(test_results, field)
      test_results.map { |test| test.core_fields[field] }.compact.map { |time| time.is_a?(Time) ? time : Time.parse(time) }
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

    def merge_entity_id(entity_id)
      true
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
      @sample_id = (entity_or_attributes.kind_of?(Hash) \
        ? entity_or_attributes[:sample_id].try(:to_s) \
        : entity_or_attributes.sample_identifier.try(:entity_id)) || @sample_id
    end

    protected

    def before_save(entity)
      sample = @parents[Sample].try(:target)
      sample_id = @sample_id
      site_id = entity.site_id

      existing_identifier = entity.sample_identifier

      if sample.nil?
        entity.sample_identifier = nil
        @garbage << existing_identifier
      elsif existing_identifier.nil? || existing_identifier.entity_id != sample_id || existing_identifier.site_id != site_id
        matching_sample_identifier = sample.sample_identifiers.all.find { |si| si.entity_id == sample_id && si.site_id == site_id }
        entity.sample_identifier = matching_sample_identifier || sample.sample_identifiers.build(entity_id: sample_id, site_id: site_id)
        @garbage << existing_identifier
      elsif existing_identifier.sample != sample
        existing_identifier.sample = sample
        existing_identifier.site_id = site_id
        existing_identifier.save!
      else
        entity.sample_identifier.try :reload
      end
    end

  end

end
