Paperclip::Attachment.default_options.update({
  url: "/system/:class/:attachment/:id_partition/:style/:hash.:extension",
  hash_secret: Rails.application.secrets.secret_key_base
})

if s3_bucket = ENV['PAPERCLIP_S3_BUCKET'].presence
  Rails.application.config.paperclip_defaults = {
    storage: :s3,
    bucket: s3_bucket
  }
end
