class AssayAttachment < ActiveRecord::Base
  belongs_to :loinc_code
  belongs_to :sample
  belongs_to :assay_file, dependent: :destroy
  accepts_nested_attributes_for :assay_file, allow_destroy: true

  after_save :assign_assay_file

  validate :presence_assay_file_or_result
  validates_presence_of :loinc_code
  validates_associated :assay_file

  def assign_assay_file
    unless assay_file.nil?
      assay_file.assay_attachment = self
      assay_file.save
    end
  end

  def presence_assay_file_or_result
    unless result.present? or assay_file.present?
      errors.add(:result, "must contain a file or a result")
      errors.add(:assay_file, "must contain a file or a result")
    end
  end

end
