namespace :assay_files do
  desc "delete AssayFiles that don't have any AssayAttachment (parent model) associated"
  task garbage_collector: :environment do
    assay_files = AssayFile.where("created_at > ? AND assay_attachment_id IS NULL", 7.days.ago)
    AssayFile.destroy(assay_files.map(&:id))
  end
end
