class CleanupAssayFilesJob
  include Sidekiq::Worker

  # Delete AssayFile that don't have any AssayAttachment (parent model) associated.
  def perform
    AssayFile
      .where("created_at > ? AND assay_attachment_id IS NULL", 7.days.ago)
      .find_each(&:destroy)
  end
end
