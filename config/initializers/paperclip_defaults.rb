Paperclip::Attachment.default_options.update({
  url: "/system/:class/:attachment/:id_partition/:style/:hash.:extension",
  hash_secret: Rails.application.secrets.secret_key_base
})

if s3_bucket = ENV['PAPERCLIP_S3_BUCKET'].presence
  paperclip_defaults = {
    storage: :s3,
    bucket: s3_bucket
  }
  paperclip_defaults[:s3_host_name] = ENV['PAPERCLIP_S3_HOST_NAME'].presence
  Rails.application.config.paperclip_defaults = paperclip_defaults
end
