class Assay < ActiveRecord::Base
  belongs_to :sample
  # has_attached_file :picture, styles: { card: "130x130>" }, default_url: "card-unkown.png"

  # https://stackoverflow.com/questions/20920212/generate-thumbnail-from-pdf-in-rails-paperclip
  has_attached_file :picture, styles:  lambda { |a| a.instance.is_image? ? { :card => "130x130>" }  : {} }

  do_not_validate_attachment_file_type :picture
  # validates_attachment :picture, :content_type => { :content_type => %w(image/jpeg image/jpg image/png application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document) }
  # validates_attachment_content_type :picture, content_type: /\Aimage\/.*\Z/

  # validates_attachment_content_type :picture,
  #   :content_type => [
  #     "video/mp4",
  #     "video/quicktime",

  #     "image/jpg",
  #     "image/jpeg",
  #     "image/png",
  #     "image/gif",

  #     "application/pdf",

  #     "audio/mpeg",
  #     "audio/x-mpeg",
  #     "audio/mp3",
  #     "audio/x-mp3",

  #     "file/txt",
  #     "text/plain",

  #     "application/doc",
  #     "application/msword",
  #     "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  #     "application/vnd.oasis.opendocument.text",

  #     "application/vnd.ms-excel",
  #     "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",

  #     "application/vnd.ms-powerpoint"
  #     ],
  #   :message => "Attached file type not valid"

  def is_image?
    # self.picture.content_type =~ %r(image)
    self.picture.content_type =~ /\Aimage\/.*\Z/
  end
end
