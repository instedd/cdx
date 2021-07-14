class Assay < ActiveRecord::Base
  belongs_to :sample
  has_attached_file :picture, styles: { card: "130x130>" }, default_url: "card-unkown.png"

  validates_attachment_content_type :picture, content_type: /\Aimage\/.*\Z/
end
