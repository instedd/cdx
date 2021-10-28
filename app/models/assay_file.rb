class AssayFile < ActiveRecord::Base

  has_attached_file :picture, styles:  lambda { |a| a.instance.is_image? ? { :card => "130x130>" }  : {} }

  validates_attachment_size :picture, :in => 0.megabytes..10.megabytes
  do_not_validate_attachment_file_type :picture

  validates_presence_of :picture

  def is_image?
    self.picture_content_type =~ /\Aimage\/.*\Z/
  end

end