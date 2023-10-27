class Batch < ApplicationRecord
  include Entity
  include AutoUUID
  include Resource
  include SpecimenRole
  include InactivationMethod
  include SiteContained
  include DateProduced

  validates_presence_of :institution

  has_many :samples, dependent: :destroy, autosave: true

  def self.entity_scope
    "batch"
  end

  attribute_field :isolate_name, copy: true
  attribute_field :batch_number, copy: true
  attribute_field :date_produced, copy: true
  attribute_field :lab_technician,
                  :specimen_role,
                  :inactivation_method,
                  :volume,
                  :virus_lineage,
                  :reference_gene,
                  :virus_shortname,
                  :target_organism_taxonomy_id,
                  :target_organism_name,
                  :pango_lineage,
                  :who_label,
                  :gisaid_id,
                  :gisaid_clade,
                  :nucleotide_db_id,
                  :virus_sample_source,
                  :virus_sample_source_url,
                  :virus_source,
                  :virus_location,
                  :virus_sample_type,
                  :virus_sample_formulation,
                  :virus_sample_concentration,
                  :virus_sample_concentration_unit,
                  :virus_sample_genome_equivalents,
                  :virus_sample_genome_equivalents_unit,
                  :virus_sample_genome_equivalents_reference_gene,
                  :virus_preinactivation_tcid50,
                  :virus_preinactivation_tcid50_unit,
                  :virus_sample_grow_cell_line

  validates_presence_of :inactivation_method
  validates_presence_of :volume
  validates_presence_of :lab_technician
  validates_numericality_of :volume, greater_than: 0, message: "value must be greater than 0"
  validates_presence_of :batch_number
  validates_presence_of :isolate_name
  validates_uniqueness_of :batch_number, scope: :isolate_name

  validates_associated :samples, message: "are invalid"

  scope :autocomplete, ->(query) {
    where("batches.batch_number LIKE ?", "%#{query}%")
  }

  def qc_sample
    self.samples.select { |sample| sample.is_quality_control? }.first
  end

  def has_qc_sample?
    self.qc_sample.present?
  end

  def qc_info
    if qc_sample = self.qc_sample
      QcInfo.find_or_duplicate_from(qc_sample)
    end
  end

  def build_sample(**attributes)
    samples.build(
      institution: institution,
      site: site,
      sample_identifiers: [SampleIdentifier.new],
      date_produced: date_produced,
      lab_technician: lab_technician,
      specimen_role: specimen_role,
      isolate_name: isolate_name,
      inactivation_method: inactivation_method,
      virus_lineage: virus_lineage,
      original_batch_id: id,
      **attributes
    )
  end
end
