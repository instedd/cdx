class LoincCode < ActiveRecord::Base
  belongs_to :assay_attachment, class_name: 'AssayAttachment', :foreign_key => "id"
end
