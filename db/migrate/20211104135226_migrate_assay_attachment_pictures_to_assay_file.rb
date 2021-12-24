class MigrateAssayAttachmentPicturesToAssayFile < ActiveRecord::Migration
  def up
    AssayAttachment.where.not(picture_file_size: nil ) do |assay_attachment|
      assay_file = AssayFile.new
      assay_file.picture_file_name = assay_attachment.picture_file_name
      assay_file.picture_content_type = assay_attachment.picture_content_type
      assay_file.picture_file_size = assay_attachment.picture_file_size
      assay_file.picture_updated_at = assay_attachment.picture_updated_at
      assay_file.assay_attachment = assay_attachment
      if assay_file.save!
        assay_attachment.assay_file = assay_file
        assay_attachment.save!
      end
    end

    remove_column :assay_attachments, :picture_file_name
    remove_column :assay_attachments, :picture_file_size
    remove_column :assay_attachments, :picture_updated_at
    remove_column :assay_attachments, :picture_content_type

  end

  def down
    add_column :assay_attachments, :picture_file_name, :string
    add_column :assay_attachments, :picture_content_type, :string
    add_column :assay_attachments, :picture_file_size, :integer
    add_column :assay_attachments, :picture_updated_at, :datetime

    AssayFile.where.not(assay_attachment_id: nil).each do |assay_file|
      assay_file.assay_attachment.picture_file_name = assay_file.picture_file_name
      assay_file.assay_attachment.picture_file_size = assay_file.picture_file_size
      assay_file.assay_attachment.picture_updated_at = assay_file.picture_updated_at
      assay_file.assay_attachment.picture_content_type = assay_file.picture_content_type
      assay_file.assay_attachment.save
    end

  end

end
