class QcInfo < ActiveRecord::Base
  include Entity
  include SpecimenRole
  include InactivationMethod
  include DateProduced

  has_many :samples
  has_many :assay_attachments
  has_many :notes

  has_many :assay_attachments
  accepts_nested_attributes_for :assay_attachments

  has_many :notes
  accepts_nested_attributes_for :notes

  def self.entity_scope
    "qcInfo"
  end

  attribute_field :uuid, copy: true
  attribute_field :batch_number, copy: true
  attribute_field :date_produced,
                  :lab_technician,
                  :inactivation_method,
                  :volume,
                  :isolate_name,
                  :specimen_role

  def self.find_or_duplicate_from(sample_qc)
    qc_info = QcInfo.find_by_sample_qc_id(sample_qc.id)

    unless qc_info
      qc_info = QcInfo.new({
                             sample_qc_id: sample_qc.id,
                             uuid: sample_qc.uuid,
                             batch_number: sample_qc.batch.batch_number,
                             date_produced: sample_qc.date_produced,
                             lab_technician: sample_qc.lab_technician,
                             specimen_role: sample_qc.specimen_role,
                             isolate_name: sample_qc.isolate_name,
                             inactivation_method: sample_qc.inactivation_method,
                             volume: sample_qc.volume
                           })

      duplicate_notes(qc_info, sample_qc)
      duplicate_assay_attachments(qc_info, sample_qc)
    end
    qc_info
  end

  def self.duplicate_notes(qc_info, sample)
    sample.notes.each do |note|
      new_note = note.dup
      #avoids duplicating notes for the original sample
      new_note.sample_id = nil
      new_note.save!

      qc_info.notes << new_note
    end
  end

  def self.duplicate_assay_attachments(qc_info, sample)
    sample.assay_attachments.each do |assay_attachment|
      new_assay_attachment = assay_attachment.dup
      if assay_attachment.assay_file
        new_assay_file = AssayFile.create(picture: assay_attachment.assay_file.picture)
        new_assay_attachment.assay_file = new_assay_file
      end
      #avoids duplicating assay_attachment for the original sample
      new_assay_attachment.sample = nil
      new_assay_attachment.save!

      qc_info.assay_attachments << new_assay_attachment
    end
  end

  def formatted_date_produced
    value = date_produced

    if value.is_a?(Time)
      return value.strftime(self.class.date_format[:pattern])
    end

    value
  end

end

