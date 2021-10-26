class AssayAttachment < ActiveRecord::Base
  belongs_to :loinc_code, :dependent => :destroy
  belongs_to :sample
  has_many :assay_files, dependent: :destroy
  accepts_nested_attributes_for :assay_files, allow_destroy: true

  has_attached_file :picture, styles:  lambda { |a| a.instance.is_image? ? { :card => "130x130>" }  : {} }

  def is_image?
    self.picture.content_type =~ /\Aimage\/.*\Z/
  end
end
