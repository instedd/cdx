class AssayAttachment < ActiveRecord::Base
  belongs_to :loinc_code
  belongs_to :sample
  belongs_to :assay_file, dependent: :destroy
  accepts_nested_attributes_for :assay_file, allow_destroy: true

  validate :presence_assay_file_or_result

  def picture
    self.assay_file.picture
  end

  def presence_assay_file_or_result
    unless result.present? or assay_file.present?
      errors.add(:result, "must contain a file or a result")
    end
  end

end
